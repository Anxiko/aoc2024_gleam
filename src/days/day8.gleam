import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/yielder

import shared/boards.{type Board, from_lines}
import shared/coords.{type Coord}
import shared/parsers.{read_lines}
import shared/types.{type ProblemPart, Part1, Part2}

type Cell =
  Option(String)

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(board) = read_input(input_path)
  let antenna_positions = extract_antenna_positions(board)

  let allow_harmonics = case part {
    Part1 -> False
    Part2 -> True
  }

  antenna_positions
  |> dict.values()
  |> list.flat_map(calculate_antinodes(_, board, harmonics: allow_harmonics))
  |> list.unique()
  |> list.length()
  |> int.to_string()
}

fn read_input(input_path: String) -> Result(Board(Cell), Nil) {
  use lines <- result.try(read_lines(input_path))
  use board <- result.map(from_lines(lines, parse_cell))
  board
}

fn parse_cell(char: String) -> Result(Cell, Nil) {
  case char {
    "." | "#" -> None
    antenna -> Some(antenna)
  }
  |> Ok()
}

fn calculate_antinodes(
  antennas: List(Coord),
  board: Board(Cell),
  harmonics allow_harmonics: Bool,
) -> List(Coord) {
  antennas
  |> list.combination_pairs()
  |> list.flat_map(fn(pair) { [pair, pair.swap(pair)] })
  |> list.flat_map(fn(pair) {
    calculate_pair_antinodes(pair.0, pair.1, board, allow_harmonics)
  })
  |> list.filter(boards.is_valid_coord(board, _))
}

fn calculate_pair_antinodes(
  farthest: Coord,
  closest: Coord,
  board: Board(_),
  harmonics allow_harmonics: Bool,
) -> List(Coord) {
  let delta = coords.sub_coords(closest, farthest)

  let limiter = case allow_harmonics {
    False -> fn(coords_yielder) {
      coords_yielder
      |> yielder.drop(1)
      |> yielder.take(1)
    }
    True -> yielder.take_while(_, boards.is_valid_coord(board, _))
  }

  closest
  |> yielder.iterate(coords.add_coords(_, delta))
  |> limiter
  |> yielder.to_list()
}

fn extract_antenna_positions(board: Board(Cell)) -> Dict(String, List(Coord)) {
  board
  |> boards.cells()
  |> list.filter_map(fn(pair) {
    case pair {
      #(_, None) -> Error(Nil)
      #(coord, Some(antenna)) -> Ok(#(coord, antenna))
    }
  })
  |> list.fold(dict.new(), fn(acc, pair) {
    let #(coord, antenna) = pair
    dict.upsert(acc, antenna, fn(maybe_coords) {
      maybe_coords
      |> option.lazy_unwrap(list.new)
      |> list.prepend(coord)
    })
  })
}
