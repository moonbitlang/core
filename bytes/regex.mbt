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
/// A compiled regular expression over bytes: the `Bytes` counterpart of
/// `@string.Regex`, with its own byte-specialized parser and engine.
pub struct BytesRegex {
  priv pat : @re.Pattern
  priv mut re : @re.Regex?
}

///|
/// Compiles a regex pattern string into a `BytesRegex`.
///
/// The syntax is that of `@string.Regex`, read over bytes:
///
/// - An atom is one byte, and `.` matches any byte, including newline.
/// - `\xHH` is the byte `0xHH`; it may appear in character classes and
///   ranges, as in `[\x80-\xff]`.
/// - The pattern itself is ASCII: a non-ASCII character, `\uXXXX` and
///   `\u{X...}` are errors. Write a byte above `0x7F` as `\xHH`.
/// - `(?i: ... )`, `\b`, `\B` and the POSIX classes such as `[[:alpha:]]`
///   only know ASCII. Every byte above `0x7F` is a non-word byte.
/// - Negated classes such as `[^a]` match every other byte, including bytes
///   above `0x7F`.
///
/// Everything else, from quantifiers and groups to anchors and error
/// positions, is as in `@string.Regex`. Positions are byte offsets.
///
/// Raises when `pattern` is not a valid bytes regex pattern.
///
/// Example:
///
/// ```mbt check
/// test {
///   let regex = @bytes.BytesRegex("\\xff+(?<rest>[[:digit:]]+)")
///   guard regex.execute(b"a\xff\xff42") is Some(m) else { fail("Expected match") }
///   inspect(m.content(), content="b\"\\xff\\xff42\"")
///   inspect(m.named_group("rest").unwrap(), content="b\"42\"")
/// }
/// ```
pub fn BytesRegex::BytesRegex(pattern : StringView) -> BytesRegex raise {
  let pat = @regex_parser.parse(pattern)
  { pat, re: None, }
}

///|
pub impl @debug.Debug for BytesRegex with fn to_repr(self) {
  @debug.Repr::opaque_("BytesRegex", Repr(self.pat))
}

///|
/// Result of one successful match produced by `BytesRegex::execute`.
struct MatchResult {
  input : BytesView
  group_names : ReadOnlyArray[String?]
  result : @re.MatchResult
} derive(@debug.Debug)

///|
/// Return match `before` view.
pub fn MatchResult::before(self : MatchResult) -> BytesView {
  guard self.result.group(0) is Some((start, _end)) else { panic() }
  self.input[:start]
}

///|
/// Return match `after` view.
pub fn MatchResult::after(self : MatchResult) -> BytesView {
  guard self.result.group(0) is Some((_start, end)) else { panic() }
  self.input[end:]
}

///|
/// Return match `content` view.
pub fn MatchResult::content(self : MatchResult) -> BytesView {
  guard self.result.group(0) is Some((start, end)) else { panic() }
  self.input[start:end]
}

///|
/// Returns a capture group; group `0` is the entire match.
/// Returns `None` for an out-of-range index or a group that did not participate.
pub fn MatchResult::group(
  self : MatchResult,
  group_index : Int32,
) -> BytesView? {
  match self.result.group(group_index) {
    None => None
    Some((start, end)) => Some(self.input[start:end])
  }
}

///|
/// Access capture `named_group` information.
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
/// The value of a `reb"..."` literal: the compiler checks the pattern at
/// compile time and builds the regex at run time with this function.
///
/// DO NOT call this function even in this package.
#internal(internal, "not intended for public use")
#doc(hidden)
pub fn BytesRegex::internal_from_string(pat : String) -> BytesRegex {
  try! BytesRegex(pat)
}

///|
/// Concatenates two regexes in sequence.
///
/// Example:
///
/// ```mbt check
/// test {
///   let regex = @bytes.BytesRegex("ab") + BytesRegex("\\xff")
///   guard regex.execute(b"xab\xff") is Some(m) else { fail("Expected match") }
///   inspect(m.content(), content="b\"ab\\xff\"")
/// }
/// ```
#intrinsic("%regex.seq")
pub impl Add for BytesRegex with fn add(self, other) -> BytesRegex {
  { pat: @re.seq([self.pat, other.pat]), re: None, }
}

///|
/// Builds an alternation that matches either regex.
///
/// Example:
///
/// ```mbt check
/// test {
///   let regex = @bytes.BytesRegex("^GET$") | BytesRegex("^POST$")
///   inspect(regex.execute(b"POST") is Some(_), content="true")
///   inspect(regex.execute(b"PUT") is Some(_), content="false")
/// }
/// ```
#intrinsic("%regex.alt")
pub impl BitOr for BytesRegex with fn lor(self, other) -> BytesRegex {
  { pat: @re.alt([self.pat, other.pat]), re: None, }
}

///|
fn BytesRegex::re(self : BytesRegex) -> @re.Regex {
  match self.re {
    Some(re) => re
    None => {
      let re = @re.compile(self.pat)
      self.re = Some(re)
      re
    }
  }
}

///|
/// Search `input` for the leftmost-first match, as `@string.Regex::execute`
/// does for strings.
///
/// Search starts at `last_index` (default `0`), a byte offset that must
/// satisfy `0 <= last_index <= input.length()`. The returned match, when
/// present, starts at or after that index.
///
/// `last_index` only controls where searching starts. It does **not** change
/// anchor semantics: `^` still matches only the beginning of `input` and `$`
/// only its end, and `\b` looks at the byte before `last_index`.
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
///   guard regex.execute(input) is Some(first) else {
///     fail("Expected first match")
///   }
///   inspect(first.content(), content="b\"12\"")
///   let next = first.before().length() + first.content().length()
///   guard regex.execute(input, last_index=next) is Some(second) else {
///     fail("Expected second match")
///   }
///   inspect(second.content(), content="b\"34\"")
///   let anchored = @bytes.BytesRegex("^ab$")
///   inspect(anchored.execute(b"xaby", last_index=1) is Some(_), content="false")
/// }
/// ```
pub fn BytesRegex::execute(
  self : BytesRegex,
  input : BytesView,
  last_index~ : Int32 = 0,
) -> MatchResult? {
  let re = self.re()
  match re.execute(input, last_index) {
    None => None
    Some(result) => Some({ input, group_names: re.group_names(), result, })
  }
}
