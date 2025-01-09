import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/string
import shared/parsers

import shared/boards.{type Board}
import shared/coords.{type Coord}
import shared/directions.{type Direction, Down, Left, Right, Up}
import shared/lists
import shared/results
import shared/types.{type ProblemPart, Part1, Part2}

type Key {
  Number(digit: Int)
  Direction(direction: Direction)
  Activate
}

type MaybeKey =
  Option(Key)

type Keypad {
  Keypad(keys: Dict(Key, Coord), board: Board(MaybeKey), pointer: Coord)
}

type Sequence =
  List(Key)

type Input =
  List(Sequence)

type State =
  #(List(Keypad), Sequence)

const robots_part1 = 2

const robots_part2 = 25

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(input) = read_input(input_path)

  let robots = case part {
    Part1 -> robots_part1
    Part2 -> robots_part2
  }

  let keypads = keypads(directional: robots)

  input
  |> list.map(fn(request) {
    let #(_memo, presses) = presses(keypads, request, dict.new())

    sequence_numeric_value(request) * presses
  })
  |> int.sum()
  |> int.to_string()
}

fn sequence_numeric_value(sequence: Sequence) -> Int {
  sequence
  |> list.filter_map(fn(key) {
    case key {
      Number(number) -> Ok(number)
      Activate -> Error(Nil)
      Direction(_) -> panic as "Can't evaluate sequence with directions"
    }
  })
  |> int.undigits(10)
  |> results.expect("Parse sequence as numeric value")
}

fn read_input(input_path: String) -> Result(Input, Nil) {
  use lines <- result.try(parsers.read_lines(input_path))
  lines
  |> list.try_map(fn(line) {
    line
    |> string.to_graphemes()
    |> list.try_map(parse_key)
  })
}

fn parse_key(char: String) -> Result(Key, Nil) {
  char
  |> int.parse()
  |> result.map(Number)
  |> result.try_recover(fn(_) {
    case char == "A" {
      True -> Ok(Activate)
      False -> Error(Nil)
    }
  })
}

fn keypads(directional directional: Int) -> List(Keypad) {
  [numeric_keypad()]
  |> list.append(list.repeat(direction_keypad(), directional))
}

fn valid_sequences(keypad: Keypad, to to: Coord) -> List(Sequence) {
  let #(delta_x, delta_y) = coords.sub_coords(to, keypad.pointer)

  let horizontal = case delta_x {
    positive if positive > 0 -> list.repeat(Right, positive)
    negative if negative < 0 -> list.repeat(Left, -negative)
    _ -> []
  }

  let vertical = case delta_y {
    positive if positive > 0 -> list.repeat(Down, positive)
    negative if negative < 0 -> list.repeat(Up, -negative)
    _ -> []
  }

  [list.append(horizontal, vertical), list.append(vertical, horizontal)]
  |> list.unique()
  |> list.filter(sequence_is_valid(keypad, path: _))
  |> list.map(list.map(_, Direction))
  |> list.map(list.append(_, [Activate]))
}

fn sequence_is_valid(keypad: Keypad, path path: List(Direction)) -> Bool {
  path
  |> list.scan(keypad.pointer, with: fn(coord, dir) {
    dir
    |> directions.to_delta
    |> coords.add_coords(coord, _)
  })
  |> list.all(fn(coord) {
    keypad.board
    |> boards.read_coord(coord)
    |> result.map(option.is_some)
    |> result.unwrap(False)
  })
}

fn numeric_keypad() -> Keypad {
  let board =
    [
      list.range(from: 7, to: 9) |> list.map(Number) |> list.map(Some),
      list.range(from: 4, to: 6) |> list.map(Number) |> list.map(Some),
      list.range(from: 1, to: 3) |> list.map(Number) |> list.map(Some),
      [None, 0 |> Number |> Some, Some(Activate)],
    ]
    |> boards.from_rows()

  let pointer =
    boards.find_cell(board, Some(Activate))
    |> lists.unwrap()
    |> results.expect("Find Enter in board")

  let keys = keys_from_board(board)

  Keypad(keys:, board:, pointer:)
}

fn direction_keypad() -> Keypad {
  let board =
    [
      [None, Up |> Direction |> Some, Some(Activate)],
      [
        Left |> Direction |> Some,
        Down |> Direction |> Some,
        Right |> Direction |> Some,
      ],
    ]
    |> boards.from_rows()

  let pointer =
    boards.find_cell(board, Some(Activate))
    |> lists.unwrap()
    |> results.expect("Find Enter in board")

  let keys = keys_from_board(board)

  Keypad(keys:, board:, pointer:)
}

fn keys_from_board(board: Board(MaybeKey)) -> Dict(Key, Coord) {
  board
  |> boards.cells()
  |> list.filter_map(fn(pair) {
    case pair {
      #(coord, Some(key)) -> Ok(#(key, coord))
      _ -> Error(Nil)
    }
  })
  |> dict.from_list()
}

fn presses(
  keypads: List(Keypad),
  code: Sequence,
  memo: Dict(State, Int),
) -> #(Dict(State, Int), Int) {
  case dict.get(memo, #(keypads, code)) {
    Ok(presses) -> #(memo, presses)
    Error(Nil) -> {
      case keypads {
        [] -> #(memo, list.length(code))
        [keypad, ..keypads] as all_keypads -> {
          let #(#(memo, _keypad), presses) =
            code
            |> list.map_fold(#(memo, keypad), fn(pair, key) {
              let #(memo, keypad) = pair
              let target =
                keypad.keys
                |> dict.get(key)
                |> results.expect("Find key in keypad")

              let #(memo, key_presses) =
                keypad
                |> valid_sequences(to: target)
                |> list.map_fold(memo, fn(memo, valid_sequence) {
                  presses(keypads, valid_sequence, memo)
                })
                |> pair.map_second(fn(valid_sequences_presses) {
                  lists.min(valid_sequences_presses, int.compare)
                  |> results.assert_unwrap()
                })

              let keypad = Keypad(..keypad, pointer: target)
              #(#(memo, keypad), key_presses)
            })
            |> pair.map_second(int.sum)

          let memo = dict.insert(memo, #(all_keypads, code), presses)
          #(memo, presses)
        }
      }
    }
  }
}
