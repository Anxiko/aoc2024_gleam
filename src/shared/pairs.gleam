import gleam/pair

pub fn map_both(pair: #(a, a), f f: fn(a) -> b) -> #(b, b) {
  pair
  |> pair.map_first(f)
  |> pair.map_second(f)
}
