import envoy
import gleam/erlang/atom
import gleam/option.{type Option, None, Some}
import gleam/result
import gleeunit
import gleeunit/should

import shared/expected.{Parts, read_expected}
import shared/parsers
import shared/solutions.{solution_mapper}
import shared/types.{type ProblemPart, Part1, Part2}

pub fn main() {
  gleeunit.main()
}

pub fn day1_test() {
  run_test(day: 1, example: False, part1: True, part2: True)
  run_test(day: 1, example: True, part1: True, part2: True)
}

pub fn day2_test() {
  run_test(day: 2, example: False, part1: True, part2: True)
  run_test(day: 2, example: True, part1: True, part2: True)
}

pub fn day3_test() {
  run_test(day: 3, example: False, part1: True, part2: True)
  run_test(day: 3, example: True, part1: True, part2: True)
}

pub fn day4_test() {
  run_test(day: 4, example: False, part1: True, part2: True)
  run_test(day: 4, example: True, part1: True, part2: True)
}

pub fn day5_test() {
  run_test(day: 5, example: False, part1: True, part2: True)
  run_test(day: 5, example: True, part1: True, part2: True)
}

pub fn day6_test_() {
  use <- with_timeout(10)
  run_test(day: 6, example: False, part1: True, part2: True)
  run_test(day: 6, example: True, part1: True, part2: True)
}

pub fn day7_test() {
  run_test(day: 7, example: False, part1: True, part2: True)
  run_test(day: 7, example: True, part1: True, part2: True)
}

pub fn day8_test() {
  run_test(day: 8, example: False, part1: True, part2: True)
  run_test(day: 8, example: True, part1: True, part2: True)
}

pub fn day9_test() {
  run_test(day: 9, example: False, part1: True, part2: True)
  run_test(day: 9, example: True, part1: True, part2: True)
}

pub fn day10_test() {
  run_test(day: 10, example: False, part1: True, part2: True)
  run_test(day: 10, example: True, part1: True, part2: True)
}

pub fn day11_test() {
  run_test(day: 11, example: True, part1: True, part2: True)
  run_test(day: 11, example: False, part1: True, part2: True)
}

pub fn day12_test() {
  run_test(day: 12, example: True, part1: True, part2: True)
  run_test(day: 12, example: False, part1: True, part2: True)
}

pub fn day13_test() {
  run_test(day: 12, example: True, part1: True, part2: False)
  run_test(day: 12, example: False, part1: True, part2: False)
}

fn with_timeout(
  timeout: Int,
  f: fn() -> Nil,
) -> #(atom.Atom, Int, List(fn() -> Nil)) {
  #(atom.create_from_string("timeout"), timeout, [f])
}

fn run_test(
  day day: Int,
  example example: Bool,
  part1 part1: Bool,
  part2 part2: Bool,
) {
  let must_run = example || should_run_real()

  case must_run {
    True -> {
      let assert Some(Parts(part1: expected_part1, part2: expected_part2)) =
        read_expected(day, example)
      maybe_run_day_part(day, Part1, example, part1, expected_part1)
      maybe_run_day_part(day, Part2, example, part2, expected_part2)
    }
    False -> Nil
  }
}

fn maybe_run_day_part(
  day: Int,
  part: ProblemPart,
  example: Bool,
  must_run: Bool,
  maybe_expected: Option(String),
) {
  case must_run, maybe_expected {
    False, _ -> Nil
    True, None -> should.fail()
    True, Some(expected_part1) -> {
      run_day_part(day, part, example, expected_part1)
    }
  }
}

fn run_day_part(day: Int, part: ProblemPart, example: Bool, expected: String) {
  let solver = solution_mapper(day, part, example)
  let actual = solver()

  should.equal(actual, expected)
}

fn should_run_real() -> Bool {
  "AOC2024_RUN_REAL"
  |> envoy.get()
  |> result.try(fn(value) {
    value
    |> parsers.parse_bool()
    |> option.to_result(Nil)
  })
  |> result.unwrap(False)
}
