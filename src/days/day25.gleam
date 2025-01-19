import gleam/function
import gleam/int
import gleam/list
import gleam/result
import shared/functions
import shared/lists
import shared/parsers
import shared/results

import shared/boards.{type Board}
import shared/types.{type ProblemPart, Left, Part1, Part2, Right}

type KeyLock {
  Key(List(Int))
  Lock(List(Int))
}

type Input =
  List(KeyLock)

const cylinder_size = 5

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(input) = read_input(input_path)

  let #(keys, lock) =
    input
    |> lists.partition_map(fn(key_lock) {
      case key_lock {
        Key(key) -> Left(key)
        Lock(lock) -> Right(lock)
      }
    })

  case part {
    Part1 -> {
      lists.product(keys, lock)
      |> list.count(fn(pair) {
        let #(key, lock) = pair
        key_lock_fit(key, lock)
      })
      |> int.to_string()
    }
    Part2 -> panic as "There is no part 2, just complete all previous 49 stars!"
  }
}

fn read_input(input_path: String) -> Result(Input, Nil) {
  use chunks <- result.try(parsers.read_line_chunks(input_path))
  use key_locks <- result.try(list.try_map(chunks, parse_key_lock))
  Ok(key_locks)
}

fn parse_key_lock(lines) -> Result(KeyLock, Nil) {
  use board <- result.try(boards.from_lines(lines, parse_cell))
  let top_occupied =
    boards.row_at(board, 0)
    |> results.expect("Read top")
    |> list.all(function.identity)
  let bottom_occupied =
    boards.row_at(board, board.height - 1)
    |> results.expect("Read bottom")
    |> list.all(function.identity)

  case top_occupied, bottom_occupied {
    True, False -> {
      board
      |> parse_key_lock_core()
      |> Lock()
      |> Ok()
    }
    False, True -> {
      board
      |> parse_key_lock_core()
      |> Key()
      |> Ok()
    }
    _, _ -> Error(Nil)
  }
}

fn parse_cell(cell: String) -> Result(Bool, Nil) {
  case cell {
    "#" -> Ok(True)
    "." -> Ok(False)
    _ -> Error(Nil)
  }
}

fn parse_key_lock_core(core: Board(Bool)) -> List(Int) {
  core
  |> boards.columns()
  |> list.map(list.count(_, function.identity))
  |> list.map(int.subtract(_, 1))
}

fn key_lock_fit(key_core: List(Int), lock_core: List(Int)) -> Bool {
  list.zip(key_core, lock_core)
  |> list.map(functions.apply_pair(int.add, _))
  |> list.all(fn(cylinder) { cylinder <= cylinder_size })
}
