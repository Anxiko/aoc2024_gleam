pub fn apply_pair(f: fn(a, b) -> c, pair: #(a, b)) -> c {
  let #(a, b) = pair
  f(a, b)
}

pub fn evolve(value: t, times: Int, next: fn(t) -> t) -> t {
  case times {
    0 -> value
    times if times > 0 -> evolve(next(value), times - 1, next)
    _neg -> panic as "Negative amount of iterations!"
  }
}

pub fn evolve_until(value: t, next next: fn(t) -> Result(t, Nil)) -> t {
  case next(value) {
    Ok(value) -> evolve_until(value, next)
    Error(Nil) -> value
  }
}