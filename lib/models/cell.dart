import 'package:fluid_sim/models/flow_direction.dart';

class Cell {
  /// The amount of liquid in the cell.
  double level;

  /// The cell's type: Solid or non-solid.
  CellType type;

  /// The directions the liquid is flowing.
  FlowDirections flowDirections = FlowDirections();

  /// The x coordinate of the cell in the array.
  int x;

  /// The y coordinate of the cell in the array.
  int y;

  Cell(
    this.x,
    this.y, {
    this.level = 0,
    this.type = CellType.nonSolid,
  });
}

/// The type of the cell.
///
/// Either solid or non-solid.
enum CellType {
  /// The cell can contain liquid
  nonSolid,

  /// The cell can not contain liquid and it blocks liquid from flowing.
  solid,
}
