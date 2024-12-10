import gleam/int
import gleam/string

import days/day1
import days/day10
import days/day2
import days/day3
import days/day4
import days/day5
import days/day6
import days/day7
import days/day8
import days/day9
import shared/types.{type ProblemPart}

pub type Solver =
  fn() -> String

pub fn solution_mapper(day: Int, part: ProblemPart, example: Bool) -> Solver {
  let base_solver: fn(ProblemPart, String) -> String = case day {
    1 -> day1.solve
    2 -> day2.solve
    3 -> day3.solve
    4 -> day4.solve
    5 -> day5.solve
    6 -> day6.solve
    7 -> day7.solve
    8 -> day8.solve
    9 -> day9.solve
    10 -> day10.solve

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

  fn() { base_solver(part, path) }
}
