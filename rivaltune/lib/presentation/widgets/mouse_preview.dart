import 'package:flutter/material.dart';

class MousePreview extends StatelessWidget {
  final int zoneCount;
  final List<Color> zoneColors;

  const MousePreview({
    super.key,
    required this.zoneCount,
    required this.zoneColors,
  });

  @override
  Widget build(BuildContext context) {
    // Simple Rival 3-like mouse shape with zones as colored overlays
    return AspectRatio(
      aspectRatio: 2.2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Mouse body
          CustomPaint(
            size: Size.infinite,
            painter: _MouseBodyPainter(),
          ),
          // Zones
          ...List.generate(zoneCount, (i) {
            return Positioned(
              top: 30.0 + i * 30.0,
              left: 60.0,
              child: Container(
                width: 80,
                height: 24,
                decoration: BoxDecoration(
                  color: zoneColors.length > i ? zoneColors[i].withOpacity(0.7) : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MouseBodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bodyPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.fill;
    final outlinePaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final bodyPath = Path()
      ..moveTo(size.width * 0.5, size.height * 0.1)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.3, size.width * 0.8, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.5, size.height * 1.05, size.width * 0.2, size.height * 0.9)
      ..quadraticBezierTo(size.width * 0.1, size.height * 0.3, size.width * 0.5, size.height * 0.1)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
