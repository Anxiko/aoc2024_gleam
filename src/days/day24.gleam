import gleam/bool
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/pair
import gleam/regexp.{type Regexp, Match}
import gleam/result
import gleam/set.{type Set}
import gleam/string
import gleam/yielder
import shared/yielders

import shared/lists
import shared/pairs
import shared/parsers
import shared/results
import shared/sets
import shared/types.{type ProblemPart, Part1, Part2}

type Wire {
  Digit(id: String, offset: Int)
  Intermediate(String)
}

type Operation {
  And
  Or
  Xor
}

type GateId =
  Int

type Gate {
  Gate(id: GateId, op: Operation, inputs: #(Wire, Wire), output: Wire)
}

type Input {
  Input(initial_wires: Dict(Wire, Bool), gates: List(Gate), width: Int)
}

pub fn solve(part: ProblemPart, example: Bool, input_path: String) -> String {
  let assert Ok(input) = read_input(input_path)

  let gates =
    computation_order(
      input.gates,
      dict.keys(input.initial_wires) |> set.from_list(),
    )
    |> results.expect("Computation order")
  case part {
    Part1 -> {
      input.initial_wires
      |> compute_all(gates)
      |> read_number("z")
      |> results.guard(fn(digits) {
        example || list.length(digits) == input.width + 1
      })
      |> results.expect("Binary digits in order")
      |> list.reverse()
      |> list.map(bool.to_int)
      |> int.undigits(2)
      |> results.expect("Assemble solution from binary digits")
      |> int.to_string()
    }
    Part2 -> {
      gates
      |> fix_circuit(input.width)
      |> list.flat_map(pairs.to_list)
      |> list.map(wire_to_string)
      |> list.sort(string.compare)
      |> string.join(",")
    }
  }
}

fn compute_all(values: Dict(Wire, Bool), gates: List(Gate)) -> Dict(Wire, Bool) {
  gates
  |> list.fold(values, compute)
}

fn compute(values: Dict(Wire, Bool), gate: Gate) -> Dict(Wire, Bool) {
  let input_values =
    gate.inputs
    |> pairs.map_both(fn(wire) {
      values
      |> dict.get(wire)
      |> results.expect("Read wire input " <> wire_to_string(wire))
    })

  let result = operation(gate.op, input_values)

  dict.insert(values, gate.output, result)
}

fn parse_wire(wire: String) -> Wire {
  wire
  |> parse_digit_wire()
  |> result.replace_error(Intermediate(wire))
  |> result.unwrap_both()
}

fn parse_digit_wire(wire: String) -> Result(Wire, Nil) {
  let pattern =
    "^([a-z])(\\d+)$"
    |> regexp.from_string()
    |> results.expect("Compile wire pattern")

  let matches = regexp.scan(pattern, wire)

  let maybe_split_wire = case matches {
    [Match(submatches: [Some(id), Some(number)], ..)] -> Ok(#(id, number))
    _ -> Error(Nil)
  }

  use #(id, number) <- result.try(maybe_split_wire)
  use number <- result.try(int.parse(number))

  Digit(id:, offset: number) |> Ok()
}

fn operation(op: Operation, inputs: #(Bool, Bool)) -> Bool {
  let #(left, right) = inputs
  case op {
    And -> left && right
    Or -> left || right
    Xor -> bool.exclusive_or(left, right)
  }
}

fn read_input(input_path: String) -> Result(Input, Nil) {
  use chunks <- result.try(parsers.read_line_chunks(input_path))
  let input_pair = case chunks {
    [initial_wires, gates] -> Ok(#(initial_wires, gates))
    _ -> Error(Nil)
  }

  use #(initial_wires, gates) <- result.try(input_pair)
  use initial_wires <- result.try(list.try_map(
    initial_wires,
    parse_initial_wire,
  ))
  let initial_wires = dict.from_list(initial_wires)
  let gates = lists.with_index(gates)
  use gates <- result.try(
    list.try_map(gates, fn(pair) { parse_gate(pair.1, pair.0) }),
  )

  use first_input <- result.try(read_number(initial_wires, "x"))
  use second_input <- result.try(read_number(initial_wires, "y"))

  let maybe_width = case list.length(first_input), list.length(second_input) {
    x_length, y_length if x_length == y_length -> Ok(x_length)
    _, _ -> Error(Nil)
  }

  use width <- result.try(maybe_width)

  Ok(Input(initial_wires:, gates:, width:))
}

fn parse_initial_wire(initial_wire: String) -> Result(#(Wire, Bool), Nil) {
  use #(wire, value) <- result.try(string.split_once(initial_wire, ": "))

  let maybe_value = case value {
    "0" -> Ok(False)
    "1" -> Ok(True)
    _ -> Error(Nil)
  }

  use value <- result.try(maybe_value)

  let wire = parse_wire(wire)

  Ok(#(wire, value))
}

fn gate_pattern() -> Regexp {
  "^([a-z0-9]+) (AND|XOR|OR) ([a-z0-9]+) -> ([a-z0-9]+)$"
  |> regexp.from_string()
  |> results.expect("Compile gate pattern")
}

fn parse_gate(gate: String, id: Int) -> Result(Gate, Nil) {
  let scan_results =
    gate_pattern()
    |> regexp.scan(gate)

  let maybe_gate = case scan_results {
    [Match(submatches: [Some(left), Some(op), Some(right), Some(output)], ..)] -> {
      #(left, right, op, output) |> Ok()
    }
    _ -> Error(Nil)
  }

  use #(left, right, op, output) <- result.try(maybe_gate)

  let op = case op {
    "AND" -> And
    "XOR" -> Xor
    "OR" -> Or
    invalid -> panic as { "Invalid operation: " <> invalid }
  }

  let inputs =
    #(left, right)
    |> pairs.map_both(parse_wire)

  let output = parse_wire(output)

  Ok(Gate(id:, op:, inputs:, output:))
}

fn computation_order(
  gates: List(Gate),
  available: Set(Wire),
) -> Result(List(Gate), Nil) {
  do_computation_order(available, gates, [])
}

fn do_computation_order(
  available: Set(Wire),
  remaining: List(Gate),
  acc: List(Gate),
) -> Result(List(Gate), Nil) {
  case list.is_empty(remaining) {
    True -> acc |> list.reverse() |> Ok()
    False -> {
      remaining
      |> lists.find_delete(fn(gate) {
        set.is_subset(gate_inputs(gate), available)
      })
      |> result.try(fn(pair) {
        let #(next_gate, remaining) = pair
        do_computation_order(
          set.union(available, gate_outputs(next_gate)),
          remaining,
          [next_gate, ..acc],
        )
      })
    }
  }
}

fn gate_inputs(gate: Gate) -> Set(Wire) {
  let #(left, right) = gate.inputs
  set.from_list([left, right])
}

fn gate_outputs(gate: Gate) -> Set(Wire) {
  sets.single(gate.output)
}

fn is_contiguous_count(numbers: List(Int)) -> Bool {
  let size = list.length(numbers)

  list.range(from: 0, to: size - 1) == numbers
}

fn read_number(
  values: Dict(Wire, Bool),
  number_id: String,
) -> Result(List(Bool), Nil) {
  let indexed_digits =
    values
    |> dict.to_list()
    |> list.filter_map(fn(entry) {
      case entry {
        #(Digit(id:, offset:), value) if id == number_id -> {
          Ok(#(offset, value))
        }
        _ -> Error(Nil)
      }
    })
    |> lists.sort_by(by: pair.first, with: int.compare)

  let is_contiguous =
    indexed_digits
    |> list.map(pair.first)
    |> is_contiguous_count()

  case is_contiguous {
    True ->
      indexed_digits
      |> list.map(pair.second)
      |> Ok()

    False -> Error(Nil)
  }
}

fn trace_output(
  output: Wire,
  mapped_gates: Dict(Wire, Gate),
) -> #(List(Gate), List(Wire)) {
  do_trace_output([output], mapped_gates, [], [])
}

fn do_trace_output(
  active: List(Wire),
  mapped_gates: Dict(Wire, Gate),
  gates: List(Gate),
  input_wires: List(Wire),
) -> #(List(Gate), List(Wire)) {
  case active {
    [] -> #(list.reverse(gates), input_wires)
    [output, ..active] -> {
      let maybe_gate =
        mapped_gates
        |> dict.get(output)

      case maybe_gate {
        Ok(gate) -> {
          let active =
            list.append(active, gate |> gate_inputs() |> set.to_list())
          do_trace_output(active, mapped_gates, [gate, ..gates], input_wires)
        }
        Error(Nil) ->
          case output {
            Digit(id: id, ..) as input if id == "x" || id == "y" ->
              do_trace_output(active, mapped_gates, gates, [
                input,
                ..input_wires
              ])
            _ ->
              panic as {
                "Wire "
                <> string.inspect(output)
                <> " is not an input nor an output "
              }
          }
      }
    }
  }
}

fn fix_circuit(gates: List(Gate), width: Int) -> List(#(Wire, Wire)) {
  do_fix_circuit(gates, width, set.new(), 0, [])
}

fn do_fix_circuit(
  gates: List(Gate),
  width: Int,
  validated_gate_ids: Set(GateId),
  current_output: Int,
  acc: List(#(Wire, Wire)),
) -> List(#(Wire, Wire)) {
  case current_output > width {
    True -> acc
    False -> {
      let output_wire = Digit(id: "z", offset: current_output)
      let output_to_gate_mapping =
        gates
        |> list.map(fn(gate) { #(gate.output, gate) })
        |> dict.from_list()

      let #(output_gates, _inputs) =
        trace_output(output_wire, output_to_gate_mapping)

      let invalidated_gates =
        gates
        |> list.filter(fn(gate) { !set.contains(validated_gate_ids, gate.id) })

      let output_invalidated_gates =
        output_gates
        |> list.filter(fn(gate) { !set.contains(validated_gate_ids, gate.id) })

      let validated_gate_ids =
        output_gates
        |> list.map(fn(gate) { gate.id })
        |> set.from_list()

      let #(gates, acc) = case validate_output(gates, current_output, width) {
        True -> #(gates, acc)
        False -> {
          let #(gates, swap) =
            yielders.product(
              yielder.from_list(output_invalidated_gates),
              yielder.from_list(invalidated_gates),
            )
            |> yielder.filter(fn(pair) { { pair.0 }.id != { pair.1 }.id })
            |> yielder.map(fn(pair) {
              let #(left, right) = pair
              swap_outputs(gates, left.id, right.id)
            })
            |> yielder.find(fn(pair) {
              let #(gates, _swap) = pair
              validate_output(gates, current_output, width)
            })
            |> results.expect(
              "Find a swap that passes validation for output "
              <> int.to_string(current_output),
            )
          #(gates, [swap, ..acc])
        }
      }

      do_fix_circuit(gates, width, validated_gate_ids, current_output + 1, acc)
    }
  }
}

fn swap_outputs(
  gates: List(Gate),
  left_id: GateId,
  right_id: GateId,
) -> #(List(Gate), #(Wire, Wire)) {
  let #(left, gates) =
    lists.find_delete(gates, fn(gate) { gate.id == left_id })
    |> results.expect("Find left gate")
  let #(right, gates) =
    lists.find_delete(gates, fn(gate) { gate.id == right_id })
    |> results.expect("Find left gate")

  let updated_left = Gate(..left, output: right.output)
  let updated_right = Gate(..right, output: left.output)

  let gates = [updated_left, updated_right, ..gates]
  #(gates, #(left.output, right.output))
}

fn validate_output(gates: List(Gate), output: Int, width: Int) -> Bool {
  let input_set =
    ["x", "y"]
    |> list.flat_map(fn(id) {
      list.range(from: 0, to: width - 1)
      |> list.map(Digit(id:, offset: _))
    })
    |> set.from_list()

  let output_wire = Digit(id: "z", offset: output)

  computation_order(gates, input_set)
  |> result.map(fn(gates) {
    let inputs_for_invalidated = inputs_for_invalidated(output, width)
    let validation_inputs = inputs_for_validation(output, width)

    lists.product(validation_inputs, inputs_for_invalidated)
    |> list.map(fn(pair) {
      let #(#(validation_input, expected), outside_validation_input) = pair
      #(dict.merge(validation_input, outside_validation_input), expected)
    })
    |> list.all(fn(pair) {
      let #(input, expected) = pair

      let results = compute_all(input, gates)

      let actual =
        results
        |> dict.get(output_wire)
        |> results.expect("Output wire in computation")

      actual == expected
    })
  })
  |> result.unwrap(False)
}

fn inputs_for_validation(
  current_output: Int,
  width: Int,
) -> List(#(Dict(Wire, Bool), Bool)) {
  let before =
    lists.positive_range(from: 0, to: current_output - 2)
    |> list.flat_map(fn(offset) {
      ["x", "y"]
      |> list.map(fn(id) { Digit(id:, offset:) })
    })
    |> list.map(fn(wire) { #(wire, False) })
    |> dict.from_list()

  let carry = case current_output > 0 {
    True -> {
      [False, True]
      |> list.map(fn(carry) {
        let dict =
          ["x", "y"]
          |> list.map(fn(id) { Digit(id:, offset: current_output - 1) })
          |> list.map(fn(wire) { #(wire, carry) })
          |> dict.from_list()

        #(dict, carry)
      })
    }
    False -> []
  }

  let direct_inputs = case current_output == width {
    True -> []
    False -> {
      ["x", "y"]
      |> list.map(fn(id) {
        [False, True]
        |> list.map(fn(value) {
          #(
            dict.from_list([#(Digit(id:, offset: current_output), value)]),
            value,
          )
        })
      })
    }
  }

  [carry, ..direct_inputs]
  |> list.reduce(fn(left, right) {
    lists.product(left, right)
    |> list.map(fn(pair) {
      let #(#(left_inputs, left_value), #(right_inputs, right_value)) = pair
      #(
        dict.merge(left_inputs, right_inputs),
        bool.exclusive_or(left_value, right_value),
      )
    })
  })
  |> results.assert_unwrap()
  |> list.map(pair.map_first(_, fn(inputs) { dict.merge(before, inputs) }))
}

fn inputs_for_invalidated(
  current_output: Int,
  width: Int,
) -> List(Dict(Wire, Bool)) {
  let from = current_output + 1
  let to = width - 1

  list.flatten([
    // All zero/one
    [False, True]
      |> list.map(fn(value) {
        ["x", "y"]
        |> list.map(sequence(_, from, to, value, fn(state) { #(state, state) }))
        |> list.reduce(dict.merge)
        |> results.assert_unwrap()
      }),
    // All the same, but opposite
    [False, True]
      |> list.map(fn(value) {
        [#("x", value), #("y", !value)]
        |> list.map(fn(pair) {
          let #(id, value) = pair
          sequence(id, from, to, value, fn(state) { #(state, state) })
        })
        |> list.reduce(dict.merge)
        |> results.assert_unwrap()
      }),
    // Alternating in sync
    [False, True]
      |> list.map(fn(value) {
        ["x", "y"]
        |> list.map(sequence(_, from, to, value, fn(state) { #(!state, state) }))
        |> list.reduce(dict.merge)
        |> results.assert_unwrap()
      }),
    // Alternating out of sync
    [False, True]
      |> list.map(fn(value) {
        [#("x", value), #("y", !value)]
        |> list.map(fn(pair) {
          let #(id, value) = pair
          sequence(id, from, to, value, fn(state) { #(!state, state) })
        })
        |> list.reduce(dict.merge)
        |> results.assert_unwrap()
      }),
  ])
}

fn sequence(
  id: String,
  from: Int,
  to: Int,
  state: state,
  generator: fn(state) -> #(state, Bool),
) -> Dict(Wire, Bool) {
  let total = to - from + 1

  yielder.unfold(state, fn(state) {
    let #(state, element) = generator(state)
    yielder.Next(element:, accumulator: state)
  })
  |> yielder.index()
  |> yielder.map(fn(pair) {
    let #(value, index) = pair
    #(Digit(id:, offset: index + from), value)
  })
  |> yielder.take(total)
  |> yielder.to_list()
  |> dict.from_list()
}

fn wire_to_string(wire: Wire) -> String {
  case wire {
    Intermediate(wire) -> wire
    Digit(id:, offset:) -> {
      id <> { offset |> int.to_string() |> string.pad_start(with: "0", to: 2) }
    }
  }
}
