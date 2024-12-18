import gleam/dict.{type Dict}
import gleam/function
import gleam/int
import gleam/list
import gleam/option
import gleam/order
import gleam/pair
import gleam/result
import gleam/set.{type Set}

import shared/boards.{type Board}
import shared/coords.{type Coord}
import shared/directions.{type Direction, Right}
import shared/lists
import shared/parsers
import shared/results
import shared/types.{type ProblemPart, Part1, Part2}

type Maze {
  Maze(board: Board(Bool), start: Coord, end: Coord)
}

type State =
  #(Coord, Direction)

type Costs {
  Costs(g_score: Int, h_score: Int, f_score: Int)
}

const move_cost = 1

const turn_cost = 1000

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(maze) = read_input(input_path)

  let state = #(maze.start, Right)
  let heuristic = heuristic(state, maze.end)
  let costs = Costs(g_score: 0, h_score: heuristic, f_score: heuristic)

  let #(cost, paths) =
    maze.board
    |> a_start(
      set.from_list([state]),
      dict.from_list([#(state, costs)]),
      dict.new(),
      maze.end,
    )
  case part {
    Part1 -> {
      cost
      |> int.to_string()
    }
    Part2 -> {
      paths
      |> list.flatten()
      |> list.map(fn(state) { state.0 })
      |> list.unique()
      |> list.length()
      |> int.to_string()
    }
  }
}

fn read_input(input_path: String) -> Result(Maze, Nil) {
  use lines <- result.try(parsers.read_lines(input_path))
  use board <- result.try(boards.from_lines(lines, Ok))

  let start =
    board
    |> boards.find_cell("S")
    |> lists.unwrap()

  let end =
    board
    |> boards.find_cell("E")
    |> lists.unwrap

  use start <- result.try(start)
  use end <- result.try(end)

  let board = boards.map(board, fn(char) { char == "#" })

  Maze(board:, start:, end:) |> Ok()
}

fn a_start(
  board: Board(Bool),
  active: Set(State),
  nodes: Dict(State, Costs),
  previous: Dict(State, Set(State)),
  target: Coord,
) -> #(Int, List(List(State))) {
  case min_active(active, nodes) {
    Ok(#(#(state, costs), active)) -> {
      let #(active, nodes, previous) =
        board
        |> neighbours(state, costs, target)
        |> list.fold(#(active, nodes, previous), fn(triplet, neighbour) {
          let #(active, nodes, previous) = triplet
          update_with_neighbour(state, neighbour, active, nodes, previous)
        })

      a_start(board, active, nodes, previous, target)
    }
    _ -> {
      let final_states_with_costs =
        directions.directions()
        |> list.map(fn(dir) { #(target, dir) })
        |> list.filter_map(fn(state) {
          dict.get(nodes, state)
          |> result.map(fn(cost) { #(cost, state) })
        })

      let min_cost =
        final_states_with_costs
        |> list.map(pair.first)
        |> lists.min(cost_cmp)
        |> results.expect("At least one path")

      let final_states =
        final_states_with_costs
        |> list.filter(fn(pair) { { pair.0 }.f_score == min_cost.f_score })
        |> list.map(pair.second)

      let paths =
        final_states
        |> list.flat_map(reconstruct(_, previous, []))

      #(min_cost.f_score, paths)
    }
  }
}

fn heuristic(state: State, target: Coord) -> Int {
  target
  |> coords.sub_coords(state.0)
  |> coords.manhattan()
}

fn min_active(
  active: Set(State),
  nodes: Dict(State, Costs),
) -> Result(#(#(State, Costs), Set(State)), Nil) {
  active
  |> set.to_list()
  |> list.map(fn(state) {
    let cost = nodes |> dict.get(state) |> results.assert_unwrap()
    #(state, cost)
  })
  |> lists.min(fn(left, right) { cost_cmp(left.1, right.1) })
  |> result.map(fn(min) { #(min, set.delete(active, min.0)) })
}

fn neighbours(
  board: Board(Bool),
  state: State,
  costs: Costs,
  target: Coord,
) -> List(#(State, Costs)) {
  case state.0 == target {
    True -> []
    False -> {
      [
        try_move(board, state, costs, target),
        Ok(state_with_turn(state, costs, target, directions.rotate_left)),
        Ok(state_with_turn(state, costs, target, directions.rotate_right)),
      ]
      |> list.filter_map(function.identity)
    }
  }
}

fn try_move(
  board: Board(_),
  state: State,
  costs: Costs,
  target: Coord,
) -> Result(#(State, Costs), Nil) {
  let #(coord, dir) = state
  let coord =
    dir
    |> directions.to_delta()
    |> coords.add_coords(coord)

  case boards.read_coord(board, coord) {
    Ok(False) -> {
      let state = #(coord, dir)
      Ok(#(state, update_costs(costs, state, target, move_cost)))
    }
    _ -> Error(Nil)
  }
}

fn state_with_turn(
  state: State,
  costs: Costs,
  target: Coord,
  turn_with: fn(Direction) -> Direction,
) -> #(State, Costs) {
  let state = pair.map_second(state, turn_with)

  let costs = update_costs(costs, state, target, turn_cost)
  #(state, costs)
}

fn update_costs(costs: Costs, state: State, target: Coord, delta_g: Int) {
  let h_score = heuristic(state, target)
  let g_score = costs.g_score + delta_g
  Costs(g_score:, h_score:, f_score: g_score + h_score)
}

fn update_with_neighbour(
  from: State,
  neighbour: #(State, Costs),
  active: Set(State),
  nodes: Dict(State, Costs),
  previous: Dict(State, Set(State)),
) -> #(Set(State), Dict(State, Costs), Dict(State, Set(State))) {
  let #(state, Costs(f_score: new_f_score, ..) as costs) = neighbour

  case dict.get(nodes, state) {
    Ok(Costs(f_score: existing_f_score, ..)) if existing_f_score < new_f_score -> #(
      active,
      nodes,
      previous,
    )

    Ok(Costs(f_score: existing_f_score, ..)) if existing_f_score == new_f_score -> {
      let previous =
        previous
        |> dict.upsert(state, fn(maybe_set) {
          maybe_set
          |> option.lazy_unwrap(set.new)
          |> set.insert(from)
        })

      #(active, nodes, previous)
    }

    _ -> {
      let active = set.insert(active, state)
      let nodes = dict.insert(nodes, state, costs)
      let previous = dict.insert(previous, state, set.from_list([from]))

      #(active, nodes, previous)
    }
  }
}

fn reconstruct(
  current: State,
  previous: Dict(State, Set(State)),
  acc: List(State),
) -> List(List(State)) {
  case dict.get(previous, current) {
    Ok(before) -> {
      before
      |> set.to_list()
      |> list.flat_map(reconstruct(_, previous, [current, ..acc]))
    }
    Error(Nil) -> [[current, ..acc]]
  }
}

fn cost_cmp(left: Costs, right: Costs) -> order.Order {
  int.compare(left.f_score, right.f_score)
}
