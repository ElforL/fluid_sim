import 'package:flutter/material.dart';

class Simulator extends ChangeNotifier {
  Simulator(
    this.width,
    this.height, {
    this.tickDuration = const Duration(milliseconds: 50),
  }) : array = List.generate(height, (i) => List.filled(width, 0));

  /// The duration that the simulator will wait before starting the next tick
  Duration tickDuration;
  int iteration = 0;
  int width, height;
  List<List<double>> array;
  late List<List<double>> nextArray;
  bool isRunning = false;

  void changeWidthHeight({int? newWidth, int? newHeight}) {
    if (isRunning) throw Exception("Can't change size while running");
    width = newWidth ?? width;
    height = newHeight ?? height;
    array = List.generate(height, (i) => List.filled(width, 0));
  }

  void start() {
    isRunning = true;
    _loop();
  }

  void pause() {
    isRunning = false;
    notifyListeners();
  }

  void stop() {
    iteration = 0;
    isRunning = false;
    array = List.generate(height, (i) => List.filled(width, 0));
    notifyListeners();
  }

  /// a single tick
  ///
  /// ### Cell rules:
  /// | The cell | Symbol |
  /// | :- | :-: |
  /// | The current cell | c |
  /// | The cell to the left | l |
  /// | The cell to the right | r |
  /// | The cell to the bottom | b |
  ///
  /// 1. b < 1
  ///     * if (c > 1 - b)
  ///       * c -= 1 - b
  ///       * b = 1
  ///     * else
  ///       * c = 0
  ///       * b += c
  ///
  /// 2. if l and r < c
  ///     * all three cells will have the value: `(c+l+r)/3`
  ///
  /// 3. if a side is >= c
  ///     * ignore that side
  ///
  /// 4. if only one side cell (o) < c
  ///     * λo = (c - o) / 2
  Future<void> tick() async {
    nextArray = List.generate(
      array.length,
      (index) => List.from(array[index]),
    );
    ++iteration;

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final cell = double.parse(array[y][x].toStringAsFixed(4));
        if (cell < 0) throw Exception('Negative value cell. cell $x,$y had the value $cell in iteration $iteration');

        if (cell == 0) continue;

        // 1
        double below = double.parse(_cellBelow(x, y).toStringAsFixed(4));
        if (below < 1 && below != -1) {
          if (cell > 1 - below) {
            _addToCell(x, y, -(1 - below)); // c -= (1 - b)
            _addToCell(x, y + 1, (1 - below)); // b = 1
          } else {
            // print('-' * 20);
            // print('Befor: ${array[y][x]}, ${array[y + 1][x]}');
            _addToCell(x, y, -cell); // c = 0
            _addToCell(x, y + 1, cell); // b += c
            // print('after: ${array[y][x]}, ${array[y + 1][x]}');
            // print('array: ${array[y + 1][x]}\nnext array: ${nextArray[y + 1][x]}');
          }
          continue;
        }

        double left = double.parse(_cellLeft(x, y).toStringAsFixed(4));
        double right = double.parse(_cellRight(x, y).toStringAsFixed(4));
        if (left != -1 && right != -1) {
          // C is not on the border
          if (left < cell && right < cell) {
            final nextVal = (cell + left + right) / 3;
            _addToCell(x, y, nextVal - cell); // set c
            _addToCell(x - 1, y, nextVal - left); // set l
            _addToCell(x + 1, y, nextVal - right); // set r
            continue;
          }
        }

        if (left == -1 || left >= cell) {
          // ignore left
          if (right != -1 && right < cell) {
            /// diff = (c - r) / 2.
            /// this is the amount that will go from c to r
            final diff = (cell - right) / 2;
            _addToCell(x, y, -diff);
            _addToCell(x + 1, y, diff);
            continue;
          }
        }
        if (right == -1 || right >= cell) {
          // ignore right
          if (left != -1 && left < cell) {
            /// diff = (c - l) / 2.
            /// this is the amount that will go from c to l
            final diff = (cell - left) / 2;
            _addToCell(x, y, -diff);
            _addToCell(x - 1, y, diff);
            continue;
          }
        }
      } // end of cell
    } // end of all cells
    array = nextArray;
    notifyListeners();
    await Future.delayed(tickDuration);
  }

  // cancelable operation/future
  // https://stackoverflow.com/questions/17552757/is-there-any-way-to-cancel-a-dart-future/54905898
  /// The main loop
  void _loop() async {
    while (isRunning) {
      await tick();
    }
  }

  setCell(int x, int y, double value) {
    array[y][x] = value;
    notifyListeners();
  }

  _addToCell(int x, int y, double diff) {
    nextArray[y][x] += diff;
  }

  /// returns the value of the cell below x,y
  ///
  /// returns -1 if it doesn't exist
  double _cellBelow(int x, int y) {
    _inBoundCheck(x, y);
    if (y == height - 1) return -1;
    return array[y + 1][x];
  }

  /// returns the value of the cell to the left of x,y
  ///
  /// returns -1 if it doesn't exist
  double _cellLeft(int x, int y) {
    _inBoundCheck(x, y);
    if (x == 0) return -1;
    return array[y][x - 1];
  }

  /// returns the value of the cell to the right of x,y
  ///
  /// returns -1 if it doesn't exist
  double _cellRight(int x, int y) {
    _inBoundCheck(x, y);
    if (x == width - 1) return -1;
    return array[y][x + 1];
  }

  /// Throws an [ArgumentError] if the cell [x],[y] is not in bounds.
  void _inBoundCheck(int x, int y) {
    if (x >= width || x < 0 || y >= height || y < 0) {
      throw ArgumentError('Index out of bounds. ($x,$y) in a ${width}x$height array.');
    }
  }
}
