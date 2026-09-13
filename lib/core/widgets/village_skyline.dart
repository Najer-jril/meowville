import 'package:flutter/widgets.dart';

class VillageSkyline extends StatelessWidget {
  const VillageSkyline({
    super.key,
    required this.houseColor,
    required this.windowColor,
    this.height = 64,
    this.alignRight = true,
  });

  final Color houseColor;
  final Color windowColor;
  final double height;

  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _SkylinePainter(
            houseColor: houseColor,
            windowColor: windowColor,
            alignRight: alignRight,
          ),
        ),
      ),
    );
  }
}

class _House {
  const _House(this.width, this.wall, this.ears, this.windows);

  final double width;

  final double wall;
  final bool ears;
  final int windows;
}

class _SkylinePainter extends CustomPainter {
  _SkylinePainter({
    required this.houseColor,
    required this.windowColor,
    required this.alignRight,
  });

  final Color houseColor;
  final Color windowColor;
  final bool alignRight;

  static const List<_House> _houses = <_House>[
    _House(34, 0.34, false, 1),
    _House(52, 0.52, true, 2),
    _House(28, 0.28, false, 0),
    _House(44, 0.62, true, 1),
    _House(60, 0.40, false, 2),
    _House(38, 0.48, true, 1),
  ];

  static const double _gap = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final double total =
        _houses.fold<double>(0, (double sum, _House h) => sum + h.width) +
        _gap * (_houses.length - 1);
    double x = alignRight ? size.width - total : 0;
    if (x < 0) {
      x = 0;
    }

    final Paint body = Paint()..color = houseColor;
    final Paint glass = Paint()..color = windowColor;

    for (final _House house in _houses) {
      if (x + house.width > size.width) {
        break;
      }
      final double wallTop = size.height * (1 - house.wall);
      final double roofPeak = wallTop - size.height * 0.26;
      final double w = house.width;

      final Path path = Path()..moveTo(x, size.height);
      path.lineTo(x, wallTop);
      if (house.ears) {
        // Dua puncak kecil seperti telinga, lekuk di tengah.
        path
          ..lineTo(x + w * 0.22, roofPeak)
          ..lineTo(x + w * 0.38, wallTop - size.height * 0.12)
          ..lineTo(x + w * 0.62, wallTop - size.height * 0.12)
          ..lineTo(x + w * 0.78, roofPeak);
      } else {
        path.lineTo(x + w / 2, roofPeak + size.height * 0.06);
      }
      path
        ..lineTo(x + w, wallTop)
        ..lineTo(x + w, size.height)
        ..close();
      canvas.drawPath(path, body);

      if (house.windows > 0) {
        const double pane = 6;
        final double rowY = wallTop + (size.height - wallTop) * 0.3;
        final double step = w / (house.windows + 1);
        for (int i = 1; i <= house.windows; i++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(x + step * i - pane / 2, rowY, pane, pane + 2),
              const Radius.circular(2),
            ),
            glass,
          );
        }
      }
      x += w + _gap;
    }
  }

  @override
  bool shouldRepaint(_SkylinePainter old) =>
      old.houseColor != houseColor ||
      old.windowColor != windowColor ||
      old.alignRight != alignRight;
}
