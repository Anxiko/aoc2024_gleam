import gleam/int
import gleam/list
import gleam/order.{Eq, Gt}
import gleam/result
import gleam/string

import shared/parsers
import shared/results
import shared/types.{type ProblemPart, Part1, Part2}

type UnsolvedEquation =
  #(Int, List(Int))

type Input =
  List(UnsolvedEquation)

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(unsolved_equations) = parse_input(input_path)
  let allow_concat = case part {
    Part1 -> False
    Part2 -> True
  }

  unsolved_equations
  |> list.filter(attempt_solve_equation(_, concat: allow_concat))
  |> list.map(fn(pair) { pair.0 })
  |> int.sum()
  |> int.to_string()
}

fn parse_input(input_path: String) -> Result(Input, Nil) {
  use lines <- result.try(parsers.read_lines(input_path))
  list.try_map(lines, parse_unsolved_equation)
}

fn parse_unsolved_equation(line: String) -> Result(UnsolvedEquation, Nil) {
  use #(total, operands) <- result.try(string.split_once(line, ":"))
  use total <- result.try(int.parse(total))
  let operands = operands |> string.trim_start() |> string.split(" ")
  use operands <- result.map(list.try_map(operands, int.parse))
  #(total, operands)
}

fn attempt_solve_equation(
  unsolved_equation: UnsolvedEquation,
  concat allow_concatenation: Bool,
) -> Bool {
  let #(total, operands) = unsolved_equation
  case operands {
    [] -> panic as "Can't attempt to solve an empty equation"
    [head, ..tail] ->
      do_attempt_solve_equation(total, head, tail, allow_concatenation)
  }
}

fn do_attempt_solve_equation(
  target: Int,
  acc: Int,
  operands: List(Int),
  concat allow_concatenation: Bool,
) -> Bool {
  case int.compare(acc, target), operands {
    Eq, [] -> True
    _, [] -> False
    Gt, _ -> False
    // If we are on target but still have operands left, we can stay on target if all operands left are 1, by multiplying
    // Would also work with addition and 0s, but there are no 0s, at least not on my inputs
    _, [operand, ..operands] -> {
      do_attempt_solve_equation(
        target,
        acc + operand,
        operands,
        allow_concatenation,
      )
      || do_attempt_solve_equation(
        target,
        acc * operand,
        operands,
        allow_concatenation,
      )
      || {
        allow_concatenation
        && do_attempt_solve_equation(
          target,
          concat_op(acc, operand),
          operands,
          allow_concatenation,
        )
      }
    }
  }
}

fn concat_op(left: Int, right: Int) -> Int {
  case left, right {
    maybe_neg_left, maybe_neg_right
      if maybe_neg_left < 0 || maybe_neg_right < 0
    ->
      panic as string.concat([
        "Can't concatenate negative values: ",
        int.to_string(left),
        ", ",
        int.to_string(right),
      ])
    0, right -> right
    left, 0 -> left
    left, right -> {
      [left, right]
      |> list.map(int.to_string)
      |> string.concat
      |> int.parse()
      |> results.assert_unwrap()
    }
  }
}
