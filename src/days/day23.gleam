import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option
import gleam/pair
import gleam/result
import gleam/set.{type Set}
import gleam/string
import shared/algorithms

import shared/lists
import shared/parsers
import shared/results
import shared/types.{type ProblemPart, Part1, Part2}

type Computer =
  String

type Connection =
  #(Computer, Computer)

type Input =
  List(Connection)

type MappedConnections =
  Dict(Computer, Set(Computer))

const computer_prefix = "t"

pub fn solve(part: ProblemPart, input_path: String) {
  let assert Ok(connections) = read_input(input_path)

  case part {
    Part1 -> {
      let mapped_connections = map_connections(connections)

      mapped_connections
      |> dict.keys()
      |> list.filter(fn(computer) {
        string.starts_with(computer, computer_prefix)
      })
      |> list.map(triangle_lans(_, mapped_connections))
      |> list.reduce(set.union)
      |> result.lazy_unwrap(set.new)
      |> set.size()
      |> int.to_string()
    }
    Part2 -> {
      let mapped_connections = map_connections(connections)

      mapped_connections
      |> algorithms.bron_kerbosch()
      |> lists.max(fn(left, right) {
        int.compare(set.size(left), set.size(right))
      })
      |> results.expect("At least one LAN")
      |> set.to_list()
      |> list.sort(string.compare)
      |> string.join(",")
    }
  }
}

fn read_input(input_path: String) -> Result(Input, Nil) {
  use lines <- result.try(parsers.read_lines(input_path))
  use connections <- result.try(list.try_map(lines, parse_connection))
  Ok(connections)
}

fn parse_connection(connection: String) -> Result(Connection, Nil) {
  case string.split(connection, "-") {
    [left, right] -> Ok(#(left, right))
    _ -> Error(Nil)
  }
}

fn map_connections(connections: List(Connection)) -> MappedConnections {
  connections
  |> list.flat_map(fn(connection) { [connection, pair.swap(connection)] })
  |> list.fold(dict.new(), fn(map, connection) {
    let #(from, to) = connection
    dict.upsert(map, from, fn(maybe_connection) {
      maybe_connection
      |> option.lazy_unwrap(set.new)
      |> set.insert(to)
    })
  })
}

fn triangle_lans(
  computer: Computer,
  mapped_connections: MappedConnections,
) -> Set(Set(Computer)) {
  mapped_connections
  |> dict.get(computer)
  |> result.lazy_unwrap(set.new)
  |> set.to_list()
  |> list.flat_map(fn(middle) {
    mapped_connections
    |> dict.get(middle)
    |> result.lazy_unwrap(set.new)
    |> set.to_list()
    |> list.filter(has_connection_to(_, computer, mapped_connections))
    |> list.map(fn(last) { set.from_list([computer, middle, last]) })
  })
  |> set.from_list()
}

fn has_connection_to(
  left: Computer,
  right: Computer,
  mapped_connections: MappedConnections,
) -> Bool {
  mapped_connections
  |> dict.get(left)
  |> result.map(set.contains(_, right))
  |> result.unwrap(False)
}
