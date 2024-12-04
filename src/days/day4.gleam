import gleam/dict
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import shared/dicts

import shared/lists
import shared/parsers
import shared/types.{type ProblemPart, Part1, Part2}

const part1_target = ["X", "M", "A", "S"]

const part2_target = ["M", "A", "S"]

type Row =
  List(String)

pub type Coord =
  #(Int, Int)

type BoardResult {
  Path(start: Coord, delta: Coord)
  Cross(middle: Coord)
}

pub type Input {
  Board(rows: List(Row), width: Int, height: Int)
}

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let #(target, diagonal_only) = case part {
    Part1 -> #(part1_target, False)
    Part2 -> #(part2_target, True)
  }

  input_path
  |> read_input()
  |> search_board(target, diagonal_only)
  |> list.length()
  |> int.to_string()
}

pub fn from_rows(rows: List(Row)) -> Input {
  let assert [row, ..] = rows

  Board(rows: rows, width: list.length(row), height: list.length(rows))
}

pub fn add_coords(left: Coord, right: Coord) -> Coord {
  #(left.0 + right.0, left.1 + right.1)
}

fn scalar_coord(coord: Coord, coef: Int) -> Coord {
  let #(x, y) = coord
  #(x * coef, y * coef)
}

fn search_board(
  board: Input,
  target: Row,
  only_diagonal: Bool,
) -> List(BoardResult) {
  let assert [start, ..rest] = target

  let paths =
    board
    |> find_all(start)
    |> list.flat_map(fn(coord) {
      list.map(deltas(only_diagonal), fn(delta) { #(coord, delta) })
    })
    |> list.filter(fn(vector) {
      let #(coord, delta) = vector
      follow_pattern(board, add_coords(coord, delta), delta, rest)
    })

  case only_diagonal {
    False -> list.map(paths, fn(path) { Path(start: path.0, delta: path.1) })
    True -> {
      let assert Ok(middles) =
        calculate_diagonal_matches(paths, list.length(target))
      list.map(middles, Cross)
    }
  }
}

fn calculate_diagonal_matches(
  vectors: List(#(Coord, Coord)),
  length: Int,
) -> Result(List(Coord), Nil) {
  case length / 2, length % 2 {
    half, 1 -> {
      list.map(vectors, fn(vector) {
        let #(coord, delta) = vector
        delta
        |> scalar_coord(half)
        |> add_coords(coord)
      })
      |> dicts.freq()
      |> dict.filter(fn(middle, count) {
        case count {
          1 -> False
          2 -> True
          _ ->
            panic as string.concat([
              "Unexpected count for ",
              string.inspect(middle),
              ": ",
              int.to_string(count),
            ])
        }
      })
      |> dict.keys()
      |> Ok()
    }
    _, _ -> {
      Error(Nil)
    }
  }
}

pub fn follow_pattern(
  board: Input,
  coord: Coord,
  delta: Coord,
  target: Row,
) -> Bool {
  case target, read_from_board(coord, board) {
    [], _ -> True
    [next, ..rest], Ok(char) if next == char -> {
      follow_pattern(board, add_coords(coord, delta), delta, rest)
    }
    _, _ -> False
  }
}

fn path_coords(start: Coord, delta: Coord, length: Int) {
  case length {
    0 -> []
    remaining if remaining > 0 -> {
      [start, ..path_coords(add_coords(start, delta), delta, length - 1)]
    }
    _ -> panic as "Invalid length"
  }
}

fn find_all(board: Input, char: String) -> List(Coord) {
  board
  |> coords()
  |> list.filter(fn(coord) {
    let assert Ok(contents) = read_from_board(coord, board)
    contents == char
  })
}

pub fn read_from_board(coord: Coord, board: Input) -> Result(String, Nil) {
  let #(x, y) = coord

  use row <- result.try(lists.at(board.rows, y))
  use char <- result.map(lists.at(row, x))
  char
}

fn coords(board: Input) -> List(Coord) {
  lists.product(list.range(0, board.width - 1), list.range(0, board.height - 1))
}

fn deltas(only_diagonal: Bool) -> List(Coord) {
  lists.product(list.range(-1, 1), list.range(-1, 1))
  |> list.filter(fn(coord) {
    let #(x, y) = coord
    case only_diagonal {
      False -> x != 0 || y != 0
      True -> x != 0 && y != 0
    }
  })
}

fn read_input(input_path: String) -> Input {
  let assert Ok(lines) = parsers.read_lines(input_path)

  lines
  |> list.map(string.to_graphemes)
  |> from_rows()
}
