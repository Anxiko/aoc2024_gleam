import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Some}
import gleam/regexp.{type Match, Match}
import gleam/result
import gleam/string
import gleam/yielder

import shared/functions
import shared/integers
import shared/pairs
import shared/parsers
import shared/printing
import shared/results
import shared/types.{type ProblemPart, Part1, Part2}

type Register {
  A
  B
  C
  Pc
}

type Value {
  Just(Int)
  Read(Register)
}

type OperandType {
  Literal
  Combo
}

type Instruction {
  Div(dst: Register)
  Xor(use_operand: Bool)
  Mod
  JumpNotZero
  Out
}

type Cpu {
  Cpu(registers: Dict(Register, Int), out: List(Int))
}

type Memory =
  List(Int)

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(#(cpu, memory)) = read_input(input_path)

  memory
  |> interpret_program()
  |> list.map(fn(pair) {
    string.concat([string.inspect(pair.0), " ", string.inspect(pair.1)])
  })
  |> list.each(io.println)

  case part {
    Part1 -> {
      cpu
      |> run_program(memory)
      |> list.map(int.to_string)
      |> string.join(",")
    }
    Part2 -> {
      let register_a =
        find_register_a(write_reg(cpu, A, 0), memory, list.reverse(memory))
        |> results.expect("Find a solution")

      let cpu = write_reg(cpu, A, register_a)
      let actual = run_program(cpu, memory)

      printing.inspect(actual, label: "Actual")

      int.to_string(register_a)
    }
  }
}

fn read_input(input_path: String) -> Result(#(Cpu, Memory), Nil) {
  let input = case parsers.read_line_chunks(input_path) {
    Ok([[register_a, register_b, register_c], [program]]) ->
      Ok(#(#(register_a, register_b, register_c), program))
    _ -> Error(Nil)
  }
  use #(#(register_a, register_b, register_c), program) <- result.try(input)
  use register_a <- result.try(read_register(register_a))
  use register_a <- result.try(
    results.check(register_a, fn(pair) { pair.0 == "A" }),
  )
  use register_b <- result.try(read_register(register_b))
  use register_b <- result.try(
    results.check(register_b, fn(pair) { pair.0 == "B" }),
  )
  use register_c <- result.try(read_register(register_c))
  use register_c <- result.try(
    results.check(register_c, fn(pair) { pair.0 == "C" }),
  )
  use program <- result.try(read_program(program))

  Ok(#(new_cpu(register_a.1, register_b.1, register_c.1), program))
}

fn read_register(register: String) -> Result(#(String, Int), Nil) {
  let matches =
    "^Register (A|B|C): (\\d+)$"
    |> regexp.from_string()
    |> results.expect("Compile register pattern")
    |> regexp.scan(register)

  let maybe_register = case matches {
    [Match(submatches: [Some(name), Some(value)], ..)] -> Ok(#(name, value))
    _ -> Error(Nil)
  }

  use #(name, value) <- result.try(maybe_register)
  use value <- result.try(int.parse(value))

  Ok(#(name, value))
}

fn read_program(program: String) -> Result(Memory, Nil) {
  let program =
    "^Program: ((?:\\d,)*\\d)$"
    |> regexp.from_string()
    |> results.expect("Compile program pattern")
    |> regexp.scan(program)

  let maybe_program = case program {
    [Match(submatches: [Some(program)], ..)] -> Ok(program)
    _ -> Error(Nil)
  }

  use program <- result.try(maybe_program)
  program
  |> string.split(",")
  |> list.try_map(int.parse)
}

fn new_cpu(register_a: Int, register_b: Int, register_c: Int) -> Cpu {
  Cpu(registers: dict.new(), out: [])
  |> write_reg(A, register_a)
  |> write_reg(B, register_b)
  |> write_reg(C, register_c)
  |> write_reg(Pc, 0)
}

fn decode_operand(int: Int, operand_type: OperandType) -> Value {
  case int, operand_type {
    literal, Literal if 0 <= literal && literal < 8 -> Just(literal)
    literal, Combo if 0 <= literal && literal < 4 -> Just(literal)
    4, Combo -> Read(A)
    5, Combo -> Read(B)
    6, Combo -> Read(C)
    7, Combo -> panic as "Explicitly prohibited operand"
    invalid, _ ->
      panic as { "Invalid value for operand" <> int.to_string(invalid) }
  }
}

fn read_operand(value: Value, cpu: Cpu) -> Int {
  case value {
    Just(value) -> value
    Read(register) -> read_reg(cpu, register)
  }
}

fn decode_instruction(opcode: Int) -> Instruction {
  case opcode {
    0 -> Div(A)
    1 -> Xor(use_operand: True)
    2 -> Mod
    3 -> JumpNotZero
    4 -> Xor(use_operand: False)
    5 -> Out
    6 -> Div(B)
    7 -> Div(C)
    invalid -> panic as { "Invalid opcode " <> int.to_string(invalid) }
  }
}

fn operand_type_for_instruction(instruction: Instruction) -> OperandType {
  case instruction {
    Div(..) -> Combo
    Xor(..) -> Literal
    Out -> Combo
    Mod -> Combo
    JumpNotZero -> Literal
  }
}

fn read_reg(cpu: Cpu, reg: Register) -> Int {
  cpu.registers
  |> dict.get(reg)
  |> results.expect("Read register " <> string.inspect(reg))
}

fn write_reg(cpu: Cpu, reg: Register, value: Int) -> Cpu {
  let registers =
    cpu.registers
    |> dict.insert(reg, value)

  Cpu(..cpu, registers:)
}

fn write_out(cpu: Cpu, output: Int) -> Cpu {
  let out = [output, ..cpu.out]
  Cpu(..cpu, out:)
}

fn op_div(cpu: Cpu, operand: Int, dst: Register) -> Cpu {
  let operand =
    operand
    |> decode_operand(Combo)
    |> read_operand(cpu)

  let dividend = read_reg(cpu, A)
  let divisor = integers.power(2, exp: operand)

  let #(result, _mod) =
    integers.div_mod(dividend, divisor) |> results.expect("Op div")

  cpu
  |> write_reg(dst, result)
}

fn op_xor(cpu: Cpu, operand: Int, use_operand: Bool) -> Cpu {
  let lhs = read_reg(cpu, B)
  let rhs = case use_operand {
    True ->
      operand
      |> decode_operand(Literal)
      |> read_operand(cpu)

    False -> read_reg(cpu, C)
  }

  let result = int.bitwise_exclusive_or(lhs, rhs)

  cpu
  |> write_reg(B, result)
}

fn op_out(cpu: Cpu, operand: Int) -> Cpu {
  let operand =
    operand
    |> decode_operand(Combo)
    |> read_operand(cpu)

  let #(_div, mod) =
    integers.div_mod(operand, 8) |> results.expect("Modulo on out op")

  write_out(cpu, mod)
}

fn op_mod(cpu: Cpu, operand: Int) -> Cpu {
  let operand =
    operand
    |> decode_operand(Combo)
    |> read_operand(cpu)

  let #(_div, mod) = integers.div_mod(operand, 8) |> results.expect("Modulo op")

  write_reg(cpu, B, mod)
}

fn op_jnz(cpu: Cpu, operand: Int) -> Cpu {
  let address =
    operand
    |> decode_operand(Literal)
    |> read_operand(cpu)

  case read_reg(cpu, A) {
    0 -> cpu
    _ -> write_reg(cpu, Pc, address)
  }
}

fn read_memory(cpu: Cpu, memory: Memory) -> Result(#(Int, Int), Nil) {
  let pc = read_reg(cpu, Pc)
  let chunk =
    memory
    |> list.drop(pc)
    |> list.take(2)

  case chunk {
    [instruction, operand] -> Ok(#(instruction, operand))
    _ -> Error(Nil)
  }
}

fn callable_instruction(instruction: Instruction) -> fn(Cpu, Int) -> Cpu {
  case instruction {
    Div(dst:) -> fn(cpu, operand) { op_div(cpu, operand, dst) }
    Xor(use_operand:) -> fn(cpu, operand) { op_xor(cpu, operand, use_operand) }
    Mod -> op_mod
    JumpNotZero -> op_jnz
    Out -> op_out
  }
}

fn increase_pc(cpu: Cpu) -> Cpu {
  let pc = read_reg(cpu, Pc)
  write_reg(cpu, Pc, pc + 2)
}

fn iterate(cpu: Cpu, memory: Memory) -> Result(Cpu, Nil) {
  use #(instruction, operand) <- result.map(read_memory(cpu, memory))

  let instruction =
    instruction
    |> decode_instruction()
    |> callable_instruction()

  cpu
  |> increase_pc()
  |> instruction(operand)
}

fn run_program(cpu: Cpu, memory: Memory) -> List(Int) {
  let cpu =
    cpu
    |> functions.evolve_until(iterate(_, memory))

  list.reverse(cpu.out)
}

fn run_iteration(cpu: Cpu, memory: Memory) -> #(Int, Int) {
  let #(instruction, operand) =
    cpu
    |> read_memory(memory)
    |> results.expect("Read memory")

  let decoded_instruction =
    instruction
    |> decode_instruction()

  let executable =
    decoded_instruction
    |> callable_instruction()

  let cpu =
    cpu
    |> increase_pc()
    |> executable(operand)

  case decoded_instruction == JumpNotZero {
    True -> {
      let last_output = cpu.out |> list.first() |> results.expect("Last output")
      let register_a = read_reg(cpu, A)

      #(last_output, register_a)
    }
    False -> run_iteration(cpu, memory)
  }
}

fn find_register_a(
  cpu: Cpu,
  memory: Memory,
  outputs: List(Int),
) -> Result(Int, Nil) {
  let register_a = read_reg(cpu, A)
  printing.inspect(outputs, label: "Outputs")
  printing.inspect(register_a, label: "Register A")

  case outputs {
    [] -> read_reg(cpu, A) |> Ok()
    [output, ..outputs] -> {
      yielder.range(from: 0, to: 7)
      |> yielder.map(fn(delta) { register_a * 8 + delta })
      |> yielder.find_map(fn(next_register_a) {
        let next_cpu =
          cpu
          |> write_reg(A, next_register_a)

        let #(last_output, final_register_a) =
          next_cpu
          |> run_iteration(memory)

        case last_output == output && final_register_a == register_a {
          True -> find_register_a(next_cpu, memory, outputs)
          False -> Error(Nil)
        }
      })
    }
  }
}

fn interpret_program(program: Memory) -> List(#(Instruction, Value)) {
  program
  |> list.sized_chunk(2)
  |> list.try_map(pairs.from_list)
  |> results.expect("Program")
  |> list.map(fn(pair) {
    let #(instruction, operand) = pair
    let instruction = decode_instruction(instruction)
    let operand_type = operand_type_for_instruction(instruction)
    let operand = decode_operand(operand, operand_type)

    #(instruction, operand)
  })
}
