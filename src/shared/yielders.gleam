import gleam/int
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

pub fn product(
  first_yielder: Yielder(a),
  second_yielder: Yielder(b),
) -> Yielder(#(a, b)) {
  use first <- yielder.flat_map(first_yielder)
  use second <- yielder.map(second_yielder)
  #(first, second)
}

pub fn tap(elements: Yielder(a), with tapper: fn(a) -> Nil) -> Yielder(a) {
  yielder.map(elements, with: fn(e) {
    tapper(e)
    e
  })
}

pub fn count(start start: Int) -> Yielder(Int) {
  yielder.iterate(start, int.add(_, 1))
}
