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
/// A compiled regular expression for string-oriented matching.
#internal(experimental, "subject to breaking change without notice")
pub struct Regex {
  priv pat : @re.Pattern
  priv mut re : @re.Regex?

  fn new(pattern : StringView) -> Regex raise
}

///|
const MAX_REPEAT_QUANTIFIER = 256

///|
/// Result of one successful match produced by `Regex::execute`.
#internal(experimental, "subject to breaking change without notice")
struct MatchResult {
  input : StringView
  group_names : ReadOnlyArray[String?]
  result : @re.MatchResult
}

///|
/// Return match `before` view.
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::before(self : MatchResult) -> StringView {
  guard self.result.group(0) is Some((start, _end)) else { panic() }
  self.input[0:start]
}

///|
/// Return match `after` view.
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::after(self : MatchResult) -> StringView {
  guard self.result.group(0) is Some((_start, end)) else { panic() }
  self.input[end:self.input.length()]
}

///|
/// Return match `content` view.
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::content(self : MatchResult) -> StringView {
  guard self.result.group(0) is Some((start, end)) else { panic() }
  self.input[start:end]
}

///|
/// Access capture `group` information.
#internal(experimental, "subject to breaking change without notice")
pub fn MatchResult::group(self : MatchResult, group_index : Int) -> StringView? {
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
) -> StringView? {
  match self.group_names.search(Some(name)) {
    None => None
    Some(index) => self.group(index)
  }
}

///|
/// Compile a pattern into an internal regex representation.
/// DO NOT call this function even in this package.
#internal(internal, "not intended for public use")
#doc(hidden)
pub fn Regex::internal_compile_pattern(pat : Pattern) -> Regex {
  let lowered_pat = re_lower_to_utf16(pat.0)
  { pat: pat.0, re: Some(@re.compile(profile=re_profile_utf16, lowered_pat)) }
}

///|
fn Regex::re(self : Regex) -> @re.Regex {
  match self.re {
    Some(re) => re
    None => {
      let lowered_pat = re_lower_to_utf16(self.pat)
      let re = @re.compile(profile=re_profile_utf16, lowered_pat)
      self.re = Some(re)
      re
    }
  }
}

///|
/// Compiles a regex pattern string into a `Regex` object.
///
/// The regex syntax follows MoonBit `lexmatch` regex literals.
/// The following constructs are recognized:
///
/// - `.` wildcard (matches any character, including newline)
/// - Character classes: `[abc]`, `[^abc]`, `[a-z]`, POSIX classes such as
///   `[[:digit:]]`, `[[:alpha:]]`, `[[:space:]]`, `[[:word:]]`
/// - Quantifiers: `*`, `+`, `?`, `{n}`, `{n,}`, `{n,m}` and non-greedy forms
///   `*?`, `+?`, `??`, `{n}?`, `{n,}?`, `{n,m}?`
/// - Grouping and alternation: `( ... )`, `(?: ... )` (non-capturing),
///   `(?<name> ... )`, `a|b`
/// - Assertions and modifiers: `^`, `$`, `\b`, `\B`, `(?i: ... )`
///
/// Escape sequences include `\n`, `\r`, `\t`, `\f`, `\v`, and escaped
/// metacharacters. In `Regex::compile`, Unicode escapes are supported:
/// `\uXXXX` and `\u{X...}`. `\xHH` is not supported in `Regex::compile`.
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
///   let regex = @string.Regex("[[:digit:]]+")
///   guard regex.execute("a12b") is Some(m) else { fail("Expected match") }
///   inspect(m.content(), content="12")
/// }
/// ```
#internal(experimental, "subject to breaking change without notice")
pub fn Regex::new(pattern : StringView) -> Regex raise {
  let pat = @regex_parser.parse(
    profile=re_profile_unicode,
    pattern,
    mode=String,
  )
  { pat, re: None }
}

///|
/// Builds a regex that matches `str` literally.
///
/// This is equivalent to `Regex::new(Regex::escape(str))`.
///
/// Example:
///
/// ```mbt check
/// test {
///   let regex = @string.Regex::string("a+b(c)")
///   inspect(regex.execute("a+b(c)") is Some(_), content="true")
///   inspect(regex.execute("abcc") is Some(_), content="false")
/// }
/// ```
pub fn Regex::string(str : StringView) -> Regex {
  let pat = @re.seq(
    ReadOnlyArray::from_array(
      str.to_array().map(b => @re.char(@re.RecharSet::char(b.to_int()))),
    ),
  )
  { pat, re: None }
}

///|
/// Repeats this regex with a quantifier and returns a new regex.
///
/// - `min` is the minimum number of repetitions (default `0`)
/// - `max` is the optional maximum number of repetitions
/// - `greedy` controls whether matching is greedy or non-greedy
/// - Panics if `min < 0`, `min > 256`, `max < min`, or `max > 256`
///
/// Example:
///
/// ```mbt check
/// test {
///   let greedy = @string.Regex("[[:digit:]]").repeat(min=2, max=4)
///   guard greedy.execute("a12345") is Some(m1) else { fail("Expected match") }
///   inspect(m1.content(), content="1234")
///
///   let nongreedy = @string.Regex("[[:digit:]]").repeat(
///     min=2,
///     max=4,
///     greedy=false,
///   )
///   guard nongreedy.execute("a12345") is Some(m2) else { fail("Expected match") }
///   inspect(m2.content(), content="12")
/// }
/// ```
pub fn Regex::repeat(
  self : Regex,
  min? : Int = 0,
  max? : Int,
  greedy? : Bool = true,
) -> Regex {
  guard min >= 0 && min <= MAX_REPEAT_QUANTIFIER else { panic() }
  guard max is None ||
    (max is Some(max) && max >= min && max <= MAX_REPEAT_QUANTIFIER) else {
    panic()
  }
  {
    pat: @re.quantifier(self.pat, {
      min,
      max,
      mode: if greedy {
        Greedy
      } else {
        NonGreedy
      },
    }),
    re: None,
  }
}

///|
/// Concatenates two regexes in sequence.
///
/// Example:
///
/// ```mbt check
/// test {
///   let regex = @string.Regex::string("ab") + @string.Regex::string("cd")
///   guard regex.execute("xabcd") is Some(m) else { fail("Expected match") }
///   inspect(m.content(), content="abcd")
/// }
/// ```
pub impl Add for Regex with add(self, other) -> Regex {
  { pat: @re.seq([self.pat, other.pat]), re: None }
}

///|
/// Builds an alternation that matches either regex.
///
/// Example:
///
/// ```mbt check
/// test {
///   let regex = @string.Regex::string("cat") | @string.Regex::string("dog")
///   inspect(regex.execute("dog") is Some(_), content="true")
///   inspect(regex.execute("cow") is Some(_), content="false")
/// }
/// ```
pub impl BitOr for Regex with lor(self, other) -> Regex {
  { pat: @re.alt([self.pat, other.pat]), re: None }
}

///|
/// Executes this regex on `input` and returns the first match found.
///
/// Search starts at `last_index` (default `0`). The returned match, when
/// present, starts at or after that index.
///
/// `last_index` must satisfy `0 <= last_index <= input.length()`.
///
/// For inputs containing supplementary Unicode characters, `last_index` must
/// also be a valid UTF-16 character boundary (that is, not the second code
/// unit of a surrogate pair).
///
/// Passing a `last_index` in the middle of a surrogate pair may produce match
/// offsets that later cause `MatchResult::before`, `MatchResult::content`, or
/// `MatchResult::after` to panic when slicing.
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
///   let regex = @string.Regex("[[:digit:]]+")
///   let input = "a12b34"
///
///   guard regex.execute(input) is Some(first) else {
///     fail("Expected first match")
///   }
///   inspect(first.content(), content="12")
///
///   let next = first.before().length() + first.content().length()
///   guard regex.execute(input, last_index=next) is Some(second) else {
///     fail("Expected second match")
///   }
///   inspect(second.content(), content="34")
/// }
/// ```
/// 
/// ```mbt check
/// test {
///   let anchored = @string.Regex("^ab$")
///   inspect(anchored.execute("ab", last_index=0) is Some(_), content="true")
///   inspect(anchored.execute("xaby", last_index=1) is Some(_), content="false")
/// }
/// ```
#internal(experimental, "subject to breaking change without notice")
pub fn Regex::execute(
  self : Regex,
  input : StringView,
  last_index? : Int = 0,
) -> MatchResult? {
  match self.re().execute(input, last_index) {
    None => None
    Some(result) =>
      Some(MatchResult::{ input, group_names: self.re().group_names(), result })
  }
}
