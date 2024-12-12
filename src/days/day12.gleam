import gleam/int
import gleam/list
import gleam/pair
import gleam/result
import gleam/set.{type Set}

import shared/boards.{type Board}
import shared/coords.{type Coord}
import shared/directions.{type Direction}
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
  |> list.map(map_plot_cost(board, _, sides_discount))
  |> int.sum()
  |> int.to_string()
}

fn read_input(input_path: String) -> Result(Board(String), Nil) {
  use lines <- result.try(parsers.read_lines(input_path))
  use board <- result.try(boards.from_lines(lines, Ok))
  Ok(board)
}

fn map_plot_cost(
  board: Board(String),
  map_plot: MapPlot,
  discount sides_discount: Bool,
) -> Int {
  case sides_discount {
    False -> map_plot.data.area * map_plot.data.perimeter
    True -> {
      let sides = map_plot_sides(board, map_plot)
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

fn map_plot_sides(board: Board(String), map_plot: MapPlot) -> Int {
  do_map_plot_sides(board, map_plot, set.new())
}

fn do_map_plot_sides(
  board: Board(String),
  map_plot: MapPlot,
  traversed: Set(State),
) -> Int {
  case find_start(board, map_plot, traversed) {
    Ok(start) -> {
      let #(turns, path) = border_path(board, map_plot, start)
      turns
      + do_map_plot_sides(
        board,
        map_plot,
        set.union(traversed, set.from_list(path)),
      )
    }
    Error(Nil) -> 0
  }
}

fn find_start(
  board: Board(String),
  map_plot: MapPlot,
  visited: Set(State),
) -> Result(#(Direction, Coord), Nil) {
  map_plot.data.coords
  |> set.to_list()
  |> list.flat_map(fn(coord) {
    directions.directions()
    |> list.map(fn(dir) { #(dir, coord) })
  })
  |> list.filter(fn(s) { !set.contains(visited, s) })
  |> list.find(fn(dir_coord) {
    let #(dir, coord) = dir_coord

    dir
    |> directions.rotate_left()
    |> directions.to_delta()
    |> coords.add_coords(coord)
    |> boards.read_coord(board, _)
    |> result.map(fn(other) { other != map_plot.cell })
    |> result.unwrap(True)
  })
}

fn border_path(
  board: Board(String),
  map_plot: MapPlot,
  initial: State,
) -> #(Int, List(State)) {
  do_border_path(board, map_plot, initial, initial, 0, [])
}

fn do_border_path(
  board: Board(String),
  map_plot: MapPlot,
  initial: State,
  current: State,
  turns: Int,
  path: List(State),
) -> #(Int, List(State)) {
  case turns > 0 && initial == current {
    True -> #(turns, path)
    False -> {
      let #(dir, coord) = current
      let step_attempt =
        can_step(board, map_plot, coord, directions.rotate_left(dir))
        |> result.map(fn(state) { #(1, state) })
        |> result.lazy_or(fn() {
          can_step(board, map_plot, coord, dir)
          |> result.map(fn(state) { #(0, state) })
        })

      case step_attempt {
        Ok(#(new_turns, new_state)) ->
          do_border_path(
            board,
            map_plot,
            initial,
            new_state,
            turns + new_turns,
            [new_state, ..path],
          )
        Error(Nil) -> {
          let new_state = #(directions.rotate_right(dir), coord)

          do_border_path(board, map_plot, initial, new_state, turns + 1, [
            new_state,
            ..path
          ])
        }
      }
    }
  }
}

fn can_step(
  board: Board(String),
  map_plot: MapPlot,
  coord: Coord,
  dir: Direction,
) -> Result(#(Direction, Coord), Nil) {
  let next_coord =
    dir
    |> directions.to_delta()
    |> coords.add_coords(coord)

  use cell <- result.try(boards.read_coord(board, next_coord))
  case cell == map_plot.cell {
    True -> Ok(#(dir, next_coord))
    False -> Error(Nil)
  }
}
