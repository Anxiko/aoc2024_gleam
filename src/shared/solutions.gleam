import gleam/int
import gleam/io
import gleam/string

import days/day1
import shared/types.{type ProblemPart}

pub type Solver =
  fn() -> String

pub fn solution_mapper(day: Int, part: ProblemPart, example: Bool) -> Solver {
  let base_solver: fn(ProblemPart, String) -> String = case day {
    1 -> day1.solve

    unimplemented_day if 1 <= unimplemented_day && unimplemented_day <= 25 ->
      todo as "Day not implemented yet"

    _ -> panic as "Invalid day"
  }

  let path =
    string.concat([
      "./data/input/day",
      int.to_string(day),
      "/",
      case example {
        True -> "example.txt"
        False -> "real.txt"
      },
    ])

  io.println(path)

  fn() { base_solver(part, path) }
}
