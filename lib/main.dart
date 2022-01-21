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
                  tileWidth: 20,
                  tileHeight: 20,
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
  MyPainter({
    required this.tileWidth,
    required this.tileHeight,
    this.backgroundColor = Colors.black38,
  }) : super();

  final Color? backgroundColor;

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

    for (var i = 0; i <= size.width ~/ tileWidth; i++) {
      for (var j = 0; j <= size.height ~/ tileHeight; j++) {
        final Rect r1 = Offset(i * tileWidth, j * tileHeight) & Size(tileWidth, tileHeight);

        canvas.drawRect(
          r1,
          Paint()..color = (i + j).isOdd ? Colors.white24 : Colors.white54,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
