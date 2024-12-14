import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{Some}
import gleam/order.{type Order, Eq, Gt, Lt}
import gleam/regexp.{type Regexp, Match}
import gleam/result
import gleam/set
import gleam/string
import gleam/yielder

import shared/boards.{type Board}
import shared/coords.{type Coord}
import shared/dicts
import shared/functions
import shared/integers
import shared/lists
import shared/parsers
import shared/results
import shared/types.{type ProblemPart, Part1, Part2}

type Bot {
  Bot(pos: Coord, vel: Coord)
}

type Quadrant {
  TopLeft
  TopRight
  BottomLeft
  BottomRight
}

const small_board = #(11, 7)

const big_board = #(101, 103)

const target_turns = 100

const tree = "
1111111111111111111111111111111
1.............................1
1.............................1
1.............................1
1.............................1
1..............1..............1
1.............111.............1
1............11111............1
1...........1111111...........1
1..........111111111..........1
1............11111............1
1...........1111111...........1
1..........111111111..........1
1.........11111111111.........1
1........1111111111111........1
1..........111111111..........1
1.........11111111111.........1
1........1111111111111........1
1.......111111111111111.......1
1......11111111111111111......1
1........1111111111111........1
1.......111111111111111.......1
1......11111111111111111......1
1.....1111111111111111111.....1
1....111111111111111111111....1
1.............111.............1
1.............111.............1
1.............111.............1
1.............................1
1.............................1
1.............................1
1.............................1
1111111111111111111111111111111"

pub fn solve(part: ProblemPart, example: Bool, input_path: String) -> String {
  let assert Ok(bots) = read_input(input_path)
  let board = case example {
    True -> small_board
    False -> big_board
  }

  case part {
    Part1 -> {
      bots
      |> functions.evolve(target_turns, evolve_bots(_, board))
      |> list.map(fn(b) { b.pos })
      |> list.filter_map(quadrant(_, board))
      |> dicts.freq()
      |> safety_score()
      |> int.to_string()
    }
    Part2 -> {
      let tree = tree_board()

      yielder.iterate(bots, evolve_bots(_, board))
      |> yielder.index
      |> yielder.find_map(fn(bots_with_idx) {
        let #(bots, idx) = bots_with_idx
        let board =
          bots
          |> write_to_board(board)
          |> results.assert_unwrap()

        case can_contain_tree(board, tree) {
          True -> {
            case boards.is_sub_board(board, tree) {
              True -> Ok(idx)
              False -> Error(Nil)
            }
          }
          False -> Error(Nil)
        }
      })
      |> results.expect("Find tree")
      |> int.to_string
    }
  }
}

fn read_input(input_path: String) -> Result(List(Bot), Nil) {
  use lines <- result.try(parsers.read_lines(input_path))
  use bots <- result.try(list.try_map(lines, parse_bot))
  Ok(bots)
}

fn parse_bot(bot: String) -> Result(Bot, Nil) {
  let matches = regexp.scan(bot_pattern(), bot)
  let maybe_match = case matches {
    [Match(submatches: [Some(px), Some(py), Some(vx), Some(vy)], ..)] ->
      Ok(#(#(px, py), #(vx, vy)))
    _ -> Error(Nil)
  }

  use #(#(px, py), #(vx, vy)) <- result.try(maybe_match)
  use pos <- result.try(coords.parse(px, py))
  use vel <- result.try(coords.parse(vx, vy))
  Ok(Bot(pos, vel))
}

fn bot_pattern() -> Regexp {
  "^p=(-?\\d+),(-?\\d+) v=(-?\\d+),(-?\\d+)$"
  |> regexp.from_string()
  |> results.expect("Compile bot pattern")
}

fn move_wrap(bot: Bot, board_size: Coord) -> Bot {
  let new_pos =
    bot.pos
    |> coords.add_coords(bot.vel)
    |> coords.wrap_around(board_size)

  Bot(..bot, pos: new_pos)
}

fn quadrant(pos: Coord, board: Coord) -> Result(Quadrant, Nil) {
  case compare_axis(pos.0, board.0), compare_axis(pos.1, board.1) {
    Lt, Lt -> Ok(TopLeft)
    Gt, Lt -> Ok(TopRight)
    Lt, Gt -> Ok(BottomLeft)
    Gt, Gt -> Ok(BottomRight)
    _, _ -> Error(Nil)
  }
}

fn compare_axis(pos: Int, size: Int) -> Order {
  case results.assert_unwrap(integers.div_mod(size, 2)) {
    _ if pos < 0 -> panic as "Out of axis"
    #(half, _) if pos < half -> Lt
    #(half, 1) if pos == half -> Eq
    _ if pos < size -> Gt
    _ -> panic as "Out of axis"
  }
}

fn safety_score(freq: Dict(Quadrant, Int)) -> Int {
  [TopLeft, TopRight, BottomLeft, BottomRight]
  |> list.map(fn(quadrant) {
    freq
    |> dict.get(quadrant)
    |> result.unwrap(0)
  })
  |> int.product()
}

fn write_to_board(
  bots: List(Bot),
  board_size: Coord,
) -> Result(Board(Bool), Nil) {
  let bot_coords =
    bots
    |> list.map(fn(bot) { bot.pos })
    |> set.from_list()

  0
  |> list.range(board_size.1)
  |> list.map(fn(y) {
    0
    |> list.range(board_size.0)
    |> list.map(fn(x) { set.contains(bot_coords, #(x, y)) })
  })
  |> boards.from_rows()
  |> Ok()
}

fn evolve_bots(bots: List(Bot), board: Coord) -> List(Bot) {
  list.map(bots, move_wrap(_, board))
}

fn tree_board() -> Board(Bool) {
  tree
  |> string.trim()
  |> string.split(on: "\n")
  |> boards.from_lines(fn(char) {
    case char {
      "." -> Ok(False)
      _ -> Ok(True)
    }
  })
  |> results.expect("Parse tree board")
}

fn can_contain_tree(board: Board(Bool), tree: Board(Bool)) -> Bool {
  let margin_up = board.height - tree.height

  board.rows
  |> yielder.from_list()
  |> yielder.take(margin_up)
  |> yielder.any(fn(row) { lists.max_consecutive(row, True) >= tree.width })
}
