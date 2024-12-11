import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option
import gleam/pair
import gleam/result
import gleam/string

import shared/dicts
import shared/functions
import shared/parsers.{read_single_line}
import shared/strings
import shared/types.{type ProblemPart, Part1, Part2}

const target_generation_part1 = 25

const target_generation_part2 = 75

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(input) = read_input(input_path)

  let target_generation = case part {
    Part1 -> target_generation_part1
    Part2 -> target_generation_part2
  }

  input
  |> dicts.freq()
  |> functions.evolve(target_generation, next_gen)
  |> dict.values()
  |> int.sum()
  |> int.to_string()
}

fn read_input(input_path: String) -> Result(List(Int), Nil) {
  use line <- result.try(read_single_line(input_path))
  let numbers = string.split(line, " ")
  use numbers <- result.try(list.try_map(numbers, int.parse))
  Ok(numbers)
}

fn next_gen(freq_stones: Dict(Int, Int)) -> Dict(Int, Int) {
  freq_stones
  |> dict.to_list()
  |> list.flat_map(iterate_freq_pair)
  |> list.fold(dict.new(), fn(acc, pair) {
    let #(stone, stone_freq) = pair
    dict.upsert(acc, stone, fn(maybe_freq) {
      option.unwrap(maybe_freq, 0) + stone_freq
    })
  })
}

fn iterate_stone(stone: Int) -> List(Int) {
  case stone, split_stone_in_half(stone) {
    0, _ -> [1]
    _, Ok(#(left, right)) -> [left, right]
    stone, _ -> [stone * 2024]
  }
}

fn split_stone_in_half(stone: Int) -> Result(#(Int, Int), Nil) {
  stone
  |> int.to_string()
  |> strings.split_half()
  |> result.map(fn(pair) {
    let #(left, right) = pair
    let assert Ok(left) = int.parse(left)
    let assert Ok(right) = int.parse(right)
    #(left, right)
  })
}

fn iterate_freq_pair(pair: #(Int, Int)) -> List(#(Int, Int)) {
  let #(stone, freq) = pair

  stone
  |> iterate_stone()
  |> list.map(pair.new(_, freq))
}
