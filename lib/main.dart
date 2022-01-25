// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

import 'package:liquid_simulator/models/cell.dart';
import 'package:liquid_simulator/painter.dart';
import 'package:liquid_simulator/simulator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  window.document.onContextMenu.listen((evt) => evt.preventDefault());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liquid Simulator',
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
  bool drawDirections = false;

  final double canvasHeight = 700;
  final double canvasWidth = 700;

  late double tileWidth;
  late double tileHeight;

  @override
  void initState() {
    sim = Simulator(
      30, // initial width
      30, // initial height
      tickDuration: const Duration(milliseconds: 20),
    );

    _widthController = TextEditingController(text: sim.width.toString());
    _heightController = TextEditingController(text: sim.height.toString());
    _tickMsController = TextEditingController(text: sim.tickDuration.inMilliseconds.toString())
      ..addListener(() {
        if (!sim.isRunning) {
          try {
            sim.tickDuration = Duration(milliseconds: inputTickMs);
          } on FormatException catch (_) {
            // This happens when the user clears the textfield
            // So `inputTickMs()` will parse an empty string which throws a [FormatException]
            //
            // if this happens set the tick duraton to 5 ms
            sim.tickDuration = const Duration(milliseconds: 5);
          }
        }
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final moveSizeControls = size.width < 1150;
    final allVertical = size.width < 950;

    tileWidth = canvasWidth / sim.width;
    tileHeight = canvasHeight / sim.height;
    _tickMsController.text = sim.tickDuration.inMilliseconds.toString();

    var painter = Padding(
      padding: EdgeInsets.symmetric(horizontal: 15),
      child: FittedBox(
        child: ClipRRect(
          child: SizedBox(
            width: canvasWidth,
            height: canvasHeight,
            child: Listener(
              onPointerDown: onPointerDown,
              onPointerMove: onPointerMove,
              child: CustomPaint(
                painter: MyPainter(
                  sim: sim,
                  tileWidth: tileWidth,
                  tileHeight: tileHeight,
                  showGrid: showGrid,
                  showLevels: showLevels,
                  drawDirections: drawDirections,
                  fillColor: Colors.blueAccent.shade100,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
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
                allVertical
                    ? painter
                    : Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(child: _buildDebugControls()),
                            painter,
                            if (!moveSizeControls)
                              Flexible(
                                child: _buildSizeControls(),
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
                if (allVertical) ...[
                  const Divider(),
                  _buildDebugControls(),
                ],
                if (moveSizeControls || allVertical) ...[
                  const Divider(),
                  _buildSizeControls(),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFABsControls(),
    );
  }

  /// This variable is used to determine wheter the touch input should remove or build solid bolcks
  ///
  /// if it's `true` the entire user swipe will remove any solid blocks it comes across.
  /// if it's `false` it'll set every cell it comes across to solid.
  ///
  /// The variable is set every time the user starts a swipe (in `onPointerDown()`).
  bool _isRemoveMode = true;

  void onPointerDown(PointerDownEvent details) {
    final coords = getCellCoords(details.localPosition);
    if (coords == null) return;

    // Set touch mode
    _isRemoveMode = sim.array[coords[1]][coords[0]].type == CellType.solid;

    if (details.buttons == 1) {
      // Set cell
      setCellType(coords);
    } else if (details.buttons == 2) {
      // Add 1.0 to cell lvl
      sim.setCellLevel(coords[0], coords[1], 1);
    }
  }

  void onPointerMove(PointerMoveEvent details) {
    final coords = getCellCoords(details.localPosition);
    if (coords == null) return;

    if (details.buttons == 1) {
      // Set cell
      setCellType(coords);
    } else if (details.buttons == 2) {
      // Add 1.0 to cell lvl
      sim.setCellLevel(coords[0], coords[1], 1);
    }
  }

  void setCellType(List<int> coords) {
    sim.setCellType(coords[0], coords[1], _isRemoveMode ? CellType.nonSolid : CellType.solid);
  }

  /// Returns the cell coordinates (as `[x, y]`) that [position] is in.
  ///
  /// __[posision] must be the local position in the canvas and not the global position.__
  ///
  /// Returns null if [posistion] is outside the canvas.
  List<int>? getCellCoords(Offset position) {
    // if the [position] is outside the canvas return null
    if (position.dx < 0 || position.dx > canvasWidth || position.dy < 0 || position.dy > canvasHeight) {
      return null;
    }

    int x = position.dx ~/ tileWidth;
    int y = position.dy ~/ tileHeight;

    return [x, y];
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
          },
          tooltip: 'Replay',
          child: const Icon(Icons.replay_rounded),
        ),
        FloatingActionButton(
          mini: true,
          onPressed: () async {
            await sim.tick();
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
        ListTile(
          title: const Text('Show Flow Directions'),
          trailing: Switch(
            value: drawDirections,
            onChanged: (val) {
              setState(() {
                drawDirections = val;
              });
            },
          ),
        ),
        OptionTile(
          title: const Text('Tick duration'),
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
