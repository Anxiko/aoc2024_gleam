import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option
import gleam/result
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
    Part2 -> {
      let #(left, right) = read_input(input_path)
      let diff = calculate_similarity(left, right)
      int.to_string(diff)
    }
  }
}

fn calculate_difference(left: List(Int), right: List(Int)) -> Int {
  let left = list.sort(left, by: int.compare)
  let right = list.sort(right, by: int.compare)

  list.zip(left, right)
  |> list.map(fn(pair) { int.absolute_value(pair.0 - pair.1) })
  |> int.sum()
}

fn calculate_similarity(left: List(Int), right: List(Int)) -> Int {
  let freq_left = freq(left)
  let freq_right = freq(right)

  freq_left
  |> dict.fold(from: 0, with: fn(acc, number, count_left) {
    let count_right = freq_right |> dict.get(number) |> result.unwrap(0)

    acc + number * count_left * count_right
  })
}

fn freq(numbers: List(Int)) -> Dict(Int, Int) {
  numbers
  |> list.fold(from: dict.new(), with: increment_freq)
}

fn increment_freq(d: Dict(Int, Int), number: Int) -> Dict(Int, Int) {
  dict.upsert(d, number, with: fn(maybe_freq) {
    option.unwrap(maybe_freq, 0) + 1
  })
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
