import gleam/set.{type Set}

pub fn pop(s: Set(a)) -> Result(#(a, Set(a)), Nil) {
  case set.to_list(s) {
    [head, ..tail] -> {
      Ok(#(head, set.from_list(tail)))
    }
    [] -> Error(Nil)
  }
}
