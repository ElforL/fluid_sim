import 'dart:math' as math;

import 'package:fluid_sim/simulator.dart';
import 'package:flutter/material.dart';

import 'models/cell.dart';

class MyPainter extends CustomPainter {
  MyPainter({
    required this.sim,
    this.fillColor = Colors.white60,
    this.emptyColor = Colors.white12,
    required this.tileWidth,
    required this.tileHeight,
    this.showGrid = false,
    this.showLevels = false,
    this.backgroundColor = Colors.black38,
  }) : super(repaint: sim);

  final Simulator sim;
  List<List<Cell>> get array => sim.array;

  final Color? backgroundColor;

  final Color fillColor;
  final Color emptyColor;

  final double tileWidth;
  final double tileHeight;

  bool showGrid;
  bool showLevels;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    if (backgroundColor != null) {
      final paint = Paint()..color = backgroundColor!;
      canvas.drawRect(
        Rect.largest,
        paint,
      );
    }

    for (var y = 0; y < array.length; y++) {
      for (var x = 0; x < array[y].length; x++) {
        final double percent = array[y][x].level;

        // Define Rect
        final offset = Offset(x * tileWidth, y * tileHeight);
        final Rect cellRect = offset & Size(tileWidth, tileHeight);

        // The gradiant shows the level amount by having both colors' stops at [percent].
        final gradient = LinearGradient(
          tileMode: TileMode.decal,
          transform: const GradientRotation(-math.pi / 2),
          stops: [percent, percent],
          colors: [fillColor, emptyColor],
        );

        // apply the gradient
        var fillPaint = Paint()..shader = gradient.createShader(cellRect);

        // Draw cell
        canvas.drawRect(cellRect, fillPaint);

        // Draw level
        if (showLevels) {
          final span = TextSpan(
            text: percent.toStringAsFixed(2),
            style: const TextStyle(color: Colors.white54),
          );
          final painter = TextPainter(text: span, textDirection: TextDirection.ltr);
          painter.layout();
          painter.paint(canvas, offset);
        }

        // Draw grid
        if (showGrid) {
          final gridPaint = Paint()
            ..color = Colors.white30
            ..style = PaintingStyle.stroke;
          canvas.drawRect(cellRect, gridPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return oldDelegate.array != array;
  }
}
