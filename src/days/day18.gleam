import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import shared/pairs
import shared/parsers

import shared/boards.{type Board}
import shared/coords.{type Coord}
import shared/lists
import shared/results
import shared/types.{type ProblemPart, Part1, Part2}

type Cost {
  Cost(path: Int, total: Int)
}

type NodeInfo {
  NodeInfo(cost: Cost, previous: Set(Coord))
}

const board_size = 71

const coords_limit = 1024

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(coords) = read_input(input_path)
  case part {
    Part1 -> {
      let board =
        coords
        |> list.take(up_to: coords_limit)
        |> list.fold(
          boards.from_cell(False, width: board_size, height: board_size),
          fn(board, coord) {
            boards.write_coord(board, coord, True) |> results.assert_unwrap()
          },
        )
      let start = #(0, 0)
      let end = #(board_size - 1, board_size - 1)

      board
      |> a_star(start:, end:)
      |> int.to_string()
    }
    Part2 -> todo
  }
}

fn read_input(input_path: String) -> Result(List(Coord), Nil) {
  use lines <- result.try(parsers.read_lines(input_path))
  lines
  |> list.try_map(fn(line) {
    let split_line = string.split(line, ",")
    use #(x, y) <- result.try(pairs.from_list(split_line))
    coords.parse(x, y)
  })
}

fn a_star(board: Board(Bool), start initial: Coord, end target: Coord) -> Int {
  let cost = Cost(path: 0, total: heuristic(initial, target))
  let node_info = NodeInfo(cost:, previous: set.new())
  let node_info =
    do_a_star(
      board,
      set.from_list([initial]),
      dict.from_list([#(initial, node_info)]),
      target,
    )

  let final_node_info =
    dict.get(node_info, target) |> results.expect("Final response")
  final_node_info.cost.total
}

fn do_a_star(
  board: Board(Bool),
  active: Set(Coord),
  node_info_mapping: Dict(Coord, NodeInfo),
  target: Coord,
) -> Dict(Coord, NodeInfo) {
  case min_active(active, node_info_mapping) {
    Ok(#(next, cost, active)) -> {
      let #(active, node_info_mapping) =
        next
        |> neighbours(cost, board, target)
        |> list.fold(#(active, node_info_mapping), fn(acc, neighbour) {
          let #(active, node_info_mapping) = acc
          update_with_neighbour(neighbour, next, active, node_info_mapping)
        })
      do_a_star(board, active, node_info_mapping, target)
    }
    Error(Nil) -> node_info_mapping
  }
}

fn update_with_neighbour(
  neighbour: #(Coord, Cost),
  before_neighbour: Coord,
  active: Set(Coord),
  node_info_mapping: Dict(Coord, NodeInfo),
) -> #(Set(Coord), Dict(Coord, NodeInfo)) {
  case dict.get(node_info_mapping, neighbour.0) {
    Ok(NodeInfo(cost: Cost(total:, ..), ..)) if total < neighbour.1.total -> {
      #(active, node_info_mapping)
    }
    Ok(NodeInfo(cost: Cost(total:, ..), previous:) as node_info)
      if total == neighbour.1.total
    -> {
      let node_info =
        NodeInfo(..node_info, previous: set.insert(previous, before_neighbour))
      let node_info_mapping =
        dict.insert(node_info_mapping, neighbour.0, node_info)
      let active = set.insert(active, neighbour.0)

      #(active, node_info_mapping)
    }
    _ -> {
      let node_info =
        NodeInfo(cost: neighbour.1, previous: set.from_list([before_neighbour]))
      let node_info_mapping =
        dict.insert(node_info_mapping, neighbour.0, node_info)
      let active = set.insert(active, neighbour.0)

      #(active, node_info_mapping)
    }
  }
}

fn min_active(
  active: Set(Coord),
  node_info_mapping: Dict(Coord, NodeInfo),
) -> Result(#(Coord, Cost, Set(Coord)), Nil) {
  active
  |> set.to_list()
  |> list.map(fn(neighbour) {
    let node_info_mapping =
      node_info_mapping
      |> dict.get(neighbour)
      |> results.assert_unwrap()

    #(neighbour, node_info_mapping.cost)
  })
  |> lists.min(by: fn(left, right) {
    let left_cost = left.1
    let right_cost = right.1
    int.compare(left_cost.total, right_cost.total)
  })
  |> result.map(fn(min) { #(min.0, min.1, set.delete(active, min.0)) })
}

fn neighbours(
  current: Coord,
  cost: Cost,
  board: Board(Bool),
  target: Coord,
) -> List(#(Coord, Cost)) {
  board
  |> boards.neighbours(current, diagonals: False)
  |> list.filter(pair.second)
  |> list.map(pair.first)
  |> list.map(fn(neighbour) {
    let h = heuristic(current, target)
    let cost = Cost(path: cost.path + 1, total: cost.path + 1 + h)
    #(neighbour, cost)
  })
}

fn heuristic(current: Coord, target: Coord) -> Int {
  target
  |> coords.sub_coords(current)
  |> coords.manhattan()
}