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
/// Structured parse errors for the internal strconv helpers.
///
/// In-module callers (e.g. the JSON number lexer) match on the variants to
/// distinguish out-of-range values from syntax problems instead of comparing
/// failure message strings. The public wrappers in `moonbitlang/core/string`
/// translate these back into `Failure` with the historical message strings,
/// so externally observable behavior is unchanged.
pub(all) suberror StrConvError {
  RangeError
  SyntaxError
  InvalidBase
} derive(Eq, @debug.Debug)

///|
pub extend StrConvError with Eq::{equal, not_equal}

///|
pub extend StrConvError with @debug.Debug::{to_repr}

///|
/// The historical human-readable message for this error.
pub fn StrConvError::message(self : Self) -> String {
  match self {
    RangeError => "value out of range"
    SyntaxError => "invalid syntax"
    InvalidBase => "invalid base"
  }
}

///|
fn[T] range_err() -> T raise StrConvError {
  raise RangeError
}

///|
fn[T] syntax_err() -> T raise StrConvError {
  raise SyntaxError
}

///|
fn[T] base_err() -> T raise StrConvError {
  raise InvalidBase
}
