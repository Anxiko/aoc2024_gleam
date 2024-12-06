import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/set.{type Set}
import gleam/string

import shared/boards.{type Board, from_lines}
import shared/coords.{type Coord}
import shared/parsers
import shared/types.{type ProblemPart, Part1, Part2}

type Direction {
  Up
  Down
  Left
  Right
}

type GuardState =
  #(Coord, Direction)

type Cell {
  Obstacle
  Empty
  Guard(Direction)
}

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(board) = read_input(input_path)
  let assert Ok(#(board, pos, dir)) = extract_guard(board)
  let assert #(path, False) = guard_roam(board, pos, dir)
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
      |> list.filter(fn(coord) {
        let assert Ok(board) = boards.write_coord(board, coord, Obstacle)
        let #(_path, is_loop) = guard_roam(board, pos, dir)
        is_loop
      })
      |> list.length()
      |> int.to_string()
    }
  }
}

fn read_input(input_path: String) -> Result(Board(Cell), Nil) {
  use lines <- result.try(parsers.read_lines(input_path))
  from_lines(lines, cell_parser)
}

fn cell_parser(char: String) -> Result(Cell, Nil) {
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

fn extract_guard(
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

fn guard_roam(
  board: Board(Cell),
  pos: Coord,
  dir: Direction,
) -> #(Set(GuardState), Bool) {
  case boards.is_valid_coord(board, pos) {
    True -> do_roam(board, pos, dir, set.from_list([#(pos, dir)]))
    False ->
      panic as string.concat([
        "Invalid initial roaming position: ",
        string.inspect(pos),
      ])
  }
}

fn do_roam(
  board: Board(Cell),
  pos: Coord,
  dir: Direction,
  path: Set(GuardState),
) -> #(Set(GuardState), Bool) {
  case next_roam_state(board, pos, dir) {
    None -> #(path, False)
    Some(next_state) -> {
      case set.contains(path, next_state) {
        True -> #(path, True)
        False -> {
          let #(next_pos, next_dir) = next_state
          do_roam(board, next_pos, next_dir, set.insert(path, next_state))
        }
      }
    }
  }
}

fn next_roam_state(
  board: Board(Cell),
  pos: Coord,
  dir: Direction,
) -> Option(GuardState) {
  let next_pos =
    dir
    |> direction_to_delta
    |> coords.add_coords(pos)

  case boards.read_coord(board, next_pos) {
    Error(Nil) -> None
    Ok(Obstacle) -> Some(#(pos, rotate_right(dir)))
    Ok(Empty) -> Some(#(next_pos, dir))
    Ok(Guard(_)) ->
      panic as string.concat([
        "Bumped into another guard at ",
        string.inspect(next_pos),
        "!",
      ])
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
