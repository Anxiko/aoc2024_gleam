import gleam/option.{None, Some}
import gleeunit
import gleeunit/should

import days/day2.{
  Ascending, Descending, Safe, Unsafe, analyze_delta, do_analyze_report,
}

pub fn main() {
  gleeunit.main()
}

pub fn analyze_delta_test() {
  should.be_error(analyze_delta(1, 1))

  should.equal(analyze_delta(1, 2), Ok(day2.Ascending))
  should.equal(analyze_delta(1, 4), Ok(day2.Ascending))

  should.be_error(analyze_delta(1, 5))

  should.equal(analyze_delta(2, 1), Ok(day2.Descending))
  should.equal(analyze_delta(4, 1), Ok(day2.Descending))
}

pub fn do_analyze_report_test() {
  // Base case
  should.be_error(do_analyze_report(0, 0, [], None))
  should.equal(
    do_analyze_report(0, 1, [], Some(Ascending)),
    Ok(Safe(Ascending)),
  )

  // Unknown direction, correctly inferred
  should.equal(do_analyze_report(1, 0, [2], None), Ok(Safe(Ascending)))
  should.equal(do_analyze_report(2, 0, [1], None), Ok(Safe(Descending)))

  // Unknown direction, invalid inferred
  should.equal(do_analyze_report(1, 0, [5], None), Ok(Unsafe(0)))
  should.equal(do_analyze_report(5, 0, [1], None), Ok(Unsafe(0)))
  should.equal(do_analyze_report(0, 0, [0], None), Ok(Unsafe(0)))

  // Known direction respected
  should.equal(
    do_analyze_report(1, 1, [2], Some(Ascending)),
    Ok(Safe(Ascending)),
  )
  should.equal(
    do_analyze_report(2, 1, [1], Some(Descending)),
    Ok(Safe(Descending)),
  )

  // Known direction, contradicted
  should.equal(do_analyze_report(1, 1, [0], Some(Ascending)), Ok(Unsafe(1)))
  should.equal(do_analyze_report(1, 1, [2], Some(Descending)), Ok(Unsafe(1)))
  should.equal(do_analyze_report(0, 1, [0], Some(Ascending)), Ok(Unsafe(1)))

  // Known direction, exceeded
  should.equal(do_analyze_report(1, 1, [5], Some(Ascending)), Ok(Unsafe(1)))
  should.equal(do_analyze_report(5, 1, [1], Some(Descending)), Ok(Unsafe(1)))
}
