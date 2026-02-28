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
/// Unified error surface exposed by argparse.
pub suberror ArgError {
  Message(String)
}

///|
pub impl Show for ArgError with output(self : ArgError, logger) {
  match self {
    Message(msg) => logger.write_string(msg)
  }
}

///|
/// Internal parse error variants used while parsing.
priv suberror ArgParseError {
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
fn ArgParseError::arg_parse_error_message(self : ArgParseError) -> String {
  match self {
    UnknownArgument(arg, Some(hint)) =>
      (
        $|error: unexpected argument '\{arg}' found
        $|
        $|  tip: a similar argument exists: '\{hint}'
      )
    UnknownArgument(arg, None) => "error: unexpected argument '\{arg}' found"
    InvalidArgument(arg) =>
      if arg.has_prefix("-") {
        "error: unexpected argument '\{arg}' found"
      } else {
        "error: \{arg}"
      }
    MissingValue(arg) =>
      "error: a value is required for '\{arg}' but none was supplied"
    MissingRequired(name) =>
      "error: the following required argument was not provided: '\{name}'"
    TooFewValues(name, got, min) =>
      "error: '\{name}' requires at least \{min} values but only \{got} were provided"
    TooManyValues(name, got, max) =>
      "error: '\{name}' allows at most \{max} values but \{got} were provided"
    TooManyPositionals => "error: too many positional arguments were provided"
    InvalidValue(msg) => "error: \{msg}"
    MissingGroup(name) =>
      "error: the following required argument group was not provided: '\{name}'"
    GroupConflict(name) => "error: group conflict \{name}"
  }
}

///|
/// Internal build errors raised while validating command definitions.
priv suberror ArgBuildError {
  Unsupported(String)
}

///|
fn ArgBuildError::arg_build_error_message(self : ArgBuildError) -> String {
  match self {
    Unsupported(msg) => "error: \{msg}"
  }
}

///|
/// Internal control-flow event for displaying help.
priv suberror DisplayHelp {
  Message(String)
}

///|
/// Internal control-flow event for displaying version text.
priv suberror DisplayVersion {
  Message(String)
}
