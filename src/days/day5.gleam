import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option
import gleam/order.{type Order, Eq, Gt, Lt}
import gleam/result
import gleam/set.{type Set}
import gleam/string

import shared/lists.{is_ordered, middle}
import shared/parsers
import shared/printing.{inspect}
import shared/types.{type ProblemPart, Part1, Part2}

type Input {
  SafetyBook(rules: List(Rule), updates: List(Update))
}

type Rule =
  #(Int, Int)

type RuleDict =
  Dict(Int, Set(Int))

type Update =
  List(Int)

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(input) = read_input(input_path)
  let rule_dict = build_rule_dict(input.rules)

  let #(correct, incorrect) =
    input.updates
    |> list.partition(fn(update) {
      is_ordered(update, fn(l, r) { compare_by_ruledict(l, r, rule_dict) })
    })

  let selected_updates = case part {
    Part1 -> correct
    Part2 -> {
      incorrect
      |> list.map(list.sort(_, fn(l, r) { compare_by_ruledict(l, r, rule_dict) }))
    }
  }

  let assert Ok(sum) =
    selected_updates
    |> list.try_map(middle(_))
    |> result.map(int.sum(_))

  int.to_string(sum)
}

fn build_rule_dict(rules: List(Rule)) -> RuleDict {
  rules
  |> list.fold(dict.new(), fn(acc, rule) {
    let #(lesser, greater) = rule
    dict.upsert(acc, lesser, fn(maybe_existing) {
      maybe_existing
      |> option.unwrap(set.new())
      |> set.insert(greater)
    })
  })
}

fn compare_by_ruledict(left: Int, right: Int, rule_dict: RuleDict) -> Order {
  case left == right {
    True -> Eq
    False -> {
      case
        less_then_by_ruledict(left, right, rule_dict),
        less_then_by_ruledict(right, left, rule_dict)
      {
        True, False -> Lt
        False, True -> Gt
        False, False -> Eq
        True, True ->
          panic as string.concat([
            "Both elements are greater than eachother: ",
            int.to_string(left),
            ", ",
            int.to_string(right),
            "\nFollowing the rule_dict:\n",
            rule_dict_to_string(rule_dict),
          ])
      }
    }
  }
}

fn less_then_by_ruledict(left: Int, right: Int, rule_dict: RuleDict) -> Bool {
  rule_dict
  |> dict.get(left)
  |> result.map(fn(greater_than_left) { set.contains(greater_than_left, right) })
  |> result.unwrap(False)
}

fn rule_dict_to_string(rule_dict: RuleDict) -> String {
  rule_dict
  |> dict.to_list()
  |> list.map(fn(pair) {
    let #(key, values) = pair
    let joined_values =
      values
      |> set.to_list()
      |> list.map(int.to_string)
      |> string.join(", ")

    string.concat([int.to_string(key), " => ", joined_values])
  })
  |> string.join("\n")
}

fn read_input(input_path: String) -> Result(Input, Nil) {
  let assert Ok([rules, updates, ..]) = parsers.read_line_chunks(input_path)

  use rules <- result.try(list.try_map(rules, parse_rule(_)))
  use updates <- result.map(list.try_map(updates, parse_update(_)))
  SafetyBook(rules:, updates:)
}

fn parse_rule(rule: String) -> Result(Rule, Nil) {
  case string.split(rule, "|") {
    [left, right] -> {
      use left <- result.try(int.parse(left))
      use right <- result.map(int.parse(right))
      #(left, right)
    }
    _ -> Error(Nil)
  }
}

fn parse_update(update: String) -> Result(Update, Nil) {
  update
  |> string.split(",")
  |> list.try_map(int.parse(_))
}
