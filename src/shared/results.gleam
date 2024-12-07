import gleam/string

pub fn expect(result: Result(t, e), msg msg: String) -> t {
  case result {
    Ok(t) -> t
    Error(e) -> {
      panic as string.concat([
        "Attempted to extract value from result in error: ",
        msg,
        ", error:",
        string.inspect(e),
      ])
    }
  }
}

pub fn assert_unwrap(result: Result(t, e)) -> t {
  case result {
    Ok(t) -> t
    Error(e) -> {
      panic as string.concat([
        "Attempted to extract value from result in error, error:",
        string.inspect(e),
      ])
    }
  }
}
