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
/// Type `Mode` used by this package APIs.
pub(all) enum Mode {
  Bytes
  String
}

///|
priv struct ParserContext {
  profile : @re.Profile
  base : Int
  ignore_case : Bool
  mode : Mode
  /// Names of the capture groups seen so far, shared by every copy of the
  /// context.
  group_names : Map[String, Unit]
  /// Number of groups open at the current position.
  depth : Int
}

///|
fn ParserContext::new(
  profile~ : @re.Profile,
  base~ : Int,
  mode~ : Mode,
) -> ParserContext {
  { profile, base, ignore_case: false, mode, group_names: {}, depth: 0, }
}

///|
/// Whether an escape may name code point `c`. Half of a surrogate pair is a
/// code point that no well-formed string contains: it matches nothing, but
/// it can be the end of a range, as in `[\u0000-\uDFFF]`.
fn ParserContext::escape_in_range(self : ParserContext, c : Int) -> Bool {
  self.profile.valid.contains(c) ||
  (self.mode is String && c >= 0xD800 && c <= 0xDFFF)
}

///|
fn ParserContext::error_at(
  self : ParserContext,
  view : StringView,
  hint : String,
  offset? : Int = 0,
) -> ParserError {
  ParserError(at=view.start_offset() - self.base + offset, hint~)
}
