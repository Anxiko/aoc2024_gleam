import shared/printing
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/result
import gleam/set.{type Set}
import shared/dicts
import shared/lists
import shared/sets

pub type NodeInfo(state) {
  NodeInfo(previous: Set(state), cost: Int)
}

pub fn dijkstra(
  initial: state,
  state_neighbours: fn(state, Int) -> List(#(state, Int)),
) {
  run_dijkstra(
    sets.single(initial),
    dicts.single(initial, NodeInfo(previous: set.new(), cost: 0)),
    state_neighbours,
  )
}

fn run_dijkstra(
  active: Set(state),
  mapped_node_info: Dict(state, NodeInfo(state)),
  state_neighbours: fn(state, Int) -> List(#(state, Int)),
) -> Dict(state, NodeInfo(state)) {
  case min_active(active, mapped_node_info) {
    Error(Nil) -> mapped_node_info
    Ok(#(state, cost, active)) -> {
      let #(active, mapped_node_info) =
        state
        |> state_neighbours(cost)
        |> list.fold(
          from: #(active, mapped_node_info),
          with: fn(pair, neighbour) {
            let #(active, mapped_node_info) = pair
            let #(neighbour, cost) = neighbour
            update_node_info_mapping(
              state,
              neighbour,
              cost,
              active,
              mapped_node_info,
            )
          },
        )
      run_dijkstra(active, mapped_node_info, state_neighbours)
    }
  }
}

fn min_active(
  active: Set(state),
  mapped_node_info: Dict(state, NodeInfo(state)),
) -> Result(#(state, Int, Set(state)), Nil) {
  active
  |> set.to_list()
  |> list.map(fn(state) {
    let assert Ok(NodeInfo(cost:, ..)) = dict.get(mapped_node_info, state)
    #(state, cost)
  })
  |> lists.min(fn(left, right) { int.compare(left.1, right.1) })
  |> result.map(fn(pair) {
    let #(state, cost) = pair
    #(state, cost, set.delete(active, state))
  })
}

fn update_node_info_mapping(
  state: state,
  neighbour: state,
  cost: Int,
  active: Set(state),
  mapped_node_info: Dict(state, NodeInfo(state)),
) -> #(Set(state), Dict(state, NodeInfo(state))) {
  case dict.get(mapped_node_info, neighbour) {
    Ok(NodeInfo(cost: current_cost, ..)) if current_cost < cost -> {
      #(active, mapped_node_info)
    }
    Ok(NodeInfo(cost: current_cost, previous:) as node_info)
      if current_cost == cost
    -> {
      let node_info =
        NodeInfo(..node_info, previous: set.insert(previous, state))
      let mapped_node_info = dict.insert(mapped_node_info, neighbour, node_info)
      #(active, mapped_node_info)
    }
    _ -> {
      let node_info = NodeInfo(previous: sets.single(state), cost:)
      let mapped_node_info = dict.insert(mapped_node_info, neighbour, node_info)
      let active = set.insert(active, neighbour)
      #(active, mapped_node_info)
    }
  }
}
