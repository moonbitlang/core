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
/// A compiled regular expression for byte-oriented matching.
#internal(experimental, "subject to breaking change without notice")
pub struct BytesRegex {
  priv re : @re.Regex

  fn new(pattern : StringView) -> BytesRegex raise
}

///|
/// Result of one successful match produced by `BytesRegex::execute`.
#internal(experimental, "subject to breaking change without notice")
struct MatchResult {
  input : BytesView
  group_names : ReadOnlyArray[String?]
  result : @re.MatchResult
}

///|
/// Return match `before` view.
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::before(self : MatchResult) -> BytesView {
  guard self.result.group(0) is Some((start, _end)) else { panic() }
  self.input[0:start]
}

///|
/// Return match `after` view.
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::after(self : MatchResult) -> BytesView {
  guard self.result.group(0) is Some((_start, end)) else { panic() }
  self.input[end:self.input.length()]
}

///|
/// Return match `content` view.
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::content(self : MatchResult) -> BytesView {
  guard self.result.group(0) is Some((start, end)) else { panic() }
  self.input[start:end]
}

///|
/// Access capture `group` information.
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::group(self : MatchResult, group_index : Int) -> BytesView? {
  match self.result.group(group_index) {
    None => None
    Some((start, end)) => Some(self.input[start:end])
  }
}

///|
/// Access capture `named_group` information.
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::named_group(
  self : MatchResult,
  name : String,
) -> BytesView? {
  match self.group_names.search(Some(name)) {
    None => None
    Some(index) => self.group(index)
  }
}

///|
/// Compile a pattern into an internal regex representation.
/// DO NOT call this function even in this package.
#internal(experimental, "subject to breaking change without notice")
#doc(hidden)
pub fn BytesRegex::internal_compile_pattern(pat : @re.Pattern) -> BytesRegex {
  { re: @re.compile(profile=re_profile, pat) }
}

///|
/// Compiles a regex pattern string into a `BytesRegex` object.
///
/// The regex syntax follows MoonBit `lexmatch` regex literals.
/// The following constructs are recognized:
///
/// - `.` wildcard (matches any byte, including newline)
/// - Character classes: `[abc]`, `[^abc]`, `[a-z]`, POSIX classes such as
///   `[[:digit:]]`, `[[:alpha:]]`, `[[:space:]]`, `[[:word:]]`
/// - Quantifiers: `*`, `+`, `?`, `{n}`, `{n,}`, `{n,m}` and non-greedy forms
///   `*?`, `+?`, `??`, `{n}?`, `{n,}?`, `{n,m}?`
/// - Grouping and alternation: `( ... )`, `(?: ... )` (non-capturing),
///   `(?<name> ... )`, `a|b`
/// - Assertions and modifiers: `^`, `$`, `\b`, `\B`, `(?i: ... )`
///
/// Escape sequences include `\n`, `\r`, `\t`, `\f`, `\v`, `\xHH`, and
/// escaped metacharacters. `\uXXXX` and `\u{X...}` are not supported in
/// `BytesRegex::compile`.
///
/// `^` and `$` are non-multiline anchors: they match only the beginning and
/// end of the whole input, not per-line boundaries.
///
/// `\d`, `\D`, `\s`, `\S`, `\w`, and `\W` are not supported; use POSIX
/// character classes instead.
///
/// POSIX character classes are ASCII-based.
///
/// For full grammar and semantics, see:
/// <https://github.com/moonbitlang/lexmatch_spec>
/// 
/// Raises when `pattern` is not a valid regex pattern.
/// 
/// Example:
/// 
/// ```mbt check
/// test {
///   let regex = @bytes.BytesRegex("[[:digit:]]+")
///   guard regex.execute(b"a12b") is Some(m) else { fail("Expected match") }
///   inspect(m.content(), content="b\"12\"")
/// }
/// ```
#internal(experimental, "subject to breaking change without notice")
pub fn BytesRegex::new(pattern : StringView) -> BytesRegex raise {
  let pat = @regex_syntax.parse(profile=re_profile, pattern, mode=Bytes)
  { re: @re.compile(profile=re_profile, pat) }
}

///|
/// Executes this regex on `input` and returns the first match found.
///
/// Search starts at `last_index` (default `0`). The returned match, when
/// present, starts at or after that index.
///
/// `last_index` must satisfy `0 <= last_index <= input.length()`.
///
/// `last_index` only controls where searching starts. It does **not** change
/// anchor semantics:
///
/// - `^` still matches only the beginning of `input`
/// - `$` still matches only the end of `input`
///
/// This parameter is needed by iterative operations such as
/// `Regex::find`, `Regex::replace_by`, and `Regex::split`, which repeatedly
/// resume searching from the end of the previous match while keeping anchor
/// behavior relative to the full `input`.
///
/// Returns `None` when there is no match from `last_index` to the end of
/// `input`.
///
/// Example:
///
/// ```mbt check
/// test {
///   let regex = @bytes.BytesRegex("[[:digit:]]+")
///   let input = b"a12b34"
///
///   guard regex.execute(input) is Some(first) else {
///     fail("Expected first match")
///   }
///   inspect(
///     first.content(),
///     content=(
///       #|b"12"
///     ),
///   )
///
///   let next = first.before().length() + first.content().length()
///   guard regex.execute(input, last_index=next) is Some(second) else {
///     fail("Expected second match")
///   }
///   inspect(
///     second.content(),
///     content=(
///       #|b"34"
///     ),
///   )
/// }
/// ```
/// 
/// ```mbt check
/// test {
///   let anchored = @bytes.BytesRegex("^ab$")
///   inspect(anchored.execute("ab", last_index=0) is Some(_), content="true")
///   inspect(anchored.execute("xaby", last_index=1) is Some(_), content="false")
/// }
/// ```
#internal(experimental, "subject to breaking change without notice")
pub fn BytesRegex::execute(
  self : BytesRegex,
  input : BytesView,
  last_index? : Int = 0,
) -> MatchResult? {
  match self.re.execute(input, last_index) {
    None => None
    Some(result) =>
      Some(MatchResult::{ input, group_names: self.re.group_names(), result })
  }
}
