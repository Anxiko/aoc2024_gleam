import gleam/list
import gleeunit
import gleeunit/should

import shared/lists.{delete_at}

const list = [3, 5, 2, 0, 4, 7, 5]

pub fn main() {
  gleeunit.main()
}

pub fn delete_at_test() {
  [
    #(0, [5, 2, 0, 4, 7, 5]),
    #(1, [3, 2, 0, 4, 7, 5]),
    #(3, [3, 5, 2, 4, 7, 5]),
    #(6, [3, 5, 2, 0, 4, 7]),
    #(7, [3, 5, 2, 0, 4, 7, 5]),
  ]
  |> list.each(fn(tuple) {
    let #(idx, expected) = tuple
    should.equal(delete_at(list, idx), expected)
  })
}
