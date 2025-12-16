import 'package:flutter/material.dart';

class BatteryIcon extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final Color? color;

  const BatteryIcon({super.key, this.size = 24, this.strokeWidth = 0.7, this.color});

  @override
  Widget build(BuildContext context) {
    final Color paintColor = color ?? IconTheme.of(context).color ?? Colors.black;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BatteryPainter(paintColor, strokeWidth),
      ),
    );
  }
}

class _BatteryPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _BatteryPainter(this.color, this.strokeWidth);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // battery body (rounded rect)
    final double terminalWidth = size.width * 0.08;
    final double bodyWidth = size.width - terminalWidth - 2.0; // small gap
    final double bodyHeight = size.height * 0.6;
    final double bodyLeft = 1.0;
    final double bodyTop = (size.height - bodyHeight) / 2;
    final RRect bodyRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(bodyLeft, bodyTop, bodyWidth, bodyHeight),
        Radius.circular(bodyHeight * 0.12));

    canvas.drawRRect(bodyRect, paint);

    // terminal (small rect at right)
    final double termLeft = bodyLeft + bodyWidth + 1.0;
    final double termTop = size.height * 0.33;
    final double termHeight = size.height * 0.34;
    final Rect termRect = Rect.fromLTWH(termLeft, termTop, terminalWidth, termHeight);
    canvas.drawRect(termRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
