import 'dart:math' as math;

import 'package:fluid_sim/simulator.dart';
import 'package:flutter/material.dart';

import 'models/cell.dart';

class MyPainter extends CustomPainter {
  MyPainter({
    required this.sim,
    this.solidColor = Colors.black,
    this.fillColor = Colors.white60,
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
        final cell = array[y][x];
        final liquidPercent = cell.level / Simulator.maxLvl;

        /// The height of the rect
        /// This is adjusted based on the liquid amount.
        ///
        /// The `math.min()` to prevent the rect being higher than [tileHeight] if the cell is compressed
        double rectHeight;

        final topCell = sim.cellAbove(x, y);
        if ((topCell != null && topCell.level >= Simulator.minLvl) || cell.type == CellType.solid) {
          // If the top cell contains liquid then fill the whole cell (visually).
          rectHeight = tileHeight;
        } else {
          rectHeight = math.min(tileHeight, tileHeight * liquidPercent);
        }

        // Define Rect
        final topLeftOffset = Offset(x * tileWidth, y * tileHeight);
        final offset = Offset(x * tileWidth, y * tileHeight + tileHeight - rectHeight);
        final Rect cellRect = offset & Size(tileWidth, rectHeight);

        Paint? fillPaint;

        if (cell.type == CellType.solid) {
          fillPaint = Paint()..color = solidColor;
        } else if (liquidPercent >= Simulator.minLvl) {
          fillPaint = Paint()..color = fillColor;
        }

        // Draw cell
        if (fillPaint != null) canvas.drawRect(cellRect, fillPaint);

        // Draw level
        if (showLevels) {
          final span = TextSpan(
            text: cell.level.toStringAsFixed(2),
            style: const TextStyle(color: Colors.white54),
          );
          final painter = TextPainter(text: span, textDirection: TextDirection.ltr);
          painter.layout();
          painter.paint(canvas, topLeftOffset);
        }

        // Draw grid
        if (showGrid) {
          final gridRect = topLeftOffset & Size(tileWidth, tileHeight);
          final gridPaint = Paint()
            ..color = Colors.white30
            ..style = PaintingStyle.stroke;

          canvas.drawRect(gridRect, gridPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return oldDelegate.array != array;
  }
}
