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
test "lex_string stops at the end of a view inside a larger string" {
  // The backing string closes the string just past the view end; the lexer
  // must not see that quote, whichever scan path reaches it.
  for len in [0, 7, 8, 15, 16, 17, 23, 24, 25, 40, 100] {
    let text = "[\"" + "a".repeat(len) + "\"]"
    let view = text.exact_view(start=1, end=2 + len)
    debug_inspect(
      expect_parse_error(view, "expected InvalidEof"),
      content=(
        #|InvalidEof
      ),
    )
    assert_true(
      @json.parse(text.exact_view(start=1, end=3 + len)) ==
      Json::string("a".repeat(len)),
    )
  }
}

///|
test "lex_string reports control characters in long strings" {
  debug_inspect(
    expect_parse_error("\"" + "a".repeat(37) + "\n\"", "expected InvalidChar"),
    content=(
      #|InvalidChar({ line: 1, column: 38 }, '\n')
    ),
  )
  // After an escape, the run scan resumes and still finds the character.
  debug_inspect(
    expect_parse_error(
      "\"\\t" + "a".repeat(37) + "\u{1F}\"",
      "expected InvalidChar",
    ),
    content=(
      #|InvalidChar({ line: 1, column: 40 }, '\u{1f}')
    ),
  )
}

///|
test "lex_string copies long runs around escapes" {
  let run = "\u{1F600}abc\u{FF22}\u{225C}".repeat(4)
  assert_true(
    @json.parse("\"" + run + "\\n" + run + "\\u0041" + run + "\"") ==
    Json::string(run + "\n" + run + "A" + run),
  )
}
