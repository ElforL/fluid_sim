class FlowDirections {
  bool up = false;
  bool down = false;
  bool right = false;
  bool left = false;

  FlowDirections({
    this.up = false,
    this.down = false,
    this.right = false,
    this.left = false,
  });

  reset() {
    up = false;
    down = false;
    right = false;
    left = false;
  }

  @override
  String toString() {
    return 'FlowDirections(up:$up, down:$down, right:$right, left:$left)';
  }
}
