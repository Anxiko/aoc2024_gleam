import gleam/list

import shared/lists

pub type Coord =
  #(Int, Int)

pub fn add_coords(left: Coord, right: Coord) -> Coord {
  #(left.0 + right.0, left.1 + right.1)
}

pub fn deltas(
  cross include_cross: Bool,
  diagonal include_diagonal: Bool,
) -> List(Coord) {
  lists.product(list.range(-1, 1), list.range(-1, 1))
  |> list.filter(fn(coord) {
    let #(x, y) = coord
    case x, y {
      0, 0 -> False
      x, y if x != 0 && y != 0 -> include_diagonal
      _, _ -> include_cross
    }
  })
}
