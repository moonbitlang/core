// Copyright 2026 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

///|
/// Errors raised during parsing or decoding of arguments.
pub(all) suberror ArgParseError {
  UnknownArgument(String, String?)
  InvalidArgument(String)
  MissingValue(String)
  MissingRequired(String)
  TooFewValues(String, Int, Int)
  TooManyValues(String, Int, Int)
  TooManyPositionals
  InvalidValue(String)
  MissingGroup(String)
  GroupConflict(String)
}

///|
pub impl Show for ArgParseError with output(self : ArgParseError, logger) {
  logger.write_string(self.arg_parse_error_message())
}

///|
fn ArgParseError::arg_parse_error_message(self : ArgParseError) -> String {
  match self {
    ArgParseError::UnknownArgument(arg, Some(hint)) =>
      (
        $|error: unexpected argument '\{arg}' found
        $|
        $|  tip: a similar argument exists: '\{hint}'
      )
    ArgParseError::UnknownArgument(arg, None) =>
      "error: unexpected argument '\{arg}' found"
    ArgParseError::InvalidArgument(arg) =>
      if arg.has_prefix("-") {
        "error: unexpected argument '\{arg}' found"
      } else {
        "error: \{arg}"
      }
    ArgParseError::MissingValue(arg) =>
      "error: a value is required for '\{arg}' but none was supplied"
    ArgParseError::MissingRequired(name) =>
      "error: the following required argument was not provided: '\{name}'"
    ArgParseError::TooFewValues(name, got, min) =>
      "error: '\{name}' requires at least \{min} values but only \{got} were provided"
    ArgParseError::TooManyValues(name, got, max) =>
      "error: '\{name}' allows at most \{max} values but \{got} were provided"
    ArgParseError::TooManyPositionals =>
      "error: too many positional arguments were provided"
    ArgParseError::InvalidValue(msg) => "error: \{msg}"
    ArgParseError::MissingGroup(name) =>
      "error: the following required argument group was not provided: '\{name}'"
    ArgParseError::GroupConflict(name) => "error: group conflict \{name}"
  }
}

///|
/// Errors raised when building argument specifications.
pub suberror ArgBuildError {
  Unsupported(String)
} derive(Show)

///|
/// Errors raised when help information is requested.
pub suberror DisplayHelp {
  Message(String)
} derive(Show)

///|
/// Errors raised when version information is requested.
pub suberror DisplayVersion {
  Message(String)
} derive(Show)
