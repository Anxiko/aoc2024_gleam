import gleam/dict.{type Dict}
import gleam/function
import gleam/int
import gleam/list
import gleam/option.{type Option, Some}
import gleam/otp/task
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder

import shared/boards.{type Board, from_lines}
import shared/coords.{type Coord}
import shared/parsers
import shared/results
import shared/types.{type ProblemPart, Part1, Part2}

pub type Direction {
  Up
  Down
  Left
  Right
}

type GuardState =
  #(Coord, Direction)

pub type Cell {
  Obstacle
  Empty
  Guard(Direction)
}

pub type ObstaclePositions {
  ObstaclePositions(by_row: Dict(Int, Set(Int)), by_column: Dict(Int, Set(Int)))
}

const path_check_timeout = 5000

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(board) = read_input(input_path)
  let obstacle_positions = calculate_obstacle_positions(board)
  let assert Ok(#(board, pos, dir)) = extract_guard(board)
  let assert #(path, False) = guard_roam(board, obstacle_positions, pos, dir)
  let unique_path_coords =
    path
    |> set.to_list()
    |> list.map(fn(state) { state.0 })
    |> list.unique()

  case part {
    Part1 -> {
      unique_path_coords
      |> list.length()
      |> int.to_string()
    }
    Part2 -> {
      unique_path_coords
      |> list.map(fn(coord) {
        task.async(fn() {
          guard_loops_with_obstacle(board, obstacle_positions, pos, dir, coord)
        })
      })
      |> task.try_await_all(path_check_timeout)
      |> result.all()
      |> results.expect("All guard paths should be checked before timeout")
      |> list.count(function.identity)
      |> int.to_string()
    }
  }
}

fn read_input(input_path: String) -> Result(Board(Cell), Nil) {
  use lines <- result.try(parsers.read_lines(input_path))
  from_lines(lines, cell_parser)
}

pub fn cell_parser(char: String) -> Result(Cell, Nil) {
  case char {
    "#" -> Ok(Obstacle)
    "." -> Ok(Empty)
    "^" -> Ok(Guard(Up))
    ">" -> Ok(Guard(Right))
    "v" -> Ok(Guard(Down))
    "<" -> Ok(Guard(Left))
    _ -> Error(Nil)
  }
}

pub fn extract_guard(
  board: Board(Cell),
) -> Result(#(Board(Cell), Coord, Direction), Nil) {
  let maybe_pair =
    board
    |> boards.cells()
    |> list.find_map(fn(pair) {
      let #(coord, cell) = pair
      case cell {
        Guard(direction) -> Ok(#(coord, direction))
        _ -> Error(Nil)
      }
    })

  use pair <- result.try(maybe_pair)
  let #(coord, direction) = pair
  use updated_board <- result.map(boards.write_coord(board, coord, Empty))
  #(updated_board, coord, direction)
}

fn guard_loops_with_obstacle(
  board: Board(Cell),
  obstacle_positions: ObstaclePositions,
  pos: Coord,
  dir: Direction,
  obstacle: Coord,
) -> Bool {
  let assert Ok(board) = boards.write_coord(board, obstacle, Obstacle)
  let obstacle_positions =
    register_obstacle_position(obstacle_positions, obstacle)
  let #(_path, is_loop) = guard_roam(board, obstacle_positions, pos, dir)
  is_loop
}

fn guard_roam(
  board: Board(Cell),
  obstacle_positions: ObstaclePositions,
  pos: Coord,
  dir: Direction,
) -> #(Set(GuardState), Bool) {
  case boards.is_valid_coord(board, pos) {
    True ->
      do_roam(board, obstacle_positions, pos, dir, set.from_list([#(pos, dir)]))
    False ->
      panic as string.concat([
        "Invalid initial roaming position: ",
        string.inspect(pos),
      ])
  }
}

fn do_roam(
  board: Board(Cell),
  obstacle_positions: ObstaclePositions,
  pos: Coord,
  dir: Direction,
  path: Set(GuardState),
) -> #(Set(GuardState), Bool) {
  case roam_states_until_obstacle(board, obstacle_positions, pos, dir) {
    #(states, True) -> #(set.union(path, set.from_list(states)), False)
    #(states, False) -> {
      let assert Ok(#(next_pos, next_dir)) = list.last(states)
      let states = set.from_list(states)
      case set.is_disjoint(path, states) {
        True ->
          do_roam(
            board,
            obstacle_positions,
            next_pos,
            next_dir,
            set.union(path, states),
          )
        False -> #(set.union(path, states), True)
      }
    }
  }
}

pub fn roam_states_until_obstacle(
  board: Board(Cell),
  obstacle_positions: ObstaclePositions,
  pos: Coord,
  dir: Direction,
) -> #(List(GuardState), Bool) {
  let obstacle_limit = limit_by_obstacle(obstacle_positions, pos, dir)
  let board_limit = limit_by_board(board, pos, dir)

  let #(count, off_grid) = case obstacle_limit, board_limit {
    Some(obstacle_limit), board_limit if obstacle_limit < board_limit -> #(
      obstacle_limit,
      False,
    )
    _, board_limit -> #(board_limit, True)
  }

  case count > 0 {
    True -> {
      let states =
        pos
        |> next_coords(dir, count)
        |> list.map(fn(c) { #(c, dir) })

      #(states, off_grid)
    }
    False -> #([#(pos, rotate_right(dir))], False)
  }
}

fn next_coords(pos: Coord, dir: Direction, count: Int) -> List(Coord) {
  let delta = direction_to_delta(dir)

  pos
  |> yielder.iterate(coords.add_coords(_, delta))
  |> yielder.drop(1)
  |> yielder.take(count)
  |> yielder.to_list()
}

fn limit_by_obstacle(
  obstacle_positions: ObstaclePositions,
  pos: Coord,
  dir: Direction,
) -> Option(Int) {
  let #(x, y) = pos

  let #(movement_axis, perpendicular_axis, mapped_obstacles, limit_finder) = case
    dir
  {
    Up -> #(y, x, obstacle_positions.by_column, find_limit_lesser)
    Down -> #(y, x, obstacle_positions.by_column, find_limit_greater)
    Left -> #(x, y, obstacle_positions.by_row, find_limit_lesser)
    Right -> #(x, y, obstacle_positions.by_row, find_limit_greater)
  }

  mapped_obstacles
  |> dict.get(perpendicular_axis)
  |> option.from_result()
  |> option.then(limit_finder(_, movement_axis))
  |> option.map(fn(o) { int.absolute_value(o - movement_axis) - 1 })
}

fn find_limit_greater(obstacles: Set(Int), pos: Int) -> Option(Int) {
  obstacles
  |> set.to_list()
  |> list.filter(fn(o) { o > pos })
  |> list.reduce(int.min)
  |> option.from_result()
}

fn find_limit_lesser(obstacles: Set(Int), pos: Int) -> Option(Int) {
  obstacles
  |> set.to_list()
  |> list.filter(fn(o) { o < pos })
  |> list.reduce(int.max)
  |> option.from_result()
}

fn limit_by_board(board: Board(Cell), pos: Coord, dir: Direction) -> Int {
  let #(x, y) = pos
  case dir {
    Up -> y
    Down -> board.height - 1 - y
    Right -> board.width - 1 - x
    Left -> x
  }
}

fn direction_to_delta(dir: Direction) -> Coord {
  case dir {
    Up -> #(0, -1)
    Right -> #(1, 0)
    Down -> #(0, 1)
    Left -> #(-1, 0)
  }
}

fn rotate_right(dir: Direction) -> Direction {
  case dir {
    Up -> Right
    Right -> Down
    Down -> Left
    Left -> Up
  }
}

pub fn calculate_obstacle_positions(board: Board(Cell)) -> ObstaclePositions {
  board
  |> boards.cells()
  |> list.filter_map(fn(pair) {
    case pair {
      #(coord, Obstacle) -> Ok(coord)
      _ -> Error(Nil)
    }
  })
  |> list.fold(
    ObstaclePositions(by_row: dict.new(), by_column: dict.new()),
    register_obstacle_position,
  )
}

fn register_obstacle_position(
  obstacle_positions: ObstaclePositions,
  coord: Coord,
) -> ObstaclePositions {
  let #(column, row) = coord

  let updated_by_row = update_mapping(obstacle_positions.by_row, row, column)
  let updated_by_column =
    update_mapping(obstacle_positions.by_column, column, row)

  ObstaclePositions(by_row: updated_by_row, by_column: updated_by_column)
}

fn update_mapping(
  mapping: Dict(a, Set(b)),
  key key: a,
  value value: b,
) -> Dict(a, Set(b)) {
  dict.upsert(mapping, key, fn(maybe_set) {
    maybe_set
    |> option.lazy_unwrap(set.new)
    |> set.insert(value)
  })
}
