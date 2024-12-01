import argv
import gleam/int
import gleam/io
import gleam/option.{type Option, Some}

import shared/parsers.{parse_bool}
import shared/solutions.{solution_mapper}
import shared/types.{type ProblemPart, part_from_int}

pub fn main() {
  let loaded_argv = argv.load()

  case loaded_argv.arguments {
    [day, part, example] -> {
      let assert Some(#(day, part, example)) = parse_args(day, part, example)
      let solution_calculator = solution_mapper(day, part, example)
      let solution = solution_calculator()
      io.println("Solution: " <> solution)
    }

    _ -> io.println("Usage: " <> loaded_argv.program <> " day part example")
  }
}

fn parse_args(
  raw_day: String,
  raw_part: String,
  raw_example: String,
) -> Option(#(Int, ProblemPart, Bool)) {
  use day <- option.then(raw_day |> int.parse() |> option.from_result())
  use part <- option.then(raw_part |> int.parse() |> option.from_result())
  use part <- option.then(part_from_int(part))
  use example <- option.then(parse_bool(raw_example))
  Some(#(day, part, example))
}
