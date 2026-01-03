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
struct Regexp {
  instructions : Array[Instruction]
  map : Map[String, Int]
  capture : Int
}

///|
/// Compiles a regex into a matcher.
fn ParseResult::compile(self : Self) -> Regexp {
  {
    instructions: self.ast.compile(),
    map: self.capture_map,
    capture: self.captures,
  }
}

///|
/// Compiles a regular expression into an execution engine.
/// 
/// Parses and compiles a regular expression string into a reusable execution engine.
/// The compiled engine can be executed multiple times, avoiding the overhead of repeated parsing and compilation.
/// 
/// Args:
/// - `regexp`: A string view of the regular expression.
/// 
/// Returns: The compiled regular expression execution engine.
/// 
/// Throws: `Error_` if the regular expression syntax is invalid.
/// 
/// Example:
/// ```mbt check
/// test {
///   let engine = @regexp.compile("a(bc|de)f")
///   inspect(
///     engine.execute("xxabcf").results(),
///     content=(
///       #|[Some("abcf"), Some("bc")]
///     ),
///   )
/// }
/// ```
pub fn compile(
  regexp : StringView,
  flags? : StringView = "",
) -> Regexp raise RegexpError {
  regexp
  |> parse(flags={
    multiline: flags.contains("m"),
    singleline: flags.contains("s"),
    ignore_case: flags.contains("i"),
  })
  |> ParseResult::compile()
}

///|
/// Gets the index of a capture group by its name.
/// 
/// Finds the index of a capture group with the specified name in the results.
/// Used to access named capture groups, such as those defined in the form `(?<name>pattern)`.
/// 
/// Args:
/// - `self`: The regular expression execution engine.
/// - `name`: The name of the capture group.
/// 
/// Returns: The index of the capture group, or `None` if the group name does not exist.
/// 
/// Example:
/// ```mbt check
/// test {
///   let engine = @regexp.compile("(?<word>\\w+)")
///   inspect(engine.group_by_name("word"), content="Some(1)")
/// }
/// ```
pub fn Regexp::group_by_name(self : Regexp, name : String) -> Int? {
  self.map.get(name)
}

///|
/// Gets the total number of capture groups in the regular expression.
/// 
/// Returns the number of capture groups defined in the regular expression pattern, including both named and anonymous groups.
/// Group with index 0 always represents the entire match, and actual capture groups start from index 1.
/// 
/// Args:
/// - `self`: The regular expression execution engine.
/// 
/// Returns: The total number of capture groups (including the full match at index 0).
/// 
/// Example:
/// ```mbt check
/// test {
///   let engine = @regexp.compile("(a)(b|c)")
///   inspect(engine.group_count(), content="3")
/// }
/// ```
pub fn Regexp::group_count(self : Regexp) -> Int {
  self.capture
}

///|
/// Gets the names of all named capture groups in the regular expression.
/// 
/// Returns an iterator that contains the names of all named capture groups in the regular expression.
/// Only explicitly named capture groups, such as those defined in the form `(?<name>pattern)`, are returned.
/// 
/// Args:
/// - `self`: The regular expression execution engine.
/// 
/// Returns: An iterator containing all group names.
/// 
/// Example:
/// ```mbt check
/// test {
///   let engine = @regexp.compile("(?<first>a)(?<second>b)")
///   inspect(
///     engine.group_names(),
///     content=(
///       #|["first", "second"]
///     ),
///   )
/// }
/// ```
pub fn Regexp::group_names(self : Regexp) -> Array[String] {
  self.map.keys().collect()
}

///|
/// Executes a regular expression match on the input text.
/// 
/// Uses the compiled regular expression engine to perform a match on the specified input text,
/// returning a `MatchResult` object containing the match results and capture group information.
/// It uses a leftmost-first matching strategy, returning the first match found.
/// 
/// Args:
/// - `self`: The regular expression execution engine.
/// - `input`: The input text to match against.
/// 
/// Returns: A `MatchResult` object containing the match status and capture group information.
/// 
/// Example:
/// ```mbt check
/// test {
///   let engine = @regexp.compile("a(bc|de)f")
///   let result = engine.execute("xxabcf")
///   if result.matched() {
///     inspect(
///       result.get(0),
///       content=(
///         #|Some("abcf")
///       ),
///     )
///   }
/// }
/// ```
pub fn Regexp::execute(self : Regexp, input : StringView) -> MatchResult {
  let captures = vm(self.instructions, input, self.capture)
  let (before, after) = if captures is [0..<_ as start, 0..<_ as end, ..] {
    (input.view(end_offset=start), input.view(start_offset=end))
  } else {
    (input, input.view(start_offset=input.length()))
  }
  { input, captures, names: self.map, before, after }
}

///|
/// Executes a regular expression match on the input text.
/// 
/// Uses the compiled regular expression engine to perform a match on the specified input text,
/// returning a `MatchResult` object containing the match results and capture group information.
/// It uses a leftmost-first matching strategy, returning the first match found.
/// 
/// Args:
/// - `self`: The regular expression execution engine.
/// - `input`: The input text to match against.
/// 
/// Returns: A tuple of 
/// - `MatchResult` object containing the match status and capture group information.
/// - `StringView` representing the remaining text after the match.
/// 
/// Example:
/// ```mbt check
/// test {
///   let engine = @regexp.compile("a(bc|de)f")
///   let result = engine.execute("abcfxx")
///   guard result.matched()
///   inspect(result.before(), content="")
///   inspect(result.after(), content="xx")
///   let result = engine.execute("axxf")
///   guard !result.matched()
///   inspect(result.before(), content="axxf")
///   inspect(result.after(), content="")
/// }
/// ```
#deprecated("Use `Regexp::execute` and `MatchResult::before`/`after` instead.")
pub fn Regexp::execute_with_remainder(
  self : Regexp,
  input : StringView,
) -> (MatchResult, StringView) {
  let captures = vm(self.instructions, input, self.capture)
  if captures is [0..<_ as start, 0..<_ as end, ..] {
    (
      {
        input,
        captures,
        names: self.map,
        before: input.view(end_offset=start),
        after: input.view(start_offset=end),
      },
      input.view(start_offset=end),
    )
  } else {
    (
      {
        input,
        captures,
        names: self.map,
        before: input,
        after: input.view(start_offset=input.length()),
      },
      input,
    )
  }
}

///|
/// Executes a regular expression match on the input text.
/// 
/// Uses the compiled regular expression engine to perform a match on the specified input text,
/// returning a `MatchResult` object containing the match results and capture group information.
/// It uses a leftmost-first matching strategy, returning the first match found.
/// 
/// Args:
/// - `self`: The regular expression execution engine.
/// - `input`: The input text to match against.
/// 
/// Returns: A tuple of 
/// - `MatchResult` object containing the match status and capture group information.
/// 
/// Example:
/// ```mbt check
/// test {
///   let engine = @regexp.compile("a(bc|de)f")
///   guard engine.match_("abcfxx") is Some(result)
///   inspect(result.after(), content="xx")
///   assert_true(engine.match_("axxf") is None)
/// }
/// ```
pub fn Regexp::match_(self : Regexp, input : StringView) -> MatchResult? {
  let captures = vm(self.instructions, input, self.capture)
  guard captures is [0..<_ as start, 0..<_ as end, ..] else { return None }
  let before = input.view(end_offset=start)
  let after = input.view(start_offset=end)
  Some({ input, captures, names: self.map, before, after })
}

///|
/// Regular expression match result.
/// 
/// Contains the complete result information of a regular expression match, including:
/// - The original input text.
/// - An array of capture group position information.
/// - A map of named capture groups.
/// 
/// Structure of the capture group array:
/// - Index 0, 1: Start and end positions of the full match.
/// - Index 2, 3: Start and end positions of the first capture group.
/// - Index 4, 5: Start and end positions of the second capture group.
/// - And so on...
struct MatchResult {
  input : StringView
  captures : Array[Int]
  names : Map[String, Int]
  before : StringView
  after : StringView
}

///|
/// Checks if the match was successful.
/// 
/// Determines whether the regular expression found a match in the input text.
/// An empty capture group array indicates that no match was found.
/// 
/// Args:
/// - `self`: The match result object.
/// 
/// Returns: `true` if a match was found, otherwise `false`.
/// 
/// Example:
/// ```mbt check
/// test {
///   let result = @regexp.compile("text").execute("text")
///   inspect(result.matched(), content="true")
/// }
/// ```
pub fn MatchResult::matched(self : Self) -> Bool {
  not(self.captures is [])
}

///|
/// Gets the content of a capture group by its index.
/// 
/// Returns the corresponding matched text based on the capture group's index.
/// Index 0 represents the full match, while indices 1 and above represent individual capture groups.
/// 
/// Args:
/// - `self`: The match result object.
/// - `index`: The index of the capture group (0 for the full match).
/// 
/// Returns: 
/// - `Some(view)`: The text view corresponding to the capture group.
/// - `None`: If the index is invalid or the capture group did not match.
/// 
/// Example:
/// ```mbt check
/// test {
///   let result = @regexp.compile(".(bc)").execute("abc")
///   inspect(
///     result.get(0),
///     content=(
///       #|Some("abc")
///     ),
///   )
///   let first_group = result.get(1)
///   inspect(
///     first_group,
///     content=(
///       #|Some("bc")
///     ),
///   )
/// }
/// ```
pub fn MatchResult::get(self : Self, index : Int) -> StringView? {
  if self.captures.is_empty() ||
    index < 0 ||
    index >= self.captures.length() / 2 {
    return None
  }
  let start = self.captures[index * 2]
  let end = self.captures[index * 2 + 1]
  if start < 0 || end < start || end > self.input.length() {
    return None
  }
  Some(self.input.view(start_offset=start, end_offset=end))
}

///|
/// Returns a map containing all named capture groups and their matched
/// contents.
///
/// Parameters:
///
/// * `self` : The match result object containing named capture group
///   information.
///
/// Returns a map where keys are the names of capture groups and values are
/// their corresponding matched content. If a named group did not participate in
/// the match or was not matched, its value will be `None`.
///
/// Example:
///
/// ```mbt check
/// test {
///   let engine = @regexp.compile("(?<word>\\w+)\\s+(?<num>\\d+)")
///   let result = engine.execute("hello 123")
///   inspect(
///     result.groups(),
///     content=(
///       #|{"word": "hello", "num": "123"}
///     ),
///   )
/// }
/// ```
///
pub fn MatchResult::groups(self : Self) -> Map[String, StringView] {
  self.names
  .iter()
  .filter_map(p => if self.get(p.1) is Some(content) {
    Some((p.0, content))
  } else {
    None
  })
  |> Map::from_iter
}

///|
/// Gets an iterator over the content of all valid capture groups.
/// 
/// Returns an iterator that contains the content of all successfully matched capture groups,
/// including the full match (index 0) and all other capture groups. Only valid matched content is returned,
/// skipping any unmatched capture groups.
/// 
/// Args:
/// - `self`: The match result object.
/// 
/// Returns: An iterator containing the content of all valid capture groups.
/// 
/// Example:
/// ```mbt check
/// test {
///   let result = @regexp.compile("(\\w)+").execute("abc")
///   inspect(
///     result.results(),
///     content=(
///       #|[Some("abc"), Some("c")]
///     ),
///   )
/// }
/// ```
pub fn MatchResult::results(self : Self) -> Array[StringView?] {
  let results = []
  for i = 0; i < self.captures.length() / 2; i = i + 1 {
    let start = self.captures[i * 2]
    let end = self.captures[i * 2 + 1]
    if start == -1 && end == -1 {
      results.push(None)
    } else {
      results.push(Some(self.input.view(start_offset=start, end_offset=end)))
    }
  }
  results
}

///|
/// Gets the text before the match.
/// 
/// If the match was not successful, this will return the entire input text.
/// 
/// ```mbt check
/// test {
///   let engine = @regexp.compile("world")
///   let result = engine.execute("hello world")
///   inspect(result.before(), content="hello ")
///   let result = engine.execute("say hello")
///   inspect(result.before(), content="say hello")
/// }
/// ```
pub fn MatchResult::before(self : Self) -> StringView {
  self.before
}

///|
/// Gets the remaining text after the match.
/// 
/// If the match was not successful, this will return the empty string.
/// 
/// ```mbt check
/// test {
///   let engine = @regexp.compile("hello")
///   let result = engine.execute("hello world")
///   inspect(result.after(), content=" world")
///   let result = engine.execute("say yes")
///   inspect(result.after(), content="")
/// }
/// ```
pub fn MatchResult::after(self : Self) -> StringView {
  self.after
}

///|
test "rest method" {
  let engine = compile("hello")
  let result = engine.execute("hello world")
  inspect(result.matched(), content="true")
  inspect(result.before(), content="")
  inspect(result.after(), content=" world")
  let result2 = engine.execute("say hello")
  inspect(result2.matched(), content="true")
  inspect(result2.before(), content="say ")
  inspect(result2.after(), content="")
  let result3 = engine.execute("hi there")
  inspect(result3.matched(), content="false")
  inspect(result3.before(), content="hi there")
  inspect(result3.after(), content="")
  inspect("Test rest method completed", content="Test rest method completed")
}

///|
test "rest method with capture groups" {
  let engine = compile("(\\w+)\\s+")
  let result = engine.execute("hello world test")
  inspect(result.matched(), content="true")
  inspect(
    result.get(0),
    content=(
      #|Some("hello ")
    ),
  )
  inspect(
    result.get(1),
    content=(
      #|Some("hello")
    ),
  )
  inspect(result.after(), content="world test")
  let engine2 = compile(".*")
  let result2 = engine2.execute("everything")
  inspect(result2.matched(), content="true")
  inspect(
    result2.get(0),
    content=(
      #|Some("everything")
    ),
  )
  inspect(result2.after(), content="")
}

///|
test "rest method usage example" {
  let engine = compile("\\b\\w+\\b")
  let mut input : StringView = "word1 word2 word3"
  let result1 = engine.execute(input)
  inspect(
    result1.get(0),
    content=(
      #|Some("word1")
    ),
  )
  input = result1.after()
  let result2 = engine.execute(input)
  inspect(
    result2.get(0),
    content=(
      #|Some("word2")
    ),
  )
  inspect(result2.after(), content=" word3")
}
