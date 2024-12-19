import gleam/pair

pub fn map_both(pair: #(a, a), f f: fn(a) -> b) -> #(b, b) {
  pair
  |> pair.map_first(f)
  |> pair.map_second(f)
}

pub fn from_list(list: List(t)) -> Result(#(t, t), Nil) {
  case list {
    [left, right] -> #(left, right) |> Ok()
    _ -> Error(Nil)
  }
}
