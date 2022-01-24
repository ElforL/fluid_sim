import 'dart:math' as math;

import 'package:fluid_sim/simulator.dart';
import 'package:flutter/material.dart';

import 'models/cell.dart';

class MyPainter extends CustomPainter {
  MyPainter({
    required this.sim,
    this.solidColor = Colors.black,
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

  final Color solidColor;
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
        var cell = array[y][x];

        // Define Rect
        final offset = Offset(x * tileWidth, y * tileHeight);
        final Rect cellRect = offset & Size(tileWidth, tileHeight);

        Paint fillPaint;

        if (cell.type == CellType.nonSolid) {
          // The gradiant shows the level amount by having both colors' stops at [cell.level].
          final gradient = LinearGradient(
            tileMode: TileMode.decal,
            transform: const GradientRotation(-math.pi / 2),
            stops: [cell.level, cell.level],
            colors: [fillColor, emptyColor],
          );

          final topCell = sim.cellAbove(x, y);
          if (cell.level >= Simulator.minLvl && topCell != null && topCell.level >= Simulator.minLvl) {
            // If the top cell contains liquid then fill this cell (visually).
            fillPaint = Paint()..color = fillColor;
          } else {
            // apply the gradient
            fillPaint = Paint()..shader = gradient.createShader(cellRect);
          }
        } else {
          fillPaint = Paint()..color = solidColor;
        }

        // Draw cell
        canvas.drawRect(cellRect, fillPaint);

        // Draw level
        if (showLevels) {
          final span = TextSpan(
            text: cell.level.toStringAsFixed(2),
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
