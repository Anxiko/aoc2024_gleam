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
