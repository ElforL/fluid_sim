import 'package:flutter/material.dart';

import 'models/cell.dart';

class Simulator extends ChangeNotifier {
  Simulator(
    this.width,
    this.height, {
    this.tickDuration = const Duration(milliseconds: 50),
  })  : array = [],
        _diffs = [] {
    _resetDiffs();
    _fillArrayWithCells(height, width);
  }

  /// The minimum amount of liquid a cell can contain
  static const minLvl = 0.001;

  /// The maximum amount of liquid a cell can contain without compression.
  static const maxLvl = 1;

  /// The duration that the simulator will wait before starting the next tick.
  Duration tickDuration;

  /// the number of the current iteration.
  int iteration = 0;

  int width, height;

  /// is the simulation currently running (i.e., the main loop is active);
  bool isRunning = false;

  /// The [width] x [height] 2D array that contains all the cells.
  final List<List<Cell>> array;

  /// The difference of liquid levels to be applied to [array] cells at the end of each tick.
  final List<List<double>> _diffs;

  /// Changes the width and height of the [array] **and resets them all**.
  ///
  /// All cells will turn to empty non-solid cells.
  ///
  /// Throws an [Exception] when called and [isRunning] is `true`.
  void changeWidthHeight({int? newWidth, int? newHeight}) {
    if (isRunning) throw Exception("Can't change size while running");
    width = newWidth ?? width;
    height = newHeight ?? height;
    _fillArrayWithCells(height, width);
  }

  /// Start the simulator/main loop
  void start() {
    isRunning = true;
    _loop();
  }

  /// Pause the simulator/main loop
  void pause() {
    isRunning = false;
    notifyListeners();
  }

  /// Stop the simulator, reset the [iteration] counter, and reset all the cells.
  void stop() {
    isRunning = false;
    iteration = 0;
    _fillArrayWithCells(height, width);
    notifyListeners();
  }

  /// Set the level of the cell at [x],[y]
  void setCellLevel(int x, int y, double lvl) {
    if (array[y][x].type == CellType.solid) return;
    array[y][x].level = lvl;
    notifyListeners();
  }

  /// Set the level of the cell at [x],[y]
  void setCellType(int x, int y, CellType type) {
    array[y][x].type = type;
    notifyListeners();
  }

  // ### Cell rules:
  // | The cell | Symbol |
  // | :- | :-: |
  // | The current cell | c |
  // | The cell to the left | l |
  // | The cell to the right | r |
  // | The cell to the bottom | b |
  //
  // 1. b < 1
  //     * if (c > 1 - b)
  //       * c -= 1 - b
  //       * b = 1
  //     * else
  //       * c = 0
  //       * b += c
  //
  // 2. if l and r < c
  //     * all three cells will have the value: `(c+l+r)/3`
  //
  // 3. if a side is >= c
  //     * ignore that side
  //
  // 4. if only one side cell (o) < c
  //     * λo = (c - o) / 2

  /// a single tick (iteration)
  Future<void> tick() async {
    _resetDiffs();
    ++iteration;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final cell = array[y][x];
        var remainingLiquid = cell.level;

        if (cell.level < 0) {
          throw Exception('Negative value cell. cell $x,$y had the value $cell in iteration $iteration');
        }

        // skip the cell if it's solid or its level is less than the minimum level.
        if (cell.type == CellType.solid || remainingLiquid <= minLvl) {
          cell.level = 0;
          continue;
        }

        // Bottom

        Cell? below = _cellBelow(x, y);
        if (below != null && below.type == CellType.nonSolid && below.level < 1) {
          if (remainingLiquid > 1 - below.level) {
            final diff = 1 - below.level;

            remainingLiquid -= diff;
            _addDiff(x, y, -diff); // c -= (1 - b)
            _addDiff(x, y + 1, diff); // b = 1
          } else {
            remainingLiquid = 0;
            _addDiff(x, y, -cell.level); // c = 0
            _addDiff(x, y + 1, cell.level); // b += c
            continue;
          }
        }

        if (remainingLiquid <= minLvl) {
          cell.level = 0;
          continue;
        }

        // Left and right

        Cell? left = _cellLeft(x, y);
        Cell? right = _cellRight(x, y);

        /// has non solid cells on left and right?
        final hasSideCells =
            left != null && left.type == CellType.nonSolid && right != null && right.type == CellType.nonSolid;

        if (hasSideCells && left.level < remainingLiquid && right.level < remainingLiquid) {
          // C is not on the border
          final nextVal = (remainingLiquid + left.level + right.level) / 3;

          _addDiff(x, y, nextVal - remainingLiquid); // set c
          remainingLiquid += nextVal - remainingLiquid;
          _addDiff(x - 1, y, nextVal - left.level); // set l
          _addDiff(x + 1, y, nextVal - right.level); // set r
        } else {
          if (left == null || left.type == CellType.solid || left.level >= remainingLiquid) {
            // ignore left
            if (right != null && right.type == CellType.nonSolid && right.level < remainingLiquid) {
              /// diff = (c - r) / 2.
              /// this is the amount that will go from c to r
              final diff = (remainingLiquid - right.level) / 2;

              remainingLiquid -= diff;
              _addDiff(x, y, -diff);
              _addDiff(x + 1, y, diff);
            }
          } else if (right == null || right.type == CellType.solid || right.level >= remainingLiquid) {
            // ignore right
            if (left.type == CellType.nonSolid && left.level < remainingLiquid) {
              /// diff = (c - l) / 2.
              /// this is the amount that will go from c to l
              final diff = (remainingLiquid - left.level) / 2;

              remainingLiquid -= diff;
              _addDiff(x, y, -diff);
              _addDiff(x - 1, y, diff);
            }
          }
        }

        if (remainingLiquid <= minLvl) {
          cell.level = 0;
          continue;
        }

        final top = cellAbove(x, y);
        if (top != null && top.type == CellType.nonSolid && remainingLiquid > Simulator.maxLvl) {
          final diff = remainingLiquid - Simulator.maxLvl;

          remainingLiquid -= diff;
          _addDiff(x, y, -diff);
          _addDiff(x, y - 1, diff);
        }
      } // end of cell
    } // end of all cells

    for (var y = 0; y < array.length; y++) {
      for (var x = 0; x < array[y].length; x++) {
        var cell = array[y][x];

        cell.level += _diffs[y][x];
        if (cell.level < minLvl) cell.level = 0;
      }
    }

    notifyListeners();
  }

  /// The main loop
  void _loop() async {
    while (isRunning) {
      await tick();
      await Future.delayed(tickDuration);
    }
  }

  _addDiff(int x, int y, double diff) {
    _diffs[y][x] += diff;
  }

  /// returns the cell above the cell at x,y
  ///
  /// returns `null` if it doesn't exist
  Cell? cellAbove(int x, int y) {
    _inBoundCheck(x, y);
    if (y <= 0) return null;
    return array[y - 1][x];
  }

  /// returns the cell below the cell at x,y
  ///
  /// returns `null` if it doesn't exist
  Cell? _cellBelow(int x, int y) {
    _inBoundCheck(x, y);
    if (y == height - 1) return null;
    return array[y + 1][x];
  }

  /// returns the cell to the left of the cell at x,y
  ///
  /// returns `null` if it doesn't exist
  Cell? _cellLeft(int x, int y) {
    _inBoundCheck(x, y);
    if (x == 0) return null;
    return array[y][x - 1];
  }

  /// returns the cell to the right of the cell at x,y
  ///
  /// returns `null` if it doesn't exist
  Cell? _cellRight(int x, int y) {
    _inBoundCheck(x, y);
    if (x == width - 1) return null;
    return array[y][x + 1];
  }

  /// Throws an [ArgumentError] if the coordinates [x],[y] are not in bounds.
  void _inBoundCheck(int x, int y) {
    if (x >= width || x < 0 || y >= height || y < 0) {
      throw ArgumentError('Index out of bounds. ($x,$y) in a ${width}x$height array.');
    }
  }

  /// Modifies [array] to be a [height]x[width] 2D list filled with `Cell(x,y)`
  void _fillArrayWithCells(int height, int width) {
    // Clear te array.
    // This make the array = []
    array.removeRange(0, array.length);

    // populate it
    for (var y = 0; y < height; y++) {
      // add a new row
      array.insert(y, []);

      // fill the row
      for (var x = 0; x < width; x++) {
        array[y].insert(x, Cell(x, y));
      }
    }
  }

  /// Resets all elements in [_diffs] to zeros.
  void _resetDiffs() {
    // Clear te array.
    // This will make diffs = []
    _diffs.removeRange(0, _diffs.length);

    // populate it
    for (var y = 0; y < array.length; y++) {
      // add a new row
      _diffs.insert(y, []);

      // fill the row
      for (var x = 0; x < array[y].length; x++) {
        _diffs[y].insert(x, 0.0);
      }
    }
  }
}
