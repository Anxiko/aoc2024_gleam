import gleam/option.{type Option, None, Some}

pub type Either(left, right) {
  Left(left)
  Right(right)
}

pub type ProblemPart {
  Part1
  Part2
}

pub fn part_to_int(problem_part: ProblemPart) -> Int {
  case problem_part {
    Part1 -> 1
    Part2 -> 2
  }
}

pub fn part_from_int(problem_part: Int) -> Option(ProblemPart) {
  case problem_part {
    1 -> Some(Part1)
    2 -> Some(Part2)
    _ -> None
  }
}
