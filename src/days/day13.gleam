import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/regexp.{type Regexp, Match}
import gleam/result

import shared/coords.{type Coord}
import shared/functions
import shared/integers
import shared/parsers
import shared/results
import shared/types.{type ProblemPart, Part1, Part2}

type ClawMachine {
  ClawMachine(button_a: Coord, button_b: Coord, prize: Coord)
}

const max_presses = 100

const extra_distance = 10_000_000_000_000

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(claw_machines) = read_input(input_path)

  let #(_limit, extra) = case part {
    Part1 -> #(Some(max_presses), #(0, 0))
    Part2 -> #(None, #(extra_distance, extra_distance))
  }

  claw_machines
  |> list.map(fn(claw_machine) {
    ClawMachine(
      ..claw_machine,
      prize: coords.add_coords(claw_machine.prize, extra),
    )
  })
  |> list.filter_map(calculate_presses)
  |> list.map(tokens_for_presses)
  |> int.sum()
  |> int.to_string()
}

fn read_input(input_path: String) -> Result(List(ClawMachine), Nil) {
  use claw_machines <- result.try(parsers.read_line_chunks(input_path))
  use claw_machines <- result.try(list.try_map(
    claw_machines,
    parse_claw_machine,
  ))
  Ok(claw_machines)
}

fn parse_claw_machine(claw_machine: List(String)) -> Result(ClawMachine, Nil) {
  let split_lines = case claw_machine {
    [button_a, button_b, prize] -> Ok(#(button_a, button_b, prize))
    _ -> Error(Nil)
  }

  use #(button_a, button_b, prize) <- result.try(split_lines)
  use button_a <- result.try(parse_button(button_a))
  use button_a <- result.try(check_parsed_button(button_a, "A"))
  use button_b <- result.try(parse_button(button_b))
  use button_b <- result.try(check_parsed_button(button_b, "B"))
  use prize <- result.try(parse_prize(prize))
  Ok(ClawMachine(button_a:, button_b:, prize:))
}

fn check_parsed_button(
  parsed: #(String, Coord),
  expected: String,
) -> Result(Coord, Nil) {
  case parsed {
    #(button, coord) if button == expected -> Ok(coord)
    _ -> Error(Nil)
  }
}

fn parse_button(button: String) -> Result(#(String, Coord), Nil) {
  let matches =
    button_pattern()
    |> regexp.scan(button)

  let captures = case matches {
    [Match(submatches: [Some(button), Some(x), Some(y)], ..)] ->
      Ok(#(button, x, y))
    _ -> Error(Nil)
  }

  use #(button, raw_x, raw_y) <- result.try(captures)
  use coord <- result.try(coords.parse(raw_x, raw_y))
  Ok(#(button, coord))
}

fn parse_prize(prize: String) -> Result(Coord, Nil) {
  let matches =
    prize_pattern()
    |> regexp.scan(prize)

  let captures = case matches {
    [Match(submatches: [Some(x), Some(y)], ..)] -> Ok(#(x, y))
    _ -> Error(Nil)
  }

  result.try(captures, functions.apply_pair(coords.parse, _))
}

fn button_pattern() -> Regexp {
  "^Button (A|B): X\\+(\\d+), Y\\+(\\d+)$"
  |> regexp.from_string()
  |> results.expect("Compile button pattern")
}

fn prize_pattern() -> Regexp {
  "^Prize: X=(\\d+), Y=(\\d+)$"
  |> regexp.from_string()
  |> results.expect("Compile prize pattern")
}

fn calculate_presses(claw_machine: ClawMachine) -> Result(#(Int, Int), Nil) {
  let #(ax, ay) = claw_machine.button_a
  let #(bx, by) = claw_machine.button_b
  let #(px, py) = claw_machine.prize
  use b_presses <- result.try(integers.int_div(
    ax * py - ay * px,
    by * ax - bx * ay,
  ))
  use a_presses <- result.try(integers.int_div(px - b_presses * bx, ax))
  Ok(#(a_presses, b_presses))
}

fn tokens_for_presses(presses: #(Int, Int)) -> Int {
  let #(a, b) = presses
  a * 3 + b
}
