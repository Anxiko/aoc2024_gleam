import gleam/int
import gleam/io
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import shared/printing

import shared/boards.{type Board}
import shared/coords.{type Coord}
import shared/directions.{type Direction}
import shared/pairs
import shared/parsers
import shared/sets
import shared/types.{type ProblemPart, Part2}

type MapPlot {
  MapPlot(cell: String, data: PlotData)
}

type PlotData {
  PlotData(area: Int, perimeter: Int, coords: Set(Coord))
}

type State =
  #(Direction, Coord)

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(board) = read_input(input_path)
  let sides_discount = part == Part2

  board
  |> explore_map()
  |> list.map(map_plot_cost(_, sides_discount))
  |> int.sum()
  |> int.to_string()
}

fn read_input(input_path: String) -> Result(Board(String), Nil) {
  use lines <- result.try(parsers.read_lines(input_path))
  use board <- result.try(boards.from_lines(lines, Ok))
  Ok(board)
}

fn map_plot_cost(map_plot: MapPlot, discount sides_discount: Bool) -> Int {
  case sides_discount {
    False -> map_plot.data.area * map_plot.data.perimeter
    True -> {
      let sides = count_map_plot_corners(map_plot)

      map_plot.data.area * sides
    }
  }
}

fn explore_map(board: Board(String)) -> List(MapPlot) {
  let all_coords =
    board
    |> boards.coords()
    |> set.from_list()

  do_explore_map(board, all_coords, [])
}

fn do_explore_map(
  board: Board(String),
  pending: Set(Coord),
  acc: List(MapPlot),
) -> List(MapPlot) {
  case sets.pop(pending) {
    Ok(#(next, pending)) -> {
      let region = explore_region(board, next)
      let pending = set.difference(pending, region.data.coords)
      do_explore_map(board, pending, [region, ..acc])
    }
    Error(Nil) -> {
      acc
    }
  }
}

fn explore_region(board: Board(String), coord: Coord) -> MapPlot {
  let assert Ok(cell) = boards.read_coord(board, coord)
  let plot_data = do_explore_region(board, cell, [coord], new_plot_data())
  MapPlot(cell: cell, data: plot_data)
}

fn do_explore_region(
  board: Board(String),
  cell: String,
  pending: List(Coord),
  plot_data: PlotData,
) -> PlotData {
  case pending {
    [] -> plot_data
    [next, ..pending] -> {
      case set.contains(plot_data.coords, next) {
        True -> do_explore_region(board, cell, pending, plot_data)
        False -> {
          let #(perimeter, similar_neighbours) =
            check_neighbours(board, next, cell)
          do_explore_region(
            board,
            cell,
            list.append(similar_neighbours, pending),
            update_plot_data(plot_data, next, perimeter),
          )
        }
      }
    }
  }
}

fn check_neighbours(
  board: Board(String),
  coord: Coord,
  cell: String,
) -> #(Int, List(Coord)) {
  coords.deltas(cross: True, diagonal: False)
  |> list.map(coords.add_coords(_, coord))
  |> list.map(fn(coord) {
    board
    |> boards.read_coord(coord)
    |> result.map(fn(cell) { #(coord, cell) })
  })
  |> list.fold(#(0, []), fn(acc, maybe_neighbour) {
    case maybe_neighbour {
      Ok(#(neighbour_coord, neighbour_cell)) if neighbour_cell == cell -> {
        pair.map_second(acc, list.prepend(_, neighbour_coord))
      }
      _ -> pair.map_first(acc, int.add(_, 1))
    }
  })
}

fn new_plot_data() -> PlotData {
  PlotData(area: 0, perimeter: 0, coords: set.new())
}

fn update_plot_data(
  plot_data: PlotData,
  coord: Coord,
  perimeter: Int,
) -> PlotData {
  PlotData(
    coords: set.insert(plot_data.coords, coord),
    area: plot_data.area + 1,
    perimeter: plot_data.perimeter + perimeter,
  )
}

fn count_map_plot_corners(map_plot: MapPlot) -> Int {
  map_plot.data.coords
  |> set.to_list()
  |> list.map(count_coord_corners(map_plot, _))
  |> int.sum()
}

fn count_coord_corners(map_plot: MapPlot, coord: Coord) -> Int {
  coords.deltas(cross: False, diagonal: True)
  |> list.count(fn(delta) {
    let #(horizontal_in, vertical_in) =
      delta
      |> coords.decompose()
      |> pairs.map_both(coords.add_coords(_, coord))
      |> pairs.map_both(set.contains(map_plot.data.coords, _))

    let diagonal_in =
      delta |> coords.add_coords(coord) |> set.contains(map_plot.data.coords, _)

    horizontal_in == vertical_in && { !diagonal_in || !horizontal_in }
  })
}
