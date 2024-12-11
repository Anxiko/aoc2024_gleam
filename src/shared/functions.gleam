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
