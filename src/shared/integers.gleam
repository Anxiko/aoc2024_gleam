import gleam/int
import gleam/result

pub fn div_mod(dividend: Int, divisor: Int) -> Result(#(Int, Int), Nil) {
  use division <- result.try(int.divide(dividend, divisor))
  Ok(#(division, dividend % divisor))
}

pub fn int_div(dividend: Int, divisor: Int) -> Result(Int, Nil) {
  case div_mod(dividend, divisor) {
    Ok(#(result, 0)) -> Ok(result)
    _ -> Error(Nil)
  }
}
