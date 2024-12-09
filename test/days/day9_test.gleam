import gleam/list
import gleam/string
import gleeunit
import gleeunit/should

import shared/results

import days/day9.{
  type Chunks, File, FileData, Free, analyze_free_space, chunk_to_string,
  read_chunks_from_line,
}

pub fn main() {
  gleeunit.main()
}

const raw_test_disk = "2333133121414131402"

pub fn read_chunks_from_line_test() {
  let expected_disk = [
    File(FileData(2, 0)),
    Free(3),
    File(FileData(3, 1)),
    Free(3),
    File(FileData(1, 2)),
    Free(3),
    File(FileData(3, 3)),
    Free(1),
    File(FileData(2, 4)),
    Free(1),
    File(FileData(4, 5)),
    Free(1),
    File(FileData(4, 6)),
    Free(1),
    File(FileData(3, 7)),
    Free(1),
    File(FileData(4, 8)),
    File(FileData(2, 9)),
  ]

  should.equal(test_disk(), expected_disk)

  test_disk()
  |> list.map(chunk_to_string)
  |> string.join("")
  |> should.equal("00...111...2...333.44.5555.6666.777.888899")
}

pub fn analyze_free_space_test() {
  test_disk()
  |> analyze_free_space()
  |> should.equal(14)
}

fn test_disk() -> Chunks {
  raw_test_disk
  |> read_chunks_from_line()
  |> results.expect("Read raw test disk")
}
