import gleam/dict.{type Dict}
import gleam/list
import gleam/option
import gleam/set.{type Set}

pub fn single(key key: k, value value: v) -> Dict(k, v) {
  dict.from_list([#(key, value)])
}

pub fn freq(numbers: List(a)) -> Dict(a, Int) {
  numbers
  |> list.fold(from: dict.new(), with: increment_freq)
}

fn increment_freq(d: Dict(a, Int), element: a) -> Dict(a, Int) {
  dict.upsert(d, element, with: fn(maybe_freq) {
    option.unwrap(maybe_freq, 0) + 1
  })
}

pub fn dict_many(entries: List(#(k, v))) -> Dict(k, Set(v)) {
  entries
  |> list.fold(from: dict.new(), with: fn(d, entry) {
    let #(key, value) = entry
    dict.upsert(d, key, with: fn(maybe_set) {
      maybe_set
      |> option.lazy_unwrap(set.new)
      |> set.insert(value)
    })
  })
}
