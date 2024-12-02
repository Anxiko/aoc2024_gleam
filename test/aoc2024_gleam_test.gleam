import gleam/option.{type Option, None, Some}
import gleam/yielder.{type Yielder}
import gleeunit
import gleeunit/should
import shared/types.{type ProblemPart, Part1, Part2}

import shared/expected.{Parts, read_expected}
import shared/solutions.{solution_mapper}

pub fn main() {
  gleeunit.main()
}

pub fn examples_test() {
  use day <- yielder.each(days())
  run_test(day, True)
}

pub fn reals_test() {
  use day <- yielder.each(days())
  run_test(day, False)
}

fn days() -> Yielder(Int) {
  yielder.range(from: 1, to: 25)
}

fn run_test(day: Int, example: Bool) {
  case read_expected(day, example) {
    Some(Parts(part1: expected_part1, part2: expected_part2)) -> {
      maybe_run_test(day, Part1, example, expected_part1)
      maybe_run_test(day, Part2, example, expected_part2)
    }
    _ -> Nil
  }
}

fn maybe_run_test(
  day: Int,
  part: ProblemPart,
  example: Bool,
  maybe_expected_output: Option(String),
) {
  case maybe_expected_output {
    Some(expected) -> {
      let solver = solution_mapper(day, part, example)
      let actual = solver()

      should.equal(actual, expected)
    }
    None -> Nil
  }
}
