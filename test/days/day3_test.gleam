import shared/printing
import gleam/list
import gleeunit
import gleeunit/should

import days/day3.{
  Disable, Enable, Enabled, Mul, Unconditional, calculate, new_calculator,
  parse_instructions,
}

pub fn main() {
  gleeunit.main()
}

const raw_instructions = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"

const instructions = [
  Mul(2, 4),
  Disable,
  Mul(5, 5),
  Mul(11, 8),
  Enable,
  Mul(8, 5),
]

pub fn parse_instructions_test() {
  raw_instructions
  |> parse_instructions()
  |> should.equal(Ok(instructions))
}

pub fn calculate_test() {
  instructions
  |> list.fold(new_calculator(False), calculate)
  |> should.equal(Unconditional(161))

  instructions
  |> list.fold(new_calculator(True), calculate)
  |> should.equal(Enabled(48))
}
