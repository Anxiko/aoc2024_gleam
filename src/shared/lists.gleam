import gleam/int
import gleam/list
import gleam/order.{type Order, Eq, Gt, Lt}

pub fn with_index(elements: List(a)) -> List(#(Int, a)) {
  elements
  |> list.index_map(fn(element, idx) { #(idx, element) })
}

pub fn delete_at(elements: List(a), idx: Int) -> List(a) {
  elements
  |> with_index()
  |> list.filter_map(fn(tuple) {
    case tuple {
      #(i, e) if i == idx -> Error(e)
      #(_, e) -> Ok(e)
    }
  })
}

pub fn product(left: List(x), right: List(y)) -> List(#(x, y)) {
  left
  |> list.flat_map(fn(x) {
    right
    |> list.map(fn(y) { #(x, y) })
  })
}

pub fn at(elements: List(t), idx: Int) -> Result(t, Nil) {
  case idx {
    negative if negative < 0 -> Error(Nil)
    non_negative ->
      elements
      |> list.drop(non_negative)
      |> list.first()
  }
}

pub fn write_at(elements: List(t), idx: Int, element: t) -> Result(List(t), Nil) {
  case 0 <= idx && idx < list.length(elements) {
    True -> {
      elements
      |> with_index()
      |> list.map(fn(pair) {
        let #(i, e) = pair

        case i == idx {
          True -> element
          False -> e
        }
      })
      |> Ok()
    }
    False -> Error(Nil)
  }
}

pub fn split_many(
  elements: List(t),
  by predicate: fn(t) -> Bool,
  discard_splitter discard: Bool,
) -> List(List(t)) {
  list.fold(elements, [], fn(acc, e) {
    case acc, predicate(e), discard {
      [], False, _ -> [[e]]
      [head, ..tail], False, _ -> [[e, ..head], ..tail]
      acc, True, True -> [[], ..acc]
      acc, True, False -> [[e], ..acc]
    }
  })
  |> list.map(list.reverse(_))
  |> list.reverse()
}

pub fn is_ordered(elements: List(t), by comparer: fn(t, t) -> Order) -> Bool {
  case elements {
    [] | [_head] -> True
    [left, right, ..rest] ->
      case comparer(left, right) {
        Lt | Eq -> is_ordered([right, ..rest], comparer)
        Gt -> False
      }
  }
}

pub fn middle(elements: List(t)) -> Result(t, Nil) {
  let length = list.length(elements)
  case length / 2, length % 2 {
    half, 1 -> {
      let assert Ok(middle) = at(elements, half)
      Ok(middle)
    }
    _, _ -> Error(Nil)
  }
}

pub type CutResult(t, s) {
  Take(state: s)
  TakeCut(taken: t, remaining: t)
  Halt
}

pub fn cut_list(
  elements: List(t),
  state state: s,
  cutter cutter: fn(t, s) -> CutResult(t, s),
) -> #(List(t), List(t)) {
  do_cut_list(elements, [], state, cutter)
}

fn do_cut_list(
  remaining: List(t),
  taken: List(t),
  state: s,
  cutter: fn(t, s) -> CutResult(t, s),
) -> #(List(t), List(t)) {
  case remaining {
    [] -> #(list.reverse(taken), [])
    [next, ..remaining] as all_remaining -> {
      case cutter(next, state) {
        Halt -> #(list.reverse(taken), all_remaining)
        Take(s) -> do_cut_list(remaining, [next, ..taken], s, cutter)
        TakeCut(remaining: remaining_element, taken: taken_element) -> {
          #(list.reverse([taken_element, ..taken]), [
            remaining_element,
            ..remaining
          ])
        }
      }
    }
  }
}

pub fn split_tail(elements: List(t)) -> Result(#(List(t), t), Nil) {
  case list.reverse(elements) {
    [last, ..rest] -> Ok(#(list.reverse(rest), last))
    [] -> Error(Nil)
  }
}

pub fn from_pair(pair: #(a, a)) -> List(a) {
  let #(first, second) = pair
  [first, second]
}

pub fn sub_list(elements: List(t), start start: Int, size size: Int) -> List(t) {
  elements
  |> list.drop(start)
  |> list.take(size)
}

pub fn is_prefix(elements: List(t), prefix prefix: List(t)) -> Bool {
  case elements, prefix {
    _, [] -> True
    [head, ..tail], [prefix_head, ..prefix_tail] if head == prefix_head ->
      is_prefix(tail, prefix_tail)
    _, _ -> False
  }
}

pub fn max_consecutive(elements: List(t), element: t) -> Int {
  do_max_consecutive(elements, element, 0, 0)
}

pub fn unwrap(elements: List(t)) -> Result(t, Nil) {
  case elements {
    [element] -> Ok(element)
    _ -> Error(Nil)
  }
}

pub fn min(
  elements: List(t),
  by comparer: fn(t, t) -> order.Order,
) -> Result(t, Nil) {
  elements
  |> list.reduce(fn(left, right) {
    case comparer(left, right) {
      order.Lt | order.Eq -> left
      order.Gt -> right
    }
  })
}

fn do_max_consecutive(
  elements: List(t),
  element: t,
  current_count: Int,
  max_count: Int,
) -> Int {
  case elements {
    [] -> int.max(current_count, max_count)
    [head, ..elements] if head == element -> {
      do_max_consecutive(elements, element, current_count + 1, max_count)
    }
    [_head, ..elements] -> {
      do_max_consecutive(
        elements,
        element,
        0,
        int.max(current_count, max_count),
      )
    }
  }
}
