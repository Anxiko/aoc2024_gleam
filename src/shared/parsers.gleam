import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string

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
