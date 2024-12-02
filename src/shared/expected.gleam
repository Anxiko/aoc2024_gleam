import gleam/dynamic
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import gleam/string
import simplifile

pub type ExpectedOutput {
  Parts(part1: Option(String), part2: Option(String))
}

pub fn decode_expected_output(
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

pub fn read_expected(day: Int, example: Bool) -> Option(ExpectedOutput) {
  let path =
    string.concat([
      "./data/expected_output/",
      "day" <> int.to_string(day) <> "/",
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
