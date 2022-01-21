import 'package:fluid_sim/painter.dart';
import 'package:fluid_sim/simulator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  late TextEditingController _widthController;
  late TextEditingController _heightController;
  late TextEditingController _tickMsController;
  int get inputWidth => int.parse(_widthController.text);
  int get inputHeight => int.parse(_heightController.text);
  int get inputTickMs => int.parse(_tickMsController.text);

  bool showGrid = false;
  bool showLevels = false;

  @override
  void initState() {
    sim = Simulator(20, 20);
    populateSim();

    _widthController = TextEditingController(text: sim.width.toString());
    _heightController = TextEditingController(text: sim.height.toString());
    _tickMsController = TextEditingController(text: sim.tickDuration.inMilliseconds.toString())
      ..addListener(() {
        if (!sim.isRunning) sim.tickDuration = Duration(milliseconds: inputTickMs);
      });
    super.initState();
  }

  @override
  void dispose() {
    _widthController.dispose();
    _heightController.dispose();
    _tickMsController.dispose();
    sim.dispose();
    super.dispose();
  }

  void populateSim() {
    sim.setCell(4, 0, 1);
    int num = 5;
    int h = 1;
    sim.setCell(num++, 0, 1);
    sim.setCell(num++, 0, 1);
    sim.setCell(num++, 0, 1);
    sim.setCell(num++, h, 1);
    sim.setCell(num++, h, 1);
    sim.setCell(num++, h++, 1);
    sim.setCell(num, h++, 1);
    sim.setCell(num, h++, 1);
  }

  @override
  Widget build(BuildContext context) {
    // _widthController.text = sim.width.toString();
    // _heightController.text = sim.height.toString();
    return Scaffold(
      body: SafeArea(
        child: Center(
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
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(child: _buildDebugControls()),
                      Flexible(
                        flex: 3,
                        child: FittedBox(
                          child: ClipRRect(
                            child: SizedBox(
                              width: 700,
                              height: 700,
                              child: CustomPaint(
                                painter: MyPainter(
                                  sim: sim,
                                  tileWidth: 35,
                                  tileHeight: 35,
                                  showGrid: showGrid,
                                  showLevels: showLevels,
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

  Widget _buildDebugControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: const Text('Show Grid'),
          trailing: Switch(
            value: showGrid,
            onChanged: (val) {
              setState(() {
                showGrid = val;
              });
            },
          ),
        ),
        ListTile(
          title: const Text('Show Levels'),
          trailing: Switch(
            value: showLevels,
            onChanged: (val) {
              setState(() {
                showLevels = val;
              });
            },
          ),
        ),
        OptionTile(
          title: Text('Tick duration ${sim.isRunning ? '🔒' : ''}'),
          enabled: !sim.isRunning,
          controller: _tickMsController,
        ),
      ],
    );
  }

  Widget _buildSizeControls() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OptionTile(
          enabled: !sim.isRunning,
          title: const Text('Width:'),
          controller: _widthController,
        ),
        OptionTile(
          enabled: !sim.isRunning,
          title: const Text('Height:'),
          controller: _heightController,
        ),
        Center(
          child: OutlinedButton(
            child: const Text('SET'),
            onPressed: () {
              sim.stop();
              sim.changeWidthHeight(
                newWidth: inputWidth,
                newHeight: inputHeight,
              );
              populateSim();
              setState(() {});
            },
          ),
        ),
      ],
    );
  }
}

class OptionTile extends StatelessWidget {
  const OptionTile({
    Key? key,
    this.enabled = true,
    required this.controller,
    required this.title,
  }) : super(key: key);

  final bool enabled;
  final Widget? title;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      title: title,
      trailing: SizedBox(
        width: 40,
        child: TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly], // Only numbers can be entered
        ),
      ),
    );
  }
}
