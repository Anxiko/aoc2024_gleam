import gleam/option.{type Option, None, Some}

pub fn parse_bool(raw_bool) -> Option(Bool) {
  case raw_bool {
    "y" | "Y" | "yes" | "Yes" | "t" | "T" | "true" | "True" -> Some(True)
    "n" | "N" | "no" | "No" | "f" | "F" | "false" | "False" -> Some(False)
    _ -> None
  }
}
