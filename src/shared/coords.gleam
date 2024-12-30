import gleam/int
import gleam/list
import gleam/order.{type Order}
import gleam/result
import gleam/string

import shared/lists
import shared/results

pub type Coord =
  #(Int, Int)

pub fn add_coords(left: Coord, right: Coord) -> Coord {
  #(left.0 + right.0, left.1 + right.1)
}

pub fn sub_coords(left: Coord, right: Coord) -> Coord {
  #(left.0 - right.0, left.1 - right.1)
}

pub fn manhattan(coord: Coord) -> Int {
  let #(x, y) = coord
  int.absolute_value(x) + int.absolute_value(y)
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

pub fn wrap_around(coord: Coord, max: Coord) -> Coord {
  let x =
    coord.0
    |> int.modulo(by: max.0)
    |> results.assert_unwrap()

  let y =
    coord.1
    |> int.modulo(by: max.1)
    |> results.assert_unwrap()

  #(x, y)
}

pub fn compare(left: Coord, right: Coord) -> Order {
  let x_compare = int.compare(left.0, right.0)
  let y_compare = int.compare(left.1, right.1)

  order.break_tie(x_compare, y_compare)
}

pub fn to_string(coord: Coord) -> String {
  let #(x, y) = coord
  string.concat(["(", int.to_string(x), ",", int.to_string(y), ")"])
}

pub fn is_origin(coord: Coord) -> Bool {
  coord == #(0, 0)
}
