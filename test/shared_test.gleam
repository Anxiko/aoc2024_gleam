import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import shared/strings

import shared/expected.{Parts, decode_expected_output, read_expected}
import shared/lists.{delete_at, split_many}

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

const first_part = "
{
  \"part1\": \"10\"
}
"

const second_part = "
{
  \"part2\": \"4\"
}
"

const both_parts = "
{
  \"part1\": \"10\",
  \"part2\": \"4\"
}
"

const empty = "{}"

pub fn decode_expected_output_test() {
  should.equal(decode_expected_output(first_part), Ok(Parts(Some("10"), None)))
  should.equal(decode_expected_output(second_part), Ok(Parts(None, Some("4"))))
  should.equal(
    decode_expected_output(both_parts),
    Ok(Parts(Some("10"), Some("4"))),
  )
  should.equal(decode_expected_output(empty), Ok(Parts(None, None)))
  should.be_error(decode_expected_output(""))
}

pub fn read_expected_test() {
  should.equal(read_expected(0, True), Some(Parts(Some("0"), None)))
  should.equal(read_expected(0, False), Some(Parts(Some("1"), Some("2"))))
}

pub fn split_many_test() {
  should.equal(
    split_many(
      [1, 2, 3, 0, 4, 5, 6, 0],
      by: fn(e) { e == 0 },
      discard_splitter: True,
    ),
    [[1, 2, 3], [4, 5, 6], []],
  )

  should.equal(
    split_many(
      [1, 2, 3, 0, 4, 5, 6, 0],
      by: fn(e) { e == 0 },
      discard_splitter: False,
    ),
    [[1, 2, 3], [0, 4, 5, 6], [0]],
  )

  should.equal(
    split_many([], by: fn(e) { e == 0 }, discard_splitter: False),
    [],
  )

  should.equal(split_many([0], by: fn(e) { e == 0 }, discard_splitter: False), [
    [0],
  ])
}

pub fn split_half_test() {
  "aabb" |> strings.split_half() |> should.equal(Ok(#("aa", "bb")))
  "" |> strings.split_half() |> should.equal(Ok(#("", "")))
  "aacbb" |> strings.split_half |> should.be_error()
  "1" |> strings.split_half |> should.be_error()
}
