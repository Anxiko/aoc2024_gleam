pub fn apply_pair(f: fn(a, b) -> c, pair: #(a, b)) -> c {
  let #(a, b) = pair
  f(a, b)
}
