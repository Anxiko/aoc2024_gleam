import gleam/string

pub fn split_half(s: String) -> Result(#(String, String), Nil) {
  let length = string.length(s)
  case length / 2, length % 2 {
    half, 0 -> {
      let left = string.drop_end(s, half)
      let right = string.drop_start(s, half)
      Ok(#(left, right))
    }
    _, _ -> Error(Nil)
  }
}

pub fn try_remove_prefix(
  string string: String,
  prefix prefix: String,
) -> Result(String, Nil) {
  case string.split_once(string, prefix) {
    Ok(#("", without_prefix)) -> Ok(without_prefix)
    _ -> Error(Nil)
  }
}
