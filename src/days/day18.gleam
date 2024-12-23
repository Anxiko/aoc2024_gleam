import gleam/dict.{type Dict}
import gleam/function
import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder.{type Yielder}

import shared/boards.{type Board}
import shared/coords.{type Coord}
import shared/lists
import shared/pairs
import shared/parsers
import shared/printing
import shared/results
import shared/types.{type ProblemPart, Part1, Part2}

type Path =
  List(Coord)

type Cost {
  Cost(path: Int, total: Int)
}

type NodeInfo {
  NodeInfo(cost: Cost, previous: Set(Coord))
}

type Input {
  Input(coords: List(Coord), size: Int, obstacles: Int)
}

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(input) = read_input(input_path)
  let board =
    boards.from_cell(cell: False, width: input.size, height: input.size)
  let start = #(0, 0)
  let end = #(input.size - 1, input.size - 1)

  case part {
    Part1 -> {
      let board =
        input.coords
        |> list.take(up_to: input.obstacles)
        |> list.fold(board, fn(board, coord) {
          boards.write_coord(board, coord, True)
          |> results.expect("Write coord")
        })

      board
      |> a_star(start:, end:)
      |> results.expect("A* part 1")
      |> int.to_string()
    }
    Part2 -> {
      let board =
        boards.from_cell(cell: False, width: input.size, height: input.size)

      let folded_result =
        input.coords
        |> lists.with_index()
        |> list.try_fold(from: board, with: fn(board, pair) {
          let #(idx, coord) = pair
          io.println(
            "Trying #" <> int.to_string(idx) <> ": " <> coords.to_string(coord),
          )

          let board_with_obstacle =
            boards.write_coord(board, coord, True) |> results.assert_unwrap()
          case a_star(board_with_obstacle, start:, end:) {
            Ok(_) -> Ok(board_with_obstacle)
            Error(Nil) -> Error(coord)
          }
        })

      let #(x, y) = case folded_result {
        Ok(_) -> panic as "Found a path after dropping all obstacles"
        Error(coord) -> coord
      }
      [x, y]
      |> list.map(int.to_string)
      |> string.join(",")
    }
  }
}

fn read_input(input_path: String) -> Result(Input, Nil) {
  let chunks = {
    case parsers.read_line_chunks(input_path) {
      Ok([[size, obstacles], coords]) -> Ok(#(size, obstacles, coords))
      _ -> Error(Nil)
    }
  }

  use #(size, obstacles, coords) <- result.try(chunks)
  let coords =
    coords
    |> list.try_map(fn(line) {
      let split_line = string.split(line, ",")
      use #(x, y) <- result.try(pairs.from_list(split_line))
      coords.parse(x, y)
    })

  use coords <- result.try(coords)
  use size <- result.try(int.parse(size))
  use obstacles <- result.try(int.parse(obstacles))

  Input(coords:, size:, obstacles:) |> Ok()
}

fn a_star(
  board: Board(Bool),
  start initial: Coord,
  end target: Coord,
) -> Result(Int, Nil) {
  let cost = Cost(path: 0, total: heuristic(initial, target))
  let node_info = NodeInfo(cost:, previous: set.new())
  let node_info_mapping =
    do_a_star(
      board,
      set.from_list([initial]),
      dict.from_list([#(initial, node_info)]),
      target,
    )

  node_info_mapping
  |> dict.get(target)
  |> result.map(fn(node_info) { node_info.cost.total })
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
      |> results.expect("Min active")

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
  |> list.filter(fn(pair) { !pair.1 })
  |> list.map(pair.first)
  |> list.map(fn(neighbour) {
    let h = heuristic(neighbour, target)
    let cost = Cost(path: cost.path + 1, total: cost.path + 1 + h)
    #(neighbour, cost)
  })
}

fn heuristic(current: Coord, target: Coord) -> Int {
  target
  |> coords.sub_coords(current)
  |> coords.manhattan()
}

fn reconstruct_path(
  target: Coord,
  node_info_mapping: Dict(Coord, NodeInfo),
) -> Yielder(Path) {
  do_reconstruct_path([target], node_info_mapping)
}

fn do_reconstruct_path(
  path: Path,
  node_info_mapping: Dict(Coord, NodeInfo),
) -> Yielder(Path) {
  let assert Ok(last) = list.first(path)
  let assert Ok(NodeInfo(previous: previous, ..)) =
    dict.get(node_info_mapping, last)

  case set.to_list(previous) {
    [] -> yielder.single(path)
    previous -> {
      previous
      |> yielder.from_list()
      |> yielder.flat_map(fn(next) {
        case list.contains(path, next) {
          True ->
            panic as {
              "Next "
              <> coords.to_string(next)
              <> " is already in path "
              <> string.join(list.map(path, coords.to_string), ", ")
            }
          False -> do_reconstruct_path([next, ..path], node_info_mapping)
        }
      })
    }
  }
}

fn check_walk_back(
  current: Set(Coord),
  seen: Set(Coord),
  node_info_mapping: Dict(Coord, NodeInfo),
) {
  case set.is_empty(current) {
    True -> Nil
    False -> {
      let next =
        current
        |> set.to_list()
        |> list.flat_map(fn(current) {
          let NodeInfo(previous: from_current, ..) =
            node_info_mapping
            |> dict.get(current)
            |> results.expect("Node info for " <> coords.to_string(current))

          case set.is_disjoint(seen, from_current) {
            False -> panic as { "Loop back from " <> coords.to_string(current) }
            True -> set.to_list(from_current)
          }
        })
        |> set.from_list()
      check_walk_back(next, set.union(current, seen), node_info_mapping)
    }
  }
}
