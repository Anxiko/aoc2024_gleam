import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string

import shared/parsers
import shared/strings
import shared/types.{type ProblemPart, Part1, Part2}

type Input {
  Input(available: List(String), desired: List(String))
}

type Cache =
  Dict(String, Int)

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(input) = read_input(input_path)
  case part {
    Part1 -> {
      input.desired
      |> list.count(pattern_is_possible(_, input.available))
      |> int.to_string()
    }
    Part2 -> {
      input.desired
      |> list.map_fold(dict.new(), fn(cache, desired) {
        count_possible_combinations(desired, input.available, cache)
        |> pair.swap()
      })
      |> pair.second()
      |> int.sum()
      |> int.to_string
    }
  }
}

fn read_input(input_path: String) -> Result(Input, Nil) {
  use chunks <- result.try(parsers.read_line_chunks(input_path))
  let split_chunks = case chunks {
    [[available], desired] -> Ok(#(available, desired))
    _ -> Error(Nil)
  }
  use #(available, desired) <- result.try(split_chunks)
  let available = string.split(available, ", ")

  Input(available:, desired:) |> Ok()
}

fn pattern_is_possible(desired: String, available: List(String)) -> Bool {
  case desired {
    "" -> True
    desired -> {
      available
      |> list.any(fn(pattern) {
        case strings.try_remove_prefix(desired, pattern) {
          Ok(desired) -> pattern_is_possible(desired, available)
          _ -> False
        }
      })
    }
  }
}

fn count_possible_combinations(
  desired: String,
  available: List(String),
  cache: Cache,
) -> #(Int, Cache) {
  case desired {
    "" -> #(1, cache)
    desired -> {
      case dict.get(cache, desired) {
        Ok(result) -> #(result, cache)
        Error(Nil) -> {
          let #(cache, partials) =
            available
            |> list.map_fold(cache, fn(cache, pattern) {
              case strings.try_remove_prefix(desired, pattern) {
                Ok(desired) ->
                  count_possible_combinations(desired, available, cache)
                _ -> #(0, cache)
              }
              |> pair.swap()
            })

          let total = int.sum(partials)
          let cache = dict.insert(cache, desired, total)

          #(total, cache)
        }
      }
    }
  }
}
