import 'package:fluid_sim/painter.dart';
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
            Flexible(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: _buildControls(),
                  ),
                  Flexible(
                    flex: 5,
                    child: FittedBox(
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
                  ),
                  Flexible(
                    child: Container(),
                  ),
                ],
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
      floatingActionButton: _buildFABsControls(),
    );
  }

  Widget _buildFABsControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          mini: true,
          onPressed: () {
            setState(() {
              sim.stop();
            });
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
    );
  }

  Widget _buildControls() => Container();
}
