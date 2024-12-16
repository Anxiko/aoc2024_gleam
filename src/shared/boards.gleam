import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder.{type Yielder}
import shared/yielders

import shared/coords.{type Coord}
import shared/lists

pub type Row(cell) =
  List(cell)

pub type Board(cell) {
  Board(rows: List(Row(cell)), width: Int, height: Int)
}

pub fn from_lines(
  lines: List(String),
  cell_parser: fn(String) -> Result(cell, Nil),
) -> Result(Board(cell), Nil) {
  case lines {
    [] -> Ok(Board([], width: 0, height: 0))
    [first, ..] as lines -> {
      let width = string.length(first)
      let height = list.length(lines)
      let parsed_rows = list.try_map(lines, parse_row(_, cell_parser))
      use rows <- result.map(parsed_rows)
      ensure_consistent_row_width(rows, width)
      Board(rows, width, height)
    }
  }
}

pub fn from_rows(rows: List(List(cell))) -> Board(cell) {
  case rows {
    [] -> Board([], width: 0, height: 0)
    [first, ..] as rows -> {
      let width = list.length(first)
      let height = list.length(rows)
      ensure_consistent_row_width(rows, width)
      Board(rows, width:, height:)
    }
  }
}

pub fn coords(board: Board(_)) -> List(Coord) {
  lists.product(list.range(0, board.width - 1), list.range(0, board.height - 1))
}

pub fn cells(board: Board(cell)) -> List(#(Coord, cell)) {
  board.rows
  |> lists.with_index()
  |> list.flat_map(fn(pair) {
    let #(y, row) = pair
    row
    |> lists.with_index()
    |> list.map(fn(pair) {
      let #(x, cell) = pair
      #(#(x, y), cell)
    })
  })
}

pub fn row_at(board: Board(cell), y y: Int) -> Result(List(cell), Nil) {
  board.rows
  |> lists.at(y)
}

pub fn column_at(board: Board(cell), x x: Int) -> Result(List(cell), Nil) {
  board.rows
  |> list.try_map(lists.at(_, x))
}

pub fn neighbours(
  board: Board(cell),
  pos: Coord,
  diagonals include_diagonals: Bool,
) -> List(#(Coord, cell)) {
  coords.deltas(cross: True, diagonal: include_diagonals)
  |> list.map(coords.add_coords(pos, _))
  |> list.filter_map(fn(coord) {
    board
    |> read_coord(coord)
    |> result.map(fn(cell) { #(coord, cell) })
  })
}

pub fn is_valid_coord(board: Board(_), coord: Coord) -> Bool {
  let #(x, y) = coord
  0 <= x && x < board.width && 0 <= y && y < board.height
}

pub fn read_coord(board: Board(cell), coord: Coord) -> Result(cell, Nil) {
  let #(x, y) = coord

  use row <- result.try(lists.at(board.rows, y))
  use char <- result.map(lists.at(row, x))
  char
}

pub fn write_coord(
  board: Board(cell),
  coord: Coord,
  cell: cell,
) -> Result(Board(cell), Nil) {
  let #(x, y) = coord
  let rows = board.rows

  use row <- result.try(lists.at(rows, y))
  use updated_row <- result.try(lists.write_at(row, x, cell))
  use updated_rows <- result.map(lists.write_at(rows, y, updated_row))
  Board(..board, rows: updated_rows)
}

pub fn update_coord(
  board: Board(cell),
  pos: Coord,
  updater: fn(cell) -> cell,
) -> Result(Board(cell), Nil) {
  use cell <- result.try(read_coord(board, pos))
  let updated_cell = updater(cell)
  use board <- result.try(write_coord(board, pos, updated_cell))
  Ok(board)
}

pub fn to_string(board: Board(c), cell_formatter: fn(c) -> String) -> String {
  board.rows
  |> list.map(fn(row) {
    row
    |> list.map(cell_formatter)
    |> string.join("")
  })
  |> string.join("\n")
}

pub fn from_cell(cell: c, width width: Int, height height: Int) -> Board(c) {
  let rows =
    cell
    |> list.repeat(width)
    |> list.repeat(height)

  Board(rows:, width:, height:)
}

pub fn sub_board(
  board: Board(c),
  origin: Coord,
  width: Int,
  height: Int,
) -> Result(Board(c), Nil) {
  case width, height {
    width, height
      if width < 0 || height < 0 || width > board.width || height > board.height
    -> Error(Nil)
    width, height -> {
      let selected_rows =
        board.rows
        |> lists.sub_list(start: origin.1, size: height)
        |> list.map(lists.sub_list(_, start: origin.0, size: width))
      Board(selected_rows, width:, height:) |> Ok()
    }
  }
}

pub fn all_sub_boards(
  board: Board(c),
  width width: Int,
  height height: Int,
) -> Yielder(#(Coord, Board(c))) {
  board
  |> coords()
  |> yielder.from_list()
  |> yielder.filter_map(fn(origin) {
    origin
    |> sub_board(board, _, width, height)
    |> result.map(fn(s) { #(origin, s) })
  })
}

pub fn find_sub_board(
  board: Board(c),
  sub_board: Board(c),
) -> Result(#(Coord, Board(c)), Nil) {
  board
  |> all_sub_boards(width: sub_board.width, height: sub_board.height)
  |> yielder.find(fn(pair) { pair.1 == sub_board })
}

pub fn is_sub_board(board: Board(c), sub_board: Board(c)) -> Bool {
  case board.width - sub_board.width, board.height - sub_board.height {
    margin_left, margin_up if margin_left < 0 || margin_up < 0 ->
      panic as "Sub-board is bigger than board!"
    margin_left, margin_up -> {
      yielder.range(0, margin_left)
      |> yielders.product(yielder.range(0, margin_up))
      |> yielder.any(fn(offset) {
        let #(x_offset, y_offset) = offset

        board.rows
        |> list.drop(y_offset)
        |> list.zip(sub_board.rows)
        |> list.all(fn(row_pair) {
          let #(board_row, sub_board_row) = row_pair
          let board_row = list.drop(board_row, x_offset)
          lists.is_prefix(board_row, prefix: sub_board_row)
        })
      })
    }
  }
}

pub fn transform(
  board: Board(cell),
  acc: acc,
  transformer: fn(acc, Coord, cell) -> #(acc, transformed),
) -> #(acc, Board(transformed)) {
  let #(acc, transformed_rows) =
    board.rows
    |> lists.with_index()
    |> list.map_fold(acc, fn(acc, idx_row) {
      let #(y, row) = idx_row
      row
      |> lists.with_index()
      |> list.map_fold(acc, fn(acc, idx_cell) {
        let #(x, cell) = idx_cell
        transformer(acc, #(x, y), cell)
      })
    })

  #(
    acc,
    Board(rows: transformed_rows, width: board.width, height: board.height),
  )
}

pub fn map(board: Board(a), with mapper: fn(a) -> b) -> Board(b) {
  let rows =
    board.rows
    |> list.map(list.map(_, mapper))

  Board(rows:, width: board.width, height: board.height)
}

fn parse_row(
  raw_row: String,
  cell_parser: fn(String) -> Result(cell, Nil),
) -> Result(Row(cell), Nil) {
  raw_row
  |> string.to_graphemes()
  |> list.try_map(cell_parser)
}

fn ensure_consistent_row_width(rows: List(List(c)), expected_width: Int) {
  list.each(rows, fn(row) {
    case list.length(row) == expected_width {
      True -> Nil
      False ->
        panic as string.concat([
          "Inconsistent row length, row ",
          string.inspect(row),
          " does not have expected width of ",
          row |> list.length() |> int.to_string(),
        ])
    }
  })
}
