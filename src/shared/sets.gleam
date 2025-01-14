import gleam/list
import gleam/set.{type Set}
import gleam/string

pub fn pop(s: Set(a)) -> Result(#(a, Set(a)), Nil) {
  case set.to_list(s) {
    [head, ..tail] -> {
      Ok(#(head, set.from_list(tail)))
    }
    [] -> Error(Nil)
  }
}

pub fn single(a) -> Set(a) {
  set.from_list([a])
}

pub fn any(elements: Set(a), satisfies: fn(a) -> Bool) -> Bool {
  elements
  |> set.to_list()
  |> list.any(satisfies)
}

pub fn to_string(set: Set(a), with formatter: fn(a) -> String) -> String {
  let contents =
    set
    |> set.to_list()
    |> list.map(formatter)
    |> string.join(", ")

  "{" <> contents <> "}"
}
