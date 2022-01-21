import 'dart:math' as math;

import 'package:fluid_sim/simulator.dart';
import 'package:flutter/material.dart';

class MyPainter extends CustomPainter {
  MyPainter({
    required this.sim,
    this.fillColor = Colors.white60,
    this.emptyColor = Colors.white12,
    required this.tileWidth,
    required this.tileHeight,
    this.backgroundColor = Colors.black38,
  }) : super(repaint: sim);

  final Simulator sim;
  List<List<double>> get array => sim.array;

  final Color? backgroundColor;

  final Color fillColor;
  final Color emptyColor;

  final double tileWidth;
  final double tileHeight;

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

    for (var i = 0; i < array.length; i++) {
      for (var j = 0; j < array[i].length; j++) {
        final Rect r1 = Offset(i * tileHeight, j * tileWidth) & Size(tileWidth, tileHeight);

        // the gradient shows the filled amount by having both stops at the [percent]
        final double percent = array[j][i];
        final gradient = LinearGradient(
          transform: const GradientRotation(-math.pi / 2),
          stops: [percent, percent],
          colors: [fillColor, emptyColor],
        );
        // apply shader
        var paint2 = Paint()..shader = gradient.createShader(r1);

        // paint
        canvas.drawRect(r1, paint2);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MyPainter oldDelegate) {
    return oldDelegate.array != array;
  }
}
