import 'dart:math' as math;

import 'package:liquid_simulator/simulator.dart';
import 'package:flutter/material.dart';

import 'models/cell.dart';

class MyPainter extends CustomPainter {
  MyPainter({
    required this.sim,
    this.solidColor = Colors.black,
    this.fillColor = Colors.white60,
    this.arrowColors = Colors.redAccent,
    required this.tileWidth,
    required this.tileHeight,
    this.showGrid = false,
    this.showLevels = false,
    this.drawDirections = false,
    this.backgroundColor = Colors.black38,
  }) : super(repaint: sim);

  final Simulator sim;
  List<List<Cell>> get array => sim.array;

  final Color? backgroundColor;

  final Color solidColor;
  final Color fillColor;
  final Color arrowColors;

  final double tileWidth;
  final double tileHeight;

  bool showGrid;
  bool showLevels;
  bool drawDirections;

  /// [rotationMultiplier] is how many times the tip of the arrow is rotated by 90°
  void drawArrow(Offset p1, Offset p2, Paint paint, Canvas canvas) {
    canvas.drawLine(p1, p2, paint);

    int rotationMultiplier;

    if (p1.dy == p2.dy) {
      // arrow going up or down
      rotationMultiplier = p1.dx < p2.dx ? 1 : 3;
    } else {
      // arrow going left or right
      rotationMultiplier = p1.dy < p2.dy ? 2 : 0;
    }

    drawTriangle(p2, Size(tileWidth / 4, tileHeight / 4), paint, rotationMultiplier, canvas);
  }

  /// [rotationMultiplier] is how many times the tip of the arrow is rotated by 90°
  void drawTriangle(Offset offset, Size size, Paint paint, int rotationMultiplier, Canvas canvas) {
    // // Up
    final rotation = rotationMultiplier % 4;

    Path? path;
    if (rotation == 0 || rotation == 2) {
      final yOff = rotation == 0 ? -size.height : size.height;
      path = Path();
      path.moveTo(offset.dx, offset.dy + yOff);
      path.lineTo(offset.dx + size.width / 2, offset.dy);
      path.lineTo(offset.dx - size.width / 2, offset.dy);
      path.close();
    } else {
      final xOff = rotation == 3 ? -size.width : size.width;

      path = Path();
      path.moveTo(offset.dx + xOff, offset.dy);
      path.lineTo(offset.dx, offset.dy - size.height / 2);
      path.lineTo(offset.dx, offset.dy + size.height / 2);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    if (backgroundColor != null) {
      final paint = Paint()..color = backgroundColor!;
      canvas.drawRect(
        const Offset(0, 0) & size,
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

        // Draw flow directions
        if (drawDirections) {
          /// The center of the cell
          final center = Offset(topLeftOffset.dx + tileWidth / 2, topLeftOffset.dy + tileHeight / 2);

          final arrowPaint = Paint()..color = arrowColors;
          if (cell.flowDirections.down) {
            drawArrow(
              center,
              Offset(center.dx, center.dy + tileHeight / 4),
              arrowPaint,
              canvas,
            );
          }
          if (cell.flowDirections.up) {
            drawArrow(
              center,
              Offset(center.dx, center.dy - tileHeight / 4),
              arrowPaint,
              canvas,
            );
          }
          if (cell.flowDirections.right) {
            drawArrow(
              center,
              Offset(center.dx + tileWidth / 4, center.dy),
              arrowPaint,
              canvas,
            );
          }
          if (cell.flowDirections.left) {
            drawArrow(
              center,
              Offset(center.dx - tileWidth / 4, center.dy),
              arrowPaint,
              canvas,
            );
          }
        }

        // Draw level
        if (showLevels) {
          final span = TextSpan(
            text: cell.level.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
            ),
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
