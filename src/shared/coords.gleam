import gleam/int
import gleam/list
import gleam/result

import shared/lists

pub type Coord =
  #(Int, Int)

pub fn add_coords(left: Coord, right: Coord) -> Coord {
  #(left.0 + right.0, left.1 + right.1)
}

pub fn sub_coords(left: Coord, right: Coord) -> Coord {
  #(left.0 - right.0, left.1 - right.1)
}

pub fn scalar(coord: Coord, coef: Int) -> Coord {
  let #(x, y) = coord
  #(coef * x, coef * y)
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

pub fn decompose(coord: Coord) -> #(Coord, Coord) {
  let #(x, y) = coord
  #(#(x, 0), #(0, y))
}

pub fn parse(raw_x: String, raw_y: String) -> Result(Coord, Nil) {
  use x <- result.try(int.parse(raw_x))
  use y <- result.try(int.parse(raw_y))
  Ok(#(x, y))
}
