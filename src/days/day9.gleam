import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder.{type Yielder, Next}

import shared/functions
import shared/lists.{type CutResult, Halt, Take, TakeCut, cut_list}
import shared/parsers
import shared/results
import shared/types.{type ProblemPart, Part1, Part2}

type Reader {
  Reader(next_id: Int, file_next: Bool, chunks: List(DiskChunk))
}

pub type FileData {
  FileData(size: Int, id: Int)
}

pub type DiskChunk {
  File(FileData)
  Free(size: Int)
}

pub type Chunks =
  List(DiskChunk)

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let assert Ok(input) = read_input(input_path)
  case part {
    Part1 -> {
      let free_space = analyze_free_space(input)
      let #(remaining, selected) = select_defrag(input, free_space)
      let total_selected = disk_size(selected)

      let disk = list.append(remaining, [Free(size: total_selected)])
      let selected_file_data =
        list.filter_map(selected, fn(chunk) {
          case chunk {
            File(file_data) -> Ok(file_data)
            _ -> Error(Nil)
          }
        })

      disk
      |> insert_selected(selected_file_data)
      |> checksum()
      |> int.to_string()
    }
    Part2 -> {
      input
      |> defrag_whole_files()
      |> checksum()
      |> int.to_string()
    }
  }
}

fn read_input(input_file: String) -> Result(Chunks, Nil) {
  use line <- result.try(parsers.read_single_line(input_file))
  read_chunks_from_line(line)
}

pub fn read_chunks_from_line(line: String) -> Result(Chunks, Nil) {
  let digits =
    line
    |> string.to_graphemes()
    |> list.try_map(int.parse)
  use digits <- result.map(digits)
  let reader = list.fold(digits, new_reader(), add_chunk_to_reader)
  list.reverse(reader.chunks)
}

fn new_reader() -> Reader {
  Reader(next_id: 0, file_next: True, chunks: [])
}

fn add_chunk_to_reader(reader: Reader, chunk_size: Int) -> Reader {
  case reader {
    Reader(file_next: True, next_id: next_id, ..) as reader if chunk_size == 0 ->
      Reader(..reader, file_next: False, next_id: next_id + 1)
    Reader(file_next: False, ..) as reader if chunk_size == 0 ->
      Reader(..reader, file_next: True)
    Reader(file_next: True, next_id: next_id, chunks: chunks) -> {
      let chunk = File(FileData(size: chunk_size, id: next_id))
      Reader(file_next: False, next_id: next_id + 1, chunks: [chunk, ..chunks])
    }
    Reader(chunks: chunks, ..) -> {
      let chunk = Free(chunk_size)
      Reader(..reader, file_next: True, chunks: [chunk, ..chunks])
    }
  }
}

fn chunk_cutter(chunk: DiskChunk, target: Int) -> CutResult(DiskChunk, Int) {
  case chunk, target {
    _, 0 -> Halt
    Free(size: size), _ if target >= size -> Take(target - size)
    Free(size: size), _ ->
      TakeCut(taken: Free(target), remaining: Free(size - target))
    File(FileData(size: size, ..)), target if target >= size ->
      Take(target - size)
    File(FileData(size: size, ..) as file_data), target -> {
      let taken = File(FileData(..file_data, size: target))
      let remaining = File(FileData(..file_data, size: size - target))
      TakeCut(taken:, remaining:)
    }
  }
}

fn select_defrag(chunks: Chunks, target: Int) -> #(Chunks, Chunks) {
  let #(taken, disk) =
    chunks
    |> list.reverse()
    |> cut_list(target, chunk_cutter)

  #(list.reverse(disk), taken)
}

fn insert_selected(disk: Chunks, selected: List(FileData)) -> Chunks {
  do_insert_selected(disk, selected, [])
}

fn do_insert_selected(
  disk: Chunks,
  selected: List(FileData),
  acc: Chunks,
) -> Chunks {
  case disk, selected {
    _, [] -> list.append(list.reverse(acc), disk)
    [], _ -> panic as "Run out of disk space inserting selected chunks!"
    [Free(size: free_size), ..disk],
      [FileData(size: file_size, ..) as file_data, ..selected]
      if free_size > file_size
    -> {
      do_insert_selected([Free(size: free_size - file_size), ..disk], selected, [
        File(file_data),
        ..acc
      ])
    }
    [Free(size: free_size), ..disk],
      [FileData(size: file_size, ..) as file_data, ..selected]
      if free_size < file_size
    -> {
      do_insert_selected(
        disk,
        [FileData(..file_data, size: file_size - free_size), ..selected],
        [File(FileData(..file_data, size: free_size)), ..acc],
      )
    }
    [Free(..), ..disk], [FileData(..) as file_data, ..selected] -> {
      do_insert_selected(disk, selected, [File(file_data), ..acc])
    }
    [File(..) as file, ..disk], selected ->
      do_insert_selected(disk, selected, [file, ..acc])
  }
}

pub fn analyze_free_space(chunks: Chunks) -> Int {
  chunks
  |> list.filter_map(fn(chunk) {
    case chunk {
      Free(size: size) -> Ok(size)
      _ -> Error(Nil)
    }
  })
  |> int.sum()
}

fn checksum(chunks: Chunks) -> Int {
  chunks
  |> yielder.from_list()
  |> yielder.transform(0, fn(idx, chunk) {
    let #(pairs, next_idx) = chunk_yielder(chunk, idx)
    Next(pairs, next_idx)
  })
  |> yielder.flatten()
  |> yielder.map(functions.apply_pair(int.multiply, _))
  |> yielder.reduce(int.add)
  |> results.assert_unwrap()
}

fn chunk_yielder(chunk: DiskChunk, start: Int) -> #(Yielder(#(Int, Int)), Int) {
  case chunk {
    File(FileData(size: size, id: id)) -> {
      let pairs =
        start
        |> yielder.range(start + size - 1)
        |> yielder.map(fn(idx) { #(idx, id) })

      #(pairs, start + size)
    }
    Free(size: size) -> {
      #(yielder.empty(), start + size)
    }
  }
}

pub fn chunk_to_string(chunk: DiskChunk) -> String {
  let #(char, times) = case chunk {
    File(FileData(size: size, id: id)) -> {
      #(int.to_string(id), size)
    }
    Free(size: size) -> {
      #(".", size)
    }
  }

  string.repeat(char, times)
}

fn disk_size(chunks: Chunks) -> Int {
  chunks
  |> list.map(fn(chunk) {
    case chunk {
      Free(size: size) -> size
      File(FileData(size: size, ..)) -> size
    }
  })
  |> int.sum()
}

fn write_file(chunks: Chunks, file_data: FileData) -> Result(Chunks, Nil) {
  do_write_file(chunks, [], file_data)
}

fn do_write_file(
  chunks: Chunks,
  acc: Chunks,
  file_data: FileData,
) -> Result(Chunks, Nil) {
  case chunks {
    [] -> Error(Nil)
    [Free(size: free), ..rest] if free > file_data.size -> {
      let acc = [Free(free - file_data.size), File(file_data), ..acc]
      Ok(list.append(list.reverse(acc), rest))
    }
    [Free(size: free), ..rest] if free == file_data.size -> {
      let acc = [File(file_data), ..acc]
      Ok(list.append(list.reverse(acc), rest))
    }
    [next, ..rest] -> do_write_file(rest, [next, ..acc], file_data)
  }
}

fn defrag_whole_files(chunks: Chunks) -> Chunks {
  chunks
  |> do_defrag_whole_files([])
}

fn do_defrag_whole_files(chunks: Chunks, acc: Chunks) -> Chunks {
  case lists.split_tail(chunks) {
    Error(Nil) -> acc
    Ok(#(rest, Free(..) as chunk)) ->
      do_defrag_whole_files(rest, [chunk, ..acc])
    Ok(#(rest, File(file_data) as file)) -> {
      case write_file(rest, file_data) {
        Ok(written_rest) -> {
          do_defrag_whole_files(written_rest, [Free(file_data.size), ..acc])
        }
        Error(Nil) -> {
          do_defrag_whole_files(rest, [file, ..acc])
        }
      }
    }
  }
}
