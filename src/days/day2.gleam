import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import simplifile

import shared/lists
import shared/parsers
import shared/types.{type ProblemPart, Part1, Part2}

pub type Report =
  List(Int)

type Input =
  List(Report)

pub type SafeReportType {
  Ascending
  Descending
}

pub type ReportStatus {
  Safe(SafeReportType)
  Unsafe(Int)
}

pub fn solve(part: ProblemPart, input_path: String) -> String {
  let input = read_input(input_path)
  let allow_skipping = case part {
    Part1 -> False
    Part2 -> True
  }

  input
  |> list.count(is_safe(_, allow_skipping))
  |> int.to_string()
}

fn is_safe(report: Report, skipping: Bool) -> Bool {
  case analyze_report(report), skipping {
    Safe(_), _ -> True
    Unsafe(_), False -> False
    Unsafe(idx), True ->
      report |> altered_reports(idx) |> list.any(is_safe(_, False))
  }
}

fn altered_reports(report: Report, idx: Int) -> List(Report) {
  let indices = [idx, idx + 1]
  case idx {
    positive if positive > 0 -> [idx - 1, ..indices]
    _ -> indices
  }
  |> list.map(lists.delete_at(report, _))
}

fn analyze_report(report: Report) -> ReportStatus {
  case report {
    [first, ..rest] -> {
      let assert Ok(analysis) = do_analyze_report(first, 0, rest, None)
      analysis
    }
    [] -> panic as "Can't analyze an empty report!"
  }
}

pub fn do_analyze_report(
  last_number: Int,
  last_number_idx: Int,
  report: Report,
  current_status: Option(SafeReportType),
) -> Result(ReportStatus, Nil) {
  case report, current_status {
    [], Some(safe_report) -> Ok(Safe(safe_report))
    [], None -> Error(Nil)
    [next_number, ..rest], current_status -> {
      let delta_report = analyze_delta(last_number, next_number)
      case current_status, delta_report {
        None, Ok(delta_report) ->
          do_analyze_report(
            next_number,
            last_number_idx + 1,
            rest,
            Some(delta_report),
          )
        Some(current_status), Ok(delta_report)
          if current_status == delta_report
        ->
          do_analyze_report(
            next_number,
            last_number_idx + 1,
            rest,
            Some(current_status),
          )

        _, _ -> Ok(Unsafe(last_number_idx))
      }
    }
  }
}

pub fn analyze_delta(previous: Int, next: Int) -> Result(SafeReportType, Nil) {
  let difference = next - previous
  case difference {
    valid_increase if 1 <= valid_increase && valid_increase <= 3 ->
      Ok(Ascending)
    valid_decrease if -3 <= valid_decrease && valid_decrease <= -1 ->
      Ok(Descending)
    _ -> Error(Nil)
  }
}

fn read_input(input_path: String) -> Input {
  let assert Ok(file_contents) = simplifile.read(input_path)

  file_contents
  |> string.split("\n")
  |> list.filter(fn(s) { !string.is_empty(s) })
  |> list.map(parsers.parse_sequence(_, parsers.unsafe_parse_int))
}
