import gleam/result
import gleam/yielder.{type Yielder}

pub type SearchResult(t) {
  Found(t)
  Continue
  Halt
}

pub fn search_while(
  elements: Yielder(t),
  checker: fn(t) -> SearchResult(f),
) -> Result(f, Nil) {
  use #(next, elements) <- result.try(get_next(elements))
  case checker(next) {
    Found(found) -> Ok(found)
    Continue -> search_while(elements, checker)
    Halt -> Error(Nil)
  }
}

pub fn get_next(elements: Yielder(t)) -> Result(#(t, Yielder(t)), Nil) {
  case yielder.step(elements) {
    yielder.Next(element:, accumulator:) -> Ok(#(element, accumulator))
    yielder.Done -> Error(Nil)
  }
}
