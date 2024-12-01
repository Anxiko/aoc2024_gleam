import gleam/int
import gleam/io
import gleam/list
import gleam/string
import shared/types.{type ProblemPart, Part1, Part2}
import simplifile

pub fn solve(part: ProblemPart, input_path: String) -> String {
  case part {
    Part1 -> {
      let #(left, right) = read_input(input_path)
      let diff = calculate_difference(left, right)
      int.to_string(diff)
    }
    Part2 -> todo
  }
}

fn calculate_difference(left: List(Int), right: List(Int)) -> Int {
  let left = list.sort(left, by: int.compare)
  let right = list.sort(right, by: int.compare)

  list.zip(left, right)
  |> list.map(fn(pair) { int.absolute_value(pair.0 - pair.1) })
  |> int.sum()
}

fn read_input(input_path: String) -> #(List(Int), List(Int)) {
  let assert Ok(file_contents) = simplifile.read(input_path)

  file_contents
  |> string.split(on: "\n")
  |> list.filter(fn(s) { !string.is_empty(s) })
  |> list.map(line_to_tuple)
  |> list.unzip()
}

fn line_to_tuple(line: String) -> #(Int, Int) {
  let assert [left, right] =
    line
    |> string.split(on: " ")
    |> list.filter(fn(s) { !string.is_empty(s) })

  let assert Ok(left) = int.parse(left)
  let assert Ok(right) = int.parse(right)

  #(left, right)
}
