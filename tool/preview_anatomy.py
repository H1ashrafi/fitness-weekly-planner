"""Validates assets/models/anatomy.glb and renders preview PNGs.

Uses z-buffered vertex splatting (no 3D engine needed) so the generated model
can be eyeballed for shape and orientation before it ships in the APK.
"""

import json
import os
import struct
import zlib

import numpy as np

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GLB = os.path.join(ROOT, "assets", "models", "anatomy.glb")
OUTDIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "preview")

COMP = {5120: "i1", 5121: "u1", 5122: "i2", 5123: "u2", 5125: "u4", 5126: "f4"}
NCOMP = {"SCALAR": 1, "VEC2": 2, "VEC3": 3, "VEC4": 4}


def load(path):
    data = open(path, "rb").read()
    magic, ver, total = struct.unpack("<III", data[:12])
    assert magic == 0x46546C67 and ver == 2, "not a glb"
    assert total == len(data), f"length mismatch {total} vs {len(data)}"
    jlen, jtype = struct.unpack("<II", data[12:20])
    assert jtype == 0x4E4F534A
    gltf = json.loads(data[20:20 + jlen])
    off = 20 + jlen
    blen, btype = struct.unpack("<II", data[off:off + 8])
    assert btype == 0x004E4942
    return gltf, data[off + 8:off + 8 + blen]


def accessor(gltf, buf, i):
    acc = gltf["accessors"][i]
    bv = gltf["bufferViews"][acc["bufferView"]]
    dt = np.dtype("<" + COMP[acc["componentType"]])
    n = NCOMP[acc["type"]]
    start = bv.get("byteOffset", 0) + acc.get("byteOffset", 0)
    arr = np.frombuffer(buf, dtype=dt, count=acc["count"] * n, offset=start)
    return arr.reshape(acc["count"], n) if n > 1 else arr


def png(path, img):
    h, w, _ = img.shape
    raw = b"".join(b"\x00" + img[y].tobytes() for y in range(h))

    def chunk(tag, payload):
        c = struct.pack(">I", len(payload)) + tag + payload
        return c + struct.pack(">I", zlib.crc32(tag + payload) & 0xFFFFFFFF)

    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 2, 0, 0, 0)))
        f.write(chunk(b"IDAT", zlib.compress(raw, 6)))
        f.write(chunk(b"IEND", b""))


def main():
    gltf, buf = load(GLB)
    os.makedirs(OUTDIR, exist_ok=True)

    problems = 0
    parts = []
    for mesh in gltf["meshes"]:
        prim = mesh["primitives"][0]
        pos = accessor(gltf, buf, prim["attributes"]["POSITION"]).astype(np.float32)
        col = accessor(gltf, buf, prim["attributes"]["COLOR_0"])
        idx = accessor(gltf, buf, prim["indices"])
        if idx.max() >= pos.shape[0]:
            print(f"BAD indices in {mesh['name']}")
            problems += 1
        base = gltf["materials"][prim["material"]]["pbrMetallicRoughness"]["baseColorFactor"]
        parts.append((mesh["name"], pos, col, np.array(base[:3])))

    names = [p[0] for p in parts]
    print(f"nodes: {len(parts)}  problems: {problems}")
    print(f"unlit: {gltf.get('extensionsUsed')}")
    print("sample names:", names[:6])

    every = np.concatenate([p[1] for p in parts])
    lo, hi = every.min(axis=0), every.max(axis=0)
    print(f"bounds x[{lo[0]:.2f},{hi[0]:.2f}] y[{lo[1]:.2f},{hi[1]:.2f}] z[{lo[2]:.2f},{hi[2]:.2f}]")

    def cen(prefix):
        sel = [p[1] for p in parts if p[0].startswith(prefix)]
        return np.concatenate(sel).mean(axis=0) if sel else None

    checks = {
        "abs in front of traps (z)": cen("abdominals")[2] > cen("trapezius")[2],
        "traps above calves (y)": cen("trapezius")[1] > cen("calves")[1],
        "pecs in front of lats (z)": cen("pectoralis")[2] > cen("latissimusDorsi")[2],
        "glutes behind quads (z)": cen("glutes")[2] < cen("quadriceps")[2],
        "left side on +x": cen("pectoralis.L")[0] > cen("pectoralis.R")[0],
    }
    print("\n=== anatomical orientation checks ===")
    for k, v in checks.items():
        print(f"  [{'OK ' if v else 'FAIL'}] {k}")

    # ---- z-buffered vertex splat ----
    W, H = 460, 760
    for label, (ax, ay, az, flip) in {
        "front": (0, 1, 2, 1.0),
        "back": (0, 1, 2, -1.0),
        "side": (2, 1, 0, 1.0),
    }.items():
        img = np.full((H, W, 3), 245, np.uint8)
        zbuf = np.full((H, W), -1e9, np.float32)
        span = max(hi[1] - lo[1], 1e-6)
        for name, pos, col, base in parts:
            x = pos[:, ax] * flip
            y = pos[:, ay]
            z = pos[:, az] * flip
            px = ((x - (lo[0] + hi[0]) / 2) / span * H * 0.92 + W / 2).astype(np.int32)
            py = (H * 0.96 - (y - lo[1]) / span * H * 0.92).astype(np.int32)
            ok = (px >= 0) & (px < W) & (py >= 0) & (py < H)
            px, py, z = px[ok], py[ok], z[ok]
            shade = (col[ok, :3].astype(np.float32) / 255.0).mean(axis=1)
            rgb = np.clip(base[None, :] * shade[:, None] * 255.0, 0, 255).astype(np.uint8)
            order = np.argsort(z)
            px, py, z, rgb = px[order], py[order], z[order], rgb[order]
            for k in range(px.shape[0]):
                if z[k] > zbuf[py[k], px[k]]:
                    zbuf[py[k], px[k]] = z[k]
                    img[py[k], px[k]] = rgb[k]
        out = os.path.join(OUTDIR, f"anatomy_{label}.png")
        png(out, img)
        print(f"wrote {out}")


if __name__ == "__main__":
    main()
