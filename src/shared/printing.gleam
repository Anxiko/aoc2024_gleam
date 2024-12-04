import gleam/io
import gleam/string

pub fn inspect(value: t, label: String) -> t {
  io.println(label <> ": " <> string.inspect(value))
  value
}
