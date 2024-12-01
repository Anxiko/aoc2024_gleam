import gleam/dynamic
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/yielder.{type Yielder}
import gleeunit
import gleeunit/should
import shared/types.{type ProblemPart, Part1, Part2}
import simplifile

import shared/solutions.{solution_mapper}

type ExpectedOutput {
  Parts(part1: Option(String), part2: Option(String))
}

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

fn read_expected(day: Int, example: Bool) -> Option(ExpectedOutput) {
  let path =
    string.concat([
      "./data/expected_output/",
      "day" <> int.to_string(day),
      case example {
        False -> "real.json"
        True -> "example.json"
      },
    ])

  case simplifile.read(path) {
    Ok(file_contents) -> {
      let assert Ok(expected_output) = decode_expected_output(file_contents)
      Some(expected_output)
    }

    Error(simplifile.Enoent) -> None

    Error(error) -> panic as { "Couldn't read file: " <> string.inspect(error) }
  }
}

fn decode_expected_output(
  json_string: String,
) -> Result(ExpectedOutput, json.DecodeError) {
  let decoder =
    dynamic.decode2(
      Parts,
      dynamic.optional_field("part1", of: dynamic.string),
      dynamic.optional_field("part2", of: dynamic.string),
    )

  json.decode(from: json_string, using: decoder)
}
