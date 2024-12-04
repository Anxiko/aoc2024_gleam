import gleam/list
import gleam/string
import gleeunit
import gleeunit/should

import days/day4.{
  type Input, add_coords, follow_pattern, from_rows, read_from_board,
}

const board = "
....XXMAS.
.SAMXMS...
...S..A...
..A.A.MS.X
XMASAMX.MM
X.....XA.A
S.S.S.S.SS
.A.A.A.A.A
..M.M.M.MM
.X.X.XMASX
"

pub fn main() {
  gleeunit.main()
}

fn test_board() -> Input {
  board
  |> string.split("\n")
  |> list.filter(fn(s) { !string.is_empty(s) })
  |> list.map(string.to_graphemes(_))
  |> from_rows()
}

pub fn follow_pattern_test() {
  let coord = #(5, 0)
  let delta = #(1, 0)
  let assert [_first, ..rest] = ["X", "M", "A", "S"]
  should.be_true(follow_pattern(
    test_board(),
    add_coords(coord, delta),
    delta,
    rest,
  ))
}

pub fn read_from_board_test() {
  let coord = add_coords(#(5, 0), #(1, -1))

  should.be_error(read_from_board(coord, test_board()))
}
