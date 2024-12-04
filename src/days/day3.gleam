import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/regexp
import gleam/result
import gleam/string
import simplifile

import shared/types.{type ProblemPart, Part1, Part2}

pub type Instruction {
  Mul(Int, Int)
  Enable
  Disable
}

pub type Calculator {
  Unconditional(value: Int)
  Enabled(value: Int)
  Disabled(value: Int)
}

pub fn new_calculator(conditional: Bool) -> Calculator {
  case conditional {
    True -> Enabled(value: 0)
    False -> Unconditional(value: 0)
  }
}

fn get_value(calculator: Calculator) -> Int {
  calculator.value
}

type Input =
  List(Instruction)

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let calculator =
    case part {
      Part1 -> False
      Part2 -> True
    }
    |> new_calculator()

  read_input(input_path)
  |> list.fold(calculator, with: calculate)
  |> get_value()
  |> int.to_string()
}

pub fn calculate(calculator: Calculator, instruction: Instruction) -> Calculator {
  case instruction, calculator {
    Mul(left, right), Unconditional(value) ->
      Unconditional(left * right + value)
    Mul(left, right), Enabled(value) -> Enabled(left * right + value)
    Enable, Disabled(value) -> Enabled(value)
    Disable, Enabled(value) -> Disabled(value)
    _, _ -> calculator
  }
}

fn read_input(input_path: String) -> Input {
  let assert Ok(file_contents) = simplifile.read(input_path)

  let assert Ok(instructions) = parse_instructions(file_contents)

  instructions
}

fn instruction_pattern() {
  let assert Ok(re) =
    regexp.from_string(
      "(mul)\\((\\d{1,3}),(\\d{1,3})\\)|(do)\\(\\)|(don't)\\(\\)",
    )
  re
}

pub fn parse_instructions(line: String) -> Result(List(Instruction), Nil) {
  let re = instruction_pattern()

  re
  |> regexp.scan(line)
  |> list.try_map(instruction_from_match)
}

fn instruction_from_match(match: regexp.Match) -> Result(Instruction, Nil) {
  case match {
    regexp.Match(submatches: [Some("mul"), Some(left), Some(right)], ..) -> {
      use parsed_left <- result.try(int.parse(left))
      use parsed_right <- result.try(int.parse(right))
      Ok(Mul(parsed_left, parsed_right))
    }
    regexp.Match(submatches: [None, None, None, Some("do")], ..) -> {
      Ok(Enable)
    }

    regexp.Match(submatches: [None, None, None, None, Some("don't")], ..) -> {
      Ok(Disable)
    }
    unmatched -> {
      unmatched |> string.inspect() |> io.println_error()
      Error(Nil)
    }
  }
}
