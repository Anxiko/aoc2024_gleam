import shared/coords.{type Coord}

pub type Direction {
  Up
  Down
  Left
  Right
}

pub fn to_delta(dir: Direction) -> Coord {
  case dir {
    Up -> #(0, -1)
    Right -> #(1, 0)
    Down -> #(0, 1)
    Left -> #(-1, 0)
  }
}

pub fn rotate_right(dir: Direction) -> Direction {
  case dir {
    Up -> Right
    Right -> Down
    Down -> Left
    Left -> Up
  }
}

pub fn rotate_left(dir: Direction) -> Direction {
  case dir {
    Up -> Left
    Right -> Up
    Down -> Right
    Left -> Down
  }
}

pub fn directions() -> List(Direction) {
  [Up, Right, Down, Left]
}
