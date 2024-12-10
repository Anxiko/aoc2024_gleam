import gleam/int
import gleam/list
import gleam/result
import gleam/string

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
    [first, ..rest] as lines -> {
      let width = string.length(first)
      let height = list.length(lines)
      ensure_consistent_row_width(rest, string.length(first))
      let parsed_rows = list.try_map(lines, parse_row(_, cell_parser))
      use rows <- result.map(parsed_rows)
      Board(rows, width, height)
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

fn parse_row(
  raw_row: String,
  cell_parser: fn(String) -> Result(cell, Nil),
) -> Result(Row(cell), Nil) {
  raw_row
  |> string.to_graphemes()
  |> list.try_map(cell_parser)
}

fn ensure_consistent_row_width(rows: List(String), expected_width: Int) {
  list.each(rows, fn(row) {
    case string.length(row) == expected_width {
      True -> Nil
      False ->
        panic as string.concat([
          "Inconsistent row length, row ",
          row,
          " does not have expected width of ",
          row |> string.length() |> int.to_string(),
        ])
    }
  })
}
