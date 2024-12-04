import gleam/list

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

pub fn write_at(elements: List(t), idx: Int, element: t) -> List(t) {
  elements
  |> with_index()
  |> list.map(fn(pair) {
    let #(i, e) = pair

    case i == idx {
      True -> element
      False -> e
    }
  })
}
