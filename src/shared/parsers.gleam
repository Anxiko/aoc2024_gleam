import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import shared/lists
import simplifile

pub fn parse_bool(raw_bool) -> Option(Bool) {
  case raw_bool {
    "y" | "Y" | "yes" | "Yes" | "t" | "T" | "true" | "True" -> Some(True)
    "n" | "N" | "no" | "No" | "f" | "F" | "false" | "False" -> Some(False)
    _ -> None
  }
}

pub fn unsafe_parse_int(raw_int: String) -> Int {
  let assert Ok(result) = int.parse(raw_int)
  result
}

pub fn parse_sequence(
  line: String,
  parser: fn(String) -> parsed,
) -> List(parsed) {
  line
  |> string.split(on: " ")
  |> list.map(parser)
}

pub fn read_lines(path: String) -> Result(List(String), Nil) {
  let read_result =
    path
    |> simplifile.read()
    |> result.map_error(fn(_) { Nil })

  use contents <- result.map(read_result)
  contents |> string.split("\n") |> list.filter(fn(s) { !string.is_empty(s) })
}

pub fn read_line_chunks(path: String) -> Result(List(List(String)), Nil) {
  let read_result =
    path
    |> simplifile.read()
    |> result.map_error(fn(_) { Nil })

  use contents <- result.map(read_result)
  contents |> string.split("\n") |> lists.split_many(string.is_empty(_), True)
}
