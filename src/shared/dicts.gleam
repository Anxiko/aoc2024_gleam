import gleam/dict.{type Dict}
import gleam/list
import gleam/option

pub fn freq(numbers: List(a)) -> Dict(a, Int) {
  numbers
  |> list.fold(from: dict.new(), with: increment_freq)
}

fn increment_freq(d: Dict(a, Int), element: a) -> Dict(a, Int) {
  dict.upsert(d, element, with: fn(maybe_freq) {
    option.unwrap(maybe_freq, 0) + 1
  })
}
