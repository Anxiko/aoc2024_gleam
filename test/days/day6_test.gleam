import gleam/dict
import gleam/list
import gleam/set
import gleam/string
import gleeunit
import gleeunit/should

import days/day6.{
  type Cell, type Direction, ObstaclePositions, Up, calculate_obstacle_positions,
  cell_parser, extract_guard, roam_states_until_obstacle,
}
import shared/boards.{type Board, from_lines}
import shared/coords.{type Coord}
import shared/printing.{inspect}
import shared/results

pub fn main() {
  gleeunit.main()
}

const raw_board = "
....#.....
.........#
..........
..#.......
.......#..
..........
.#..^.....
........#.
#.........
......#...
"

pub fn calculate_obstacle_positions_test() {
  let by_row =
    dict.from_list([
      #(0, set.from_list([4])),
      #(1, set.from_list([9])),
      #(3, set.from_list([2])),
      #(4, set.from_list([7])),
      #(6, set.from_list([1])),
      #(7, set.from_list([8])),
      #(8, set.from_list([0])),
      #(9, set.from_list([6])),
    ])

  let by_column =
    dict.from_list([
      #(0, set.from_list([8])),
      #(1, set.from_list([6])),
      #(2, set.from_list([3])),
      #(4, set.from_list([0])),
      #(6, set.from_list([9])),
      #(7, set.from_list([4])),
      #(8, set.from_list([7])),
      #(9, set.from_list([1])),
    ])
  let expected = ObstaclePositions(by_row: by_row, by_column: by_column)

  let actual =
    calculate_obstacle_positions(test_board())
    |> inspect(label: "Obstacle positions")

  should.equal(actual, expected)
}

pub fn roam_states_until_obstacle_test() {
  let assert Ok(#(board, _, _)) = extract_guard(test_board())
  let obstacle_positions = calculate_obstacle_positions(board)

  should.equal(
    roam_states_until_obstacle(board, obstacle_positions, #(4, 6), Up),
    #(
      [
        guard_state(4, 5, Up),
        guard_state(4, 4, Up),
        guard_state(4, 3, Up),
        guard_state(4, 2, Up),
        guard_state(4, 1, Up),
      ],
      False,
    ),
  )
}

fn test_board() -> Board(Cell) {
  raw_board
  |> string.split("\n")
  |> list.filter(fn(l) { !string.is_empty(l) })
  |> from_lines(cell_parser)
  |> results.expect("Parse input board")
}

fn guard_state(x: Int, y: Int, dir: Direction) -> #(Coord, Direction) {
  #(#(x, y), dir)
}
