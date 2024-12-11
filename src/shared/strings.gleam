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
