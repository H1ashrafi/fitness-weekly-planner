import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../domain/entities/anatomy_region.dart';

typedef Polygon = List<Offset>;

@immutable
final class AnatomyShape {
  const AnatomyShape({required this.region, required this.polygon});

  final AnatomyRegion region;
  final Polygon polygon;
}

@immutable
final class AnatomyDecor {
  const AnatomyDecor({required this.polygon, this.isEllipse = false});

  final Polygon polygon;
  final bool isEllipse;
}

@immutable
final class AnatomyFigure {
  const AnatomyFigure({required this.shapes, required this.decor});

  final List<AnatomyShape> shapes;
  final List<AnatomyDecor> decor;
}

abstract final class AnatomyGeometry {
  static const Size viewBox = Size(200, 440);

  static AnatomyFigure of(AnatomyFacing facing) => switch (facing) {
        AnatomyFacing.anterior => _anterior,
        AnatomyFacing.posterior => _posterior,
      };

  static Offset _mirror(Offset point) => Offset(viewBox.width - point.dx, point.dy);

  static Polygon _mirrored(Polygon polygon) =>
      polygon.map(_mirror).toList(growable: false);

  static List<AnatomyShape> _symmetric(
    Map<AnatomyRegion, Polygon> leftSide,
  ) =>
      <AnatomyShape>[
        for (final MapEntry<AnatomyRegion, Polygon> entry in leftSide.entries) ...<AnatomyShape>[
          AnatomyShape(region: entry.key, polygon: entry.value),
          AnatomyShape(region: entry.key, polygon: _mirrored(entry.value)),
        ],
      ];

  static List<AnatomyDecor> _mirroredDecor(Polygon polygon) => <AnatomyDecor>[
        AnatomyDecor(polygon: polygon),
        AnatomyDecor(polygon: _mirrored(polygon)),
      ];

  static const Polygon _head = <Offset>[Offset(77, 15), Offset(123, 73)];

  static const Polygon _neck = <Offset>[
    Offset(90, 66), Offset(110, 66), Offset(113, 90), Offset(87, 90),
  ];

  static const Polygon _trunk = <Offset>[
    Offset(70, 90), Offset(130, 90), Offset(128, 120),
    Offset(120, 158), Offset(122, 206), Offset(78, 206),
    Offset(80, 158), Offset(72, 120),
  ];

  static const Polygon _armLeft = <Offset>[
    Offset(70, 94), Offset(56, 102), Offset(49, 132), Offset(46, 168),
    Offset(44, 200), Offset(43, 224), Offset(55, 227), Offset(60, 202),
    Offset(65, 168), Offset(71, 132),
  ];

  static const Polygon _legLeft = <Offset>[
    Offset(79, 206), Offset(99, 206), Offset(98, 262), Offset(96, 300),
    Offset(92, 356), Offset(93, 404), Offset(96, 412), Offset(80, 412),
    Offset(75, 404), Offset(74, 356), Offset(74, 300), Offset(76, 250),
  ];

  static List<AnatomyDecor> get _bodyDecor => <AnatomyDecor>[
        const AnatomyDecor(isEllipse: true, polygon: _head),
        const AnatomyDecor(polygon: _neck),
        const AnatomyDecor(polygon: _trunk),
        ..._mirroredDecor(_armLeft),
        ..._mirroredDecor(_legLeft),
      ];

  static final AnatomyFigure _anterior = AnatomyFigure(
    decor: _bodyDecor,
    shapes: <AnatomyShape>[
      const AnatomyShape(
        region: AnatomyRegion.abdominals,
        polygon: <Offset>[
          Offset(88, 134), Offset(112, 134), Offset(111, 168),
          Offset(110, 196), Offset(90, 196), Offset(89, 168),
        ],
      ),
      ..._symmetric(const <AnatomyRegion, Polygon>{
        AnatomyRegion.pectoralis: <Offset>[
          Offset(80, 101), Offset(98, 104), Offset(98, 127),
          Offset(84, 129), Offset(79, 114),
        ],
        AnatomyRegion.lateralDeltoid: <Offset>[
          Offset(52, 98), Offset(62, 92), Offset(66, 106),
          Offset(60, 116), Offset(50, 110),
        ],
        AnatomyRegion.anteriorDeltoid: <Offset>[
          Offset(64, 96), Offset(76, 96), Offset(78, 110),
          Offset(68, 118), Offset(63, 108),
        ],
        AnatomyRegion.biceps: <Offset>[
          Offset(55, 122), Offset(69, 120), Offset(66, 152), Offset(54, 150),
        ],
        AnatomyRegion.forearm: <Offset>[
          Offset(52, 158), Offset(66, 156), Offset(60, 200), Offset(48, 196),
        ],
        AnatomyRegion.obliques: <Offset>[
          Offset(80, 140), Offset(87, 138), Offset(88, 178), Offset(81, 172),
        ],
        AnatomyRegion.quadriceps: <Offset>[
          Offset(80, 210), Offset(97, 210), Offset(94, 286), Offset(76, 280),
        ],
        AnatomyRegion.adductors: <Offset>[
          Offset(90, 212), Offset(99, 212), Offset(99, 270), Offset(91, 264),
        ],
      }),
    ],
  );

  static final AnatomyFigure _posterior = AnatomyFigure(
    decor: _bodyDecor,
    shapes: <AnatomyShape>[
      const AnatomyShape(
        region: AnatomyRegion.trapezius,
        polygon: <Offset>[
          Offset(88, 88), Offset(112, 88), Offset(114, 104),
          Offset(100, 128), Offset(86, 104),
        ],
      ),
      const AnatomyShape(
        region: AnatomyRegion.rhomboids,
        polygon: <Offset>[
          Offset(90, 120), Offset(110, 120), Offset(108, 140), Offset(92, 140),
        ],
      ),
      const AnatomyShape(
        region: AnatomyRegion.lowerBack,
        polygon: <Offset>[
          Offset(88, 158), Offset(112, 158), Offset(110, 186), Offset(90, 186),
        ],
      ),
      ..._symmetric(const <AnatomyRegion, Polygon>{
        AnatomyRegion.posteriorDeltoid: <Offset>[
          Offset(52, 98), Offset(66, 94), Offset(70, 110),
          Offset(60, 116), Offset(50, 110),
        ],
        AnatomyRegion.triceps: <Offset>[
          Offset(54, 120), Offset(68, 118), Offset(66, 152), Offset(52, 150),
        ],
        AnatomyRegion.forearm: <Offset>[
          Offset(52, 158), Offset(66, 156), Offset(60, 200), Offset(48, 196),
        ],
        AnatomyRegion.latissimusDorsi: <Offset>[
          Offset(80, 120), Offset(96, 124), Offset(94, 166),
          Offset(78, 150), Offset(76, 132),
        ],
        AnatomyRegion.glutes: <Offset>[
          Offset(80, 190), Offset(99, 190), Offset(99, 222), Offset(78, 218),
        ],
        AnatomyRegion.hamstrings: <Offset>[
          Offset(78, 224), Offset(97, 224), Offset(94, 296), Offset(76, 290),
        ],
        AnatomyRegion.calves: <Offset>[
          Offset(78, 312), Offset(95, 312), Offset(90, 384), Offset(76, 378),
        ],
      }),
    ],
  );
}
