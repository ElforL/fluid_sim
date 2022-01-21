import 'dart:math' as math;

import 'package:fluid_sim/simulator.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Simulator sim;

  @override
  void initState() {
    sim = Simulator(10, 10);
    populateSim();
    super.initState();
  }

  void populateSim() {
    sim.setCell(4, 4, 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Liquid Simulation'.toUpperCase(),
              style: Theme.of(context).textTheme.headline4?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: ClipRRect(
                child: SizedBox(
                  width: 700,
                  height: 700,
                  child: CustomPaint(
                    painter: MyPainter(
                      sim: sim,
                      tileWidth: 70,
                      tileHeight: 70,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedBuilder(
              animation: sim,
              builder: (context, child) {
                return Text(
                  'Current iteration: ${sim.iteration}',
                  style: Theme.of(context).textTheme.subtitle1,
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            mini: true,
            onPressed: () {
              sim.stop();
              populateSim();
            },
            tooltip: 'Replay',
            child: const Icon(Icons.replay_rounded),
          ),
          FloatingActionButton(
            mini: true,
            onPressed: () {
              sim.tick();
            },
            tooltip: 'Skip',
            child: const Icon(Icons.skip_next_rounded),
          ),
          FloatingActionButton(
            mini: true,
            onPressed: () {
              if (sim.isRunning) {
                sim.pause();
              } else {
                sim.start();
              }
              setState(() {});
            },
            tooltip: 'Start/Pause',
            child: Icon(sim.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded),
          ),
        ],
      ),
    );
  }
}

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
