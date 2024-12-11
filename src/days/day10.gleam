import gleam/int
import gleam/list
import gleam/result

import shared/boards.{type Board}
import shared/coords.{type Coord}
import shared/parsers
import shared/types.{type ProblemPart, Part1, Part2}

type Path =
  List(Coord)

const trail_start = 0

const trail_end = 9

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(board) = read_input(input_path)
  let distinct = case part {
    Part1 -> False
    Part2 -> True
  }

  board
  |> boards.coords()
  |> list.map(count_trails(board, _, distinct))
  |> int.sum()
  |> int.to_string()
}

fn read_input(input_path: String) -> Result(Board(Int), Nil) {
  use lines <- result.try(parsers.read_lines(input_path))
  use board <- result.try(boards.from_lines(lines, int.parse))
  Ok(board)
}

fn count_trails(board: Board(Int), pos: Coord, distinct: Bool) -> Int {
  let trails =
    board
    |> continue_trail(pos, [], trail_start)

  let count = case distinct {
    False -> {
      trails
      |> list.map(list.last)
      |> list.unique()
      |> list.length()
    }
    True -> {
      trails
      |> list.length()
    }
  }

  count
}

fn continue_trail(
  board: Board(Int),
  pos: Coord,
  acc: Path,
  next: Int,
) -> List(Path) {
  case boards.read_coord(board, pos) {
    Ok(cell) if cell == next && cell == trail_end -> [
      list.reverse([pos, ..acc]),
    ]
    Ok(cell) if cell == next -> {
      let acc = [pos, ..acc]
      coords.deltas(cross: True, diagonal: False)
      |> list.map(coords.add_coords(pos, _))
      |> list.flat_map(continue_trail(board, _, acc, next + 1))
    }
    _ -> []
  }
}
