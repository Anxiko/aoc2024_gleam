import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/string
import gleam/yielder

import shared/boards.{type Board}
import shared/coords.{type Coord}
import shared/directions.{type Direction, Down, Left, Right, Up}
import shared/parsers
import shared/results
import shared/types.{type ProblemPart, Part1, Part2}

type Cell {
  Wall
  Box
  LeftWideBox
  RightWideBox
  Empty
}

type ParsedCell {
  Cell(Cell)
  Bot
}

type Warehouse {
  Warehouse(board: Board(Cell), directions: List(Direction), bot: Coord)
}

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(warehouse) = read_input(input_path)
  case part {
    Part1 -> {
      let #(board, _pos) =
        warehouse.directions
        |> yielder.from_list()
        |> yielder.fold(#(warehouse.board, warehouse.bot), fn(acc, dir) {
          let #(board, bot) = acc
          move_bot(board, bot, dir)
        })

      board
      |> boards.cells()
      |> list.filter(fn(pair) { pair.1 == Box })
      |> list.map(pair.first)
      |> list.map(fn(coord) { coord.1 * 100 + coord.0 })
      |> int.sum()
      |> int.to_string()
    }
    Part2 -> {
      let board = widen_board(warehouse.board)
      let bot = warehouse.bot |> pair.map_first(int.multiply(_, 2))

      warehouse.directions
      |> yielder.from_list()
      |> yielder.fold(#(board, bot), fn(state, dir) {
        let #(board, bot) = state

        let state = case try_move(board, bot, dir) {
          Ok(board) -> #(board, shift_coord(bot, dir))
          Error(Nil) -> state
        }

        state
      })
      |> pair.first()
      |> boards.cells()
      |> list.filter(fn(pair) { pair.1 == LeftWideBox })
      |> list.map(pair.first)
      |> list.map(fn(coord) { coord.1 * 100 + coord.0 })
      |> int.sum()
      |> int.to_string()
    }
  }
}

fn read_input(input_path: String) -> Result(Warehouse, Nil) {
  let chunks = case parsers.read_line_chunks(input_path) {
    Ok([board, directions]) -> Ok(#(board, directions))
    _ -> Error(Nil)
  }

  use #(board, directions) <- result.try(chunks)
  use board <- result.try(boards.from_lines(board, parse_cell))
  use #(bot, board) <- result.try(extract_bot(board))
  let directions = list.flat_map(directions, string.to_graphemes)
  use directions <- result.try(list.try_map(directions, directions.parse))
  Warehouse(board:, directions:, bot:) |> Ok()
}

fn parse_cell(cell: String) -> Result(ParsedCell, Nil) {
  case cell {
    "#" -> Ok(Cell(Wall))
    "." -> Ok(Cell(Empty))
    "O" -> Ok(Cell(Box))
    "@" -> Ok(Bot)
    _ -> Error(Nil)
  }
}

fn extract_bot(board: Board(ParsedCell)) -> Result(#(Coord, Board(Cell)), Nil) {
  let #(acc, board) =
    board
    |> boards.transform([], fn(acc, coord, parsed_cell) {
      case parsed_cell {
        Bot -> #([coord, ..acc], Empty)
        Cell(cell) -> #(acc, cell)
      }
    })

  case acc {
    [bot_coord] -> Ok(#(bot_coord, board))
    _ -> Error(Nil)
  }
}

fn move_bot(
  board: Board(Cell),
  pos: Coord,
  dir: Direction,
) -> #(Board(Cell), Coord) {
  board
  |> view_ahead(pos, dir)
  |> try_push()
  |> result.map(fn(ahead) {
    let board = write_ahead(board, pos, dir, ahead)
    let pos =
      dir
      |> directions.to_delta()
      |> coords.add_coords(pos)
    #(board, pos)
  })
  |> result.unwrap(#(board, pos))
}

fn view_ahead(board: Board(Cell), pos: Coord, dir: Direction) -> List(Cell) {
  let #(x, y) = pos

  case dir {
    Up -> {
      board
      |> boards.column_at(x:)
      |> results.assert_unwrap()
      |> list.take(y)
      |> list.reverse()
    }
    Down -> {
      board
      |> boards.column_at(x:)
      |> results.assert_unwrap()
      |> list.drop(y + 1)
    }
    Left -> {
      board
      |> boards.row_at(y:)
      |> results.assert_unwrap()
      |> list.take(x)
      |> list.reverse()
    }
    Right -> {
      board
      |> boards.row_at(y:)
      |> results.assert_unwrap()
      |> list.drop(x + 1)
    }
  }
}

fn write_ahead(
  board: Board(Cell),
  pos: Coord,
  dir: Direction,
  view: List(Cell),
) -> Board(Cell) {
  let delta = directions.to_delta(dir)

  pos
  |> yielder.iterate(coords.add_coords(_, delta))
  |> yielder.drop(1)
  |> yielder.zip(yielder.from_list(view))
  |> yielder.fold(board, fn(board, pair) {
    let #(coord, cell) = pair

    board
    |> boards.write_coord(coord, cell)
    |> results.assert_unwrap()
  })
}

fn try_push(cells: List(Cell)) -> Result(List(Cell), Nil) {
  use #(boxes, rest) <- result.map(do_try_push(cells, 0))
  list.flatten([[Empty], list.repeat(Box, boxes), rest])
}

fn do_try_push(cells: List(Cell), boxes: Int) -> Result(#(Int, List(Cell)), Nil) {
  case cells {
    [Box, ..cells] -> do_try_push(cells, boxes + 1)
    [Empty, ..cells] -> Ok(#(boxes, cells))
    _ -> Error(Nil)
  }
}

fn displaced_obstacles(
  board: Board(Cell),
  coord: Coord,
) -> Result(List(Coord), Nil) {
  use cell <- result.try(boards.read_coord(board, coord))
  case cell {
    Box -> Ok([coord])
    LeftWideBox -> Ok([coord, shift_coord(coord, Right)])
    RightWideBox -> Ok([shift_coord(coord, Left), coord])
    Empty -> Ok([])
    Wall -> Error(Nil)
  }
}

fn try_move(
  board: Board(Cell),
  pos: Coord,
  dir: Direction,
) -> Result(Board(Cell), Nil) {
  use coords <- result.try(do_try_move(board, [pos], dir, []))

  let pairs =
    coords
    |> list.map(fn(coord) {
      let cell =
        board
        |> boards.read_coord(coord)
        |> results.assert_unwrap()

      #(coord, cell)
    })

  let board =
    pairs
    |> list.fold(board, fn(board, pair) {
      let #(coord, _cell) = pair

      board
      |> boards.write_coord(coord, Empty)
      |> results.assert_unwrap()
    })

  let board =
    pairs
    |> list.map(pair.map_first(_, shift_coord(_, dir)))
    |> list.fold(board, fn(board, pair) {
      let #(coord, cell) = pair

      board
      |> boards.write_coord(coord, cell)
      |> results.assert_unwrap()
    })

  Ok(board)
}

fn do_try_move(
  board: Board(Cell),
  coords: List(Coord),
  dir: Direction,
  acc: List(Coord),
) -> Result(List(Coord), Nil) {
  case coords {
    [] -> Ok(acc)

    coords -> {
      let acc = list.append(coords, acc)

      let moved_coords =
        coords
        |> list.map(shift_coord(_, dir))

      let maybe_displaced_coords =
        moved_coords
        |> list.try_map(displaced_obstacles(board, _))
        |> result.map(list.flatten)

      use displaced_coords <- result.try(maybe_displaced_coords)
      let displaced_coords =
        displaced_coords
        |> list.filter(fn(displaced) { !list.contains(acc, displaced) })
      do_try_move(board, displaced_coords, dir, acc)
    }
  }
}

fn shift_coord(coord: Coord, dir: Direction) -> Coord {
  dir
  |> directions.to_delta()
  |> coords.add_coords(coord)
}

fn widen_board(board: Board(Cell)) -> Board(Cell) {
  let rows = {
    use row <- list.map(board.rows)
    use cell <- list.flat_map(row)
    case cell {
      Empty as cell | Wall as cell -> list.repeat(cell, 2)
      Box -> [LeftWideBox, RightWideBox]
      unexpected ->
        panic as string.concat([
          "Unexpected cell during widening: ",
          string.inspect(unexpected),
        ])
    }
  }
  boards.from_rows(rows)
}
