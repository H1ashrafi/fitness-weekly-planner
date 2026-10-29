"""Builds assets/models/anatomy.glb from real BodyParts3D muscle meshes.

Source: BodyParts3D, (c) The Database Center for Life Science,
licensed under CC Attribution-ShareAlike 2.1 Japan, via the GitHub mirror
github.com/Kevin-Mattheus-Moerman/BodyParts3D (binary STL per FMA id).

Sub-muscles are merged into the app's 18 AnatomyRegion groups so that tapping
any head of e.g. the quadriceps reports "quadriceps". Meshes are decimated by
vertex clustering to stay mobile-friendly, and simple directional shading is
baked into COLOR_0 so the model renders correctly with unlit materials (no IBL
or skybox asset needed).
"""

import concurrent.futures
import json
import os
import struct
import sys
import urllib.request

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
CACHE = os.path.join(HERE, ".bp3d_cache")
OUT = os.path.join(ROOT, "assets", "models", "anatomy.glb")

BASE = "https://raw.githubusercontent.com/Kevin-Mattheus-Moerman/BodyParts3D/main/assets/BodyParts3D_data/"
STL = BASE + "stl/"
PARTS = BASE + "parts_list_e.txt"

TARGET_HEIGHT = 1.75
GRID_DIVISIONS = 260          # body-height / this = clustering cell size
MUSCLE = (0.72, 0.20, 0.22)   # deep anatomical red
LIGHT = np.array([0.35, 0.72, 0.60])
LIGHT /= np.linalg.norm(LIGHT)
AMBIENT, DIFFUSE = 0.45, 0.55

REGIONS = {
    "trapezius": ["descending part of {s} trapezius", "transverse part of {s} trapezius", "ascending part of {s} trapezius"],
    "anteriorDeltoid": ["clavicular part of {s} deltoid"],
    "lateralDeltoid": ["acromial part of {s} deltoid"],
    "posteriorDeltoid": ["spinal part of {s} deltoid"],
    "pectoralis": ["clavicular part of {s} pectoralis major", "sternocostal part of {s} pectoralis major", "abdominal part of {s} pectoralis major"],
    "biceps": ["long head of {s} biceps brachii", "short head of {s} biceps brachii"],
    "triceps": ["long head of {s} triceps brachii", "lateral head of {s} triceps brachii", "medial head of {s} triceps brachii"],
    "forearm": ["{s} brachioradialis", "{s} extensor digitorum", "{s} flexor carpi radialis"],
    "abdominals": ["{s} rectus abdominis"],
    "obliques": ["{s} external oblique"],
    "latissimusDorsi": ["{s} latissimus dorsi"],
    "rhomboids": ["{s} rhomboid major", "{s} rhomboid minor"],
    "lowerBack": ["{s} iliocostalis lumborum", "{s} longissimus thoracis", "{s} quadratus lumborum"],
    "glutes": ["{s} gluteus maximus", "{s} gluteus medius"],
    "quadriceps": ["{s} rectus femoris", "{s} vastus lateralis", "{s} vastus medialis"],
    "hamstrings": ["long head of {s} biceps femoris", "short head of {s} biceps femoris", "{s} semitendinosus", "{s} semimembranosus"],
    "adductors": ["{s} adductor longus", "{s} adductor magnus", "{s} adductor brevis", "{s} gracilis"],
    "calves": ["medial head of {s} gastrocnemius", "lateral head of {s} gastrocnemius", "{s} soleus"],
}


def fetch(url, path):
    if os.path.exists(path) and os.path.getsize(path) > 0:
        return path
    tmp = path + ".part"
    with urllib.request.urlopen(url, timeout=180) as r, open(tmp, "wb") as f:
        while True:
            chunk = r.read(1 << 20)
            if not chunk:
                break
            f.write(chunk)
    os.replace(tmp, path)
    return path


def load_names():
    os.makedirs(CACHE, exist_ok=True)
    p = fetch(PARTS, os.path.join(CACHE, "parts_list_e.txt"))
    names = {}
    with open(p, encoding="utf-8", errors="replace") as f:
        next(f)
        for line in f:
            row = line.rstrip("\n").split("\t")
            if len(row) >= 2:
                names[row[1].strip().lower()] = row[0].strip()
    return names


def read_stl(path):
    """Binary STL -> (T,3,3) float32 triangle array."""
    with open(path, "rb") as f:
        head = f.read(84)
        if len(head) < 84:
            return np.zeros((0, 3, 3), np.float32)
        count = struct.unpack("<I", head[80:84])[0]
        raw = np.frombuffer(f.read(count * 50), dtype=np.uint8)
    if raw.size < count * 50:
        count = raw.size // 50
        raw = raw[: count * 50]
    rec = raw.reshape(count, 50)
    verts = rec[:, 12:48].copy().view(np.float32).reshape(count, 3, 3)
    return verts


def cluster_decimate(tris, cell):
    """Vertex-clustering decimation. Returns (verts, normals, faces)."""
    if tris.shape[0] == 0:
        return None
    flat = tris.reshape(-1, 3)
    keys = np.floor(flat / cell).astype(np.int64)
    _, inverse, counts = np.unique(keys, axis=0, return_inverse=True, return_counts=True)
    n = counts.shape[0]

    acc = np.zeros((n, 3), np.float64)
    np.add.at(acc, inverse, flat)
    verts = (acc / counts[:, None]).astype(np.float32)

    faces = inverse.reshape(-1, 3)
    ok = (faces[:, 0] != faces[:, 1]) & (faces[:, 1] != faces[:, 2]) & (faces[:, 0] != faces[:, 2])
    faces = faces[ok]
    if faces.shape[0] == 0:
        return None

    used, faces = np.unique(faces, return_inverse=True)
    faces = faces.reshape(-1, 3)
    verts = verts[used]

    a, b, c = verts[faces[:, 0]], verts[faces[:, 1]], verts[faces[:, 2]]
    fn = np.cross(b - a, c - a)
    norms = np.zeros_like(verts, dtype=np.float64)
    for i in range(3):
        np.add.at(norms, faces[:, i], fn)
    ln = np.linalg.norm(norms, axis=1, keepdims=True)
    ln[ln == 0] = 1.0
    return verts, (norms / ln).astype(np.float32), faces.astype(np.uint32)


class Glb:
    def __init__(self):
        self.bin = bytearray()
        self.views, self.accessors, self.meshes, self.nodes, self.materials = [], [], [], [], []

    def _view(self, data, target):
        while len(self.bin) % 4:
            self.bin.append(0)
        off = len(self.bin)
        self.bin += data
        self.views.append({"buffer": 0, "byteOffset": off, "byteLength": len(data), "target": target})
        return len(self.views) - 1

    def add(self, name, verts, normals, colors, faces, color):
        big = verts.shape[0] > 65535
        idx = faces.astype(np.uint32 if big else np.uint16)

        pv = self._view(verts.astype("<f4").tobytes(), 34962)
        nv = self._view(normals.astype("<f4").tobytes(), 34962)
        cv = self._view(colors.astype(np.uint8).tobytes(), 34962)
        iv = self._view(idx.tobytes(), 34963)

        base = len(self.accessors)
        self.accessors.append({"bufferView": pv, "componentType": 5126, "count": int(verts.shape[0]), "type": "VEC3",
                               "min": verts.min(axis=0).tolist(), "max": verts.max(axis=0).tolist()})
        self.accessors.append({"bufferView": nv, "componentType": 5126, "count": int(normals.shape[0]), "type": "VEC3"})
        self.accessors.append({"bufferView": cv, "componentType": 5121, "normalized": True,
                               "count": int(colors.shape[0]), "type": "VEC4"})
        self.accessors.append({"bufferView": iv, "componentType": 5125 if big else 5123,
                               "count": int(idx.size), "type": "SCALAR"})

        self.materials.append({
            "pbrMetallicRoughness": {"baseColorFactor": [color[0], color[1], color[2], 1.0],
                                     "metallicFactor": 0.0, "roughnessFactor": 1.0},
            "extensions": {"KHR_materials_unlit": {}},
        })
        self.meshes.append({"name": name, "primitives": [{
            "attributes": {"POSITION": base, "NORMAL": base + 1, "COLOR_0": base + 2},
            "indices": base + 3, "material": len(self.materials) - 1, "mode": 4}]})
        self.nodes.append({"name": name, "mesh": len(self.meshes) - 1})

    def write(self, path):
        gltf = {"asset": {"version": "2.0", "generator": "hani-anatomy/bodyparts3d",
                          "copyright": "BodyParts3D (c) The Database Center for Life Science, CC BY-SA 2.1 JP"},
                "scene": 0, "scenes": [{"nodes": list(range(len(self.nodes)))}],
                "nodes": self.nodes, "meshes": self.meshes, "materials": self.materials,
                "accessors": self.accessors, "bufferViews": self.views,
                "buffers": [{"byteLength": len(self.bin)}],
                "extensionsUsed": ["KHR_materials_unlit"]}
        js = json.dumps(gltf, separators=(",", ":")).encode()
        while len(js) % 4:
            js += b" "
        bb = bytes(self.bin)
        while len(bb) % 4:
            bb += b"\x00"
        with open(path, "wb") as f:
            f.write(struct.pack("<III", 0x46546C67, 2, 12 + 8 + len(js) + 8 + len(bb)))
            f.write(struct.pack("<II", len(js), 0x4E4F534A)); f.write(js)
            f.write(struct.pack("<II", len(bb), 0x004E4942)); f.write(bb)


def main():
    os.makedirs(CACHE, exist_ok=True)
    names = load_names()

    wanted, missing = [], []
    for region, pats in REGIONS.items():
        for side in ("right", "left"):
            for pat in pats:
                nm = pat.format(s=side)
                fid = names.get(nm)
                (wanted if fid else missing).append((region, side, nm, fid))
    if missing:
        print(f"skipping {len(missing)} unmatched parts: {[m[2] for m in missing][:6]}")

    print(f"downloading {len(wanted)} meshes (cached in {CACHE}) ...")

    def grab(item):
        _, _, _, fid = item
        return fetch(f"{STL}{fid}.stl", os.path.join(CACHE, f"{fid}.stl"))

    with concurrent.futures.ThreadPoolExecutor(max_workers=8) as ex:
        for i, _ in enumerate(ex.map(grab, wanted), 1):
            if i % 10 == 0 or i == len(wanted):
                print(f"  {i}/{len(wanted)}", flush=True)

    groups = {}
    for region, side, nm, fid in wanted:
        tris = read_stl(os.path.join(CACHE, f"{fid}.stl"))
        if tris.shape[0]:
            groups.setdefault((region, side), []).append(tris)
    groups = {k: np.concatenate(v) for k, v in groups.items()}
    print(f"loaded {len(groups)} region/side groups, "
          f"{sum(t.shape[0] for t in groups.values())/1e6:.2f}M source triangles")

    # ---- orient from anatomical landmarks ----
    every = np.concatenate(list(groups.values())).reshape(-1, 3)
    lo, hi = every.min(axis=0), every.max(axis=0)
    extent = hi - lo
    up = int(np.argmax(extent))

    def centroid(key):
        return groups[key].reshape(-1, 3).mean(axis=0) if key in groups else None

    r_pec, l_pec = centroid(("pectoralis", "right")), centroid(("pectoralis", "left"))
    lateral = int(np.argmax(np.abs(r_pec - l_pec)))
    front_axis = ({0, 1, 2} - {up, lateral}).pop()

    abs_c = centroid(("abdominals", "right"))
    trap_c = centroid(("trapezius", "right"))
    front_sign = 1.0 if abs_c[front_axis] > trap_c[front_axis] else -1.0
    up_sign = 1.0 if trap_c[up] > centroid(("calves", "right"))[up] else -1.0
    # subject's left should sit on +X so the model reads correctly facing us
    lat_sign = 1.0 if l_pec[lateral] > r_pec[lateral] else -1.0

    scale = TARGET_HEIGHT / extent[up]
    centre = (lo + hi) / 2.0

    def transform(t):
        p = t.reshape(-1, 3) - centre
        out = np.empty_like(p)
        out[:, 0] = p[:, lateral] * lat_sign
        out[:, 1] = p[:, up] * up_sign
        out[:, 2] = p[:, front_axis] * front_sign
        return (out * scale).reshape(t.shape)

    groups = {k: transform(v) for k, v in groups.items()}
    print(f"oriented: up=axis{up} lateral=axis{lateral} front=axis{front_axis} scale={scale:.5f}")

    cell = TARGET_HEIGHT / GRID_DIVISIONS
    glb = Glb()
    total_tris = 0
    for (region, side), tris in sorted(groups.items()):
        res = cluster_decimate(tris, cell)
        if res is None:
            print(f"  ! {region}.{side} collapsed, skipped")
            continue
        verts, normals, faces = res
        shade = AMBIENT + DIFFUSE * np.clip(normals @ LIGHT, 0, None)
        cols = np.empty((verts.shape[0], 4), np.uint8)
        cols[:, :3] = np.clip(shade[:, None] * 255.0, 0, 255).astype(np.uint8)
        cols[:, 3] = 255
        tag = "R" if side == "right" else "L"
        glb.add(f"{region}.{tag}", verts, normals, cols, faces, MUSCLE)
        total_tris += faces.shape[0]

    glb.write(OUT)
    size = os.path.getsize(OUT)
    print(f"\nwrote {OUT}")
    print(f"  {len(glb.nodes)} nodes, {total_tris/1000:.0f}k triangles, {size/1e6:.1f} MB")


if __name__ == "__main__":
    sys.exit(main())
