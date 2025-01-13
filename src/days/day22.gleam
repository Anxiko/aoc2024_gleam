import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set
import gleam/yielder

import shared/functions
import shared/lists
import shared/parsers
import shared/printing
import shared/results
import shared/types.{type ProblemPart, Part1, Part2}

const pruning_value = 16_777_216

const total_generated_secrets = 2000

const negotiator_code_length = 4

type MonkeyPrice {
  MonkeyPrice(price: Int, delta: Int)
}

type Code =
  List(Int)

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(seeds) = read_input(input_path, part)
  printing.inspect(seeds, label: "Seeds")

  case part {
    Part1 -> {
      seeds
      |> list.map(functions.evolve(_, total_generated_secrets, next_secret))
      |> int.sum()
      |> int.to_string()
    }
    Part2 -> {
      let monkey_price_sequences_list: List(List(MonkeyPrice)) =
        seeds
        |> list.map(fn(seed) {
          seed
          |> yielder.iterate(next_secret)
          |> yielder.map(least_sig_digit)
          |> yielder.take(total_generated_secrets + 1)
          |> yielder.to_list()
          |> list.window_by_2()
          |> list.map(fn(pair) {
            let #(previous, current) = pair
            MonkeyPrice(price: current, delta: current - previous)
          })
        })

      let mapped_code_price_list: List(Dict(Code, Int)) =
        monkey_price_sequences_list
        |> lists.map_async(mapped_code_prices, timeout: 10_000)

      let all_codes =
        mapped_code_price_list
        |> list.map(dict.keys)
        |> list.map(set.from_list)
        |> list.reduce(set.union)
        |> result.map(set.to_list)
        |> results.expect("All codes")

      let mapped_earnings =
        all_codes
        |> list.map(fn(code) {
          let total_earnings =
            mapped_code_price_list
            |> list.map(fn(mapping) {
              mapping
              |> dict.get(code)
              |> result.unwrap(0)
            })
            |> int.sum()

          #(code, total_earnings)
        })

      let #(_best_code, max_earnings) =
        mapped_earnings
        |> lists.max(fn(left_pair, right_pair) {
          int.compare(left_pair.1, right_pair.1)
        })
        |> results.expect("Find best code")

      int.to_string(max_earnings)
    }
  }
}

fn read_input(input_path: String, part: ProblemPart) -> Result(List(Int), Nil) {
  use chunks <- result.try(parsers.read_line_chunks(input_path))
  let maybe_selected_chunk = case chunks, part {
    [single], _ -> Ok(single)
    [part1, _part2], Part1 -> Ok(part1)
    [_part1, part2], Part2 -> Ok(part2)
    _, _ -> Error(Nil)
  }
  use lines <- result.try(maybe_selected_chunk)
  use values <- result.try(list.try_map(lines, int.parse))
  Ok(values)
}

fn next_secret(secret: Int) -> Int {
  secret
  |> step(int.multiply(_, 64))
  |> step(divide(_, 32))
  |> step(int.multiply(_, 2048))
}

fn mix(secret secret: Int, value value: Int) -> Int {
  int.bitwise_exclusive_or(secret, value)
}

fn prune(secret secret: Int) -> Int {
  secret
  |> int.modulo(pruning_value)
  |> results.expect("Prune secret")
}

fn step(secret: Int, f calc_ingredient: fn(Int) -> Int) -> Int {
  secret
  |> mix(calc_ingredient(secret))
  |> prune()
}

fn divide(secret: Int, value: Int) -> Int {
  secret
  |> int.divide(value)
  |> results.expect("Divide the secret by " <> int.to_string(value))
}

fn least_sig_digit(n: Int) -> Int {
  n % 10
}

fn register_valid_codes(
  mapping: Dict(Code, Int),
  complete: Code,
  value: Int,
) -> Dict(Code, Int) {
  complete
  |> list.reverse()
  |> list.take(negotiator_code_length)
  |> list.reverse()
  |> results.check(fn(maybe_code) {
    list.length(maybe_code) == negotiator_code_length
  })
  |> results.guard(fn(code) { !dict.has_key(mapping, code) })
  |> result.map(dict.insert(mapping, _, value))
  |> result.unwrap(mapping)
}

fn mapped_code_prices(monkey_prices: List(MonkeyPrice)) -> Dict(Code, Int) {
  monkey_prices
  |> list.fold(#([], dict.new()), fn(state, monkey_price) {
    let #(prefix, mapping) = state
    let code = list.append(prefix, [monkey_price.delta])
    let mapping = register_valid_codes(mapping, code, monkey_price.price)
    #(code, mapping)
  })
  |> pair.second
}
