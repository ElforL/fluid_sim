import 'dart:math' as math;

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
  bool isPlaying = false;

  late List<List<double>> array;

  @override
  void initState() {
    array = List.generate(20, (index) => List.generate(20, (index) => math.Random().nextDouble()));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌊'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: ClipRRect(
            child: SizedBox(
              width: 700,
              height: 700,
              child: CustomPaint(
                painter: MyPainter(
                  array,
                  tileWidth: 35,
                  tileHeight: 35,
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            isPlaying = !isPlaying;
          });
        },
        tooltip: 'Start/Pause',
        child: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  MyPainter(
    this.array, {
    Listenable? repaint,
    this.fillColor = Colors.white60,
    this.emptyColor = Colors.white12,
    required this.tileWidth,
    required this.tileHeight,
    this.backgroundColor = Colors.black38,
  }) : super(repaint: repaint);

  final List<List<double>> array;

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
        final Rect r1 = Offset(i * tileWidth, j * tileHeight) & Size(tileWidth, tileHeight);

        // the gradient shows the filled amount by having both stops at the [percent]
        final double percent = array[i][j];
        final gradient = LinearGradient(
          transform: const GradientRotation(-math.pi / 2),
          stops: [
            percent,
            percent,
          ],
          colors: [
            fillColor,
            emptyColor,
          ],
        );
        // apply shader
        var paint2 = Paint()..shader = gradient.createShader(r1);

        // paint
        canvas.drawRect(
          r1,
          paint2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
