import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/yielder

import shared/algorithms.{type NodeInfo}
import shared/boards.{type Board}
import shared/coords.{type Coord}
import shared/dicts
import shared/functions
import shared/lists
import shared/parsers
import shared/results
import shared/types.{type ProblemPart, Part1, Part2}
import shared/yielders

type Input {
  Input(board: Board(Bool), start: Coord, end: Coord, target: Int)
}

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(input) = read_input(input_path)
  let jump_range = case part {
    Part1 -> 2
    Part2 -> 20
  }

  let neighbours_for_board = fn(coord, cost) {
    neighbours(input.board, coord, cost)
  }
  let mapping_from_start =
    algorithms.dijkstra(input.start, neighbours_for_board)
  let mapping_from_end = algorithms.dijkstra(input.end, neighbours_for_board)

  let best_without_cheating =
    mapping_from_start
    |> dict.get(input.end)
    |> results.expect("Reach without cheating")
    |> fn(node_info) { node_info.cost }

  input.board
  |> boards.coords()
  |> list.flat_map(fn(from) {
    from
    |> jump_destinations(board: input.board, range: jump_range)
    |> list.map(pair.new(from, _))
  })
  |> list.filter_map(fn(jump_pair) {
    let #(from, to) = jump_pair
    try_cheat(mapping_from_start, mapping_from_end, from:, to:)
    |> result.map(pair.new(_, jump_pair))
  })
  |> list.map(pair.map_first(_, fn(cost) { best_without_cheating - cost }))
  |> list.filter(fn(pair) { pair.0 >= input.target })
  |> dicts.dict_many()
  |> dict.values()
  |> list.map(set.size)
  |> int.sum()
  |> int.to_string()
}

fn read_input(input_path: String) -> Result(Input, Nil) {
  use chunks <- result.try(parsers.read_line_chunks(input_path))
  let chunks = case chunks {
    [[target], lines] -> Ok(#(target, lines))
    _ -> Error(Nil)
  }
  use #(target, lines) <- result.try(chunks)
  use target <- result.try(int.parse(target))
  use board <- result.try(boards.from_lines(lines, Ok))
  let maybe_start = boards.find_cell(board, "S") |> lists.unwrap()
  use start <- result.try(maybe_start)
  let maybe_end = boards.find_cell(board, "E") |> lists.unwrap()
  use end <- result.try(maybe_end)
  let board = boards.map(board, fn(char) { char == "#" })

  Input(board:, start:, end:, target:) |> Ok()
}

fn neighbours(
  board: Board(Bool),
  coord: Coord,
  cost: Int,
) -> List(#(Coord, Int)) {
  board
  |> boards.neighbours(coord, diagonals: False)
  |> list.filter(functions.negated(pair.second))
  |> list.map(pair.first)
  |> list.map(pair.new(_, cost + 1))
}

fn jump_destinations(
  from from: Coord,
  range jump_range: Int,
  board board: Board(Bool),
) -> List(Coord) {
  let delta = yielder.range(from: -jump_range, to: jump_range)

  yielders.product(delta, delta)
  |> yielder.filter(fn(delta) {
    let manhattan = coords.manhattan(delta)
    manhattan >= 1 && manhattan <= jump_range
  })
  |> yielder.map(coords.add_coords(from, _))
  |> yielder.filter(fn(coord) {
    case boards.read_coord(board, coord) {
      Ok(False) -> True
      _ -> False
    }
  })
  |> yielder.to_list()
}

fn try_cheat(
  start_mappings: Dict(Coord, NodeInfo(Coord)),
  end_mappings: Dict(Coord, NodeInfo(Coord)),
  from jump_from: Coord,
  to jump_to: Coord,
) -> Result(Int, Nil) {
  let jump_cost =
    jump_to
    |> coords.sub_coords(jump_from)
    |> coords.manhattan()

  use jump_from <- result.try(dict.get(start_mappings, jump_from))
  use jump_to <- result.try(dict.get(end_mappings, jump_to))
  let cost = jump_from.cost + jump_cost + jump_to.cost
  Ok(cost)
}
