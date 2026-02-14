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
test "escape/no_special_chars" {
  let escaped = @regex_syntax.escape("hello")
  inspect(escaped, content="hello")
}

///|
test "escape/dot" {
  let escaped = @regex_syntax.escape("a.b")
  inspect(escaped, content="a\\.b")
}

///|
test "escape/asterisk" {
  let escaped = @regex_syntax.escape("a*b")
  inspect(escaped, content="a\\*b")
}

///|
test "escape/plus" {
  let escaped = @regex_syntax.escape("a+b")
  inspect(escaped, content="a\\+b")
}

///|
test "escape/question_mark" {
  let escaped = @regex_syntax.escape("a?b")
  inspect(escaped, content="a\\?b")
}

///|
test "escape/parentheses" {
  let escaped = @regex_syntax.escape("a(b)c")
  inspect(escaped, content="a\\(b\\)c")
}

///|
test "escape/square_brackets" {
  let escaped = @regex_syntax.escape("a[b]c")
  inspect(escaped, content="a\\[b\\]c")
}

///|
test "escape/curly_braces" {
  let escaped = @regex_syntax.escape("a{b}c")
  inspect(escaped, content="a\\{b\\}c")
}

///|
test "escape/pipe" {
  let escaped = @regex_syntax.escape("a|b")
  inspect(escaped, content="a\\|b")
}

///|
test "escape/backslash" {
  let escaped = @regex_syntax.escape("a\\b")
  inspect(escaped, content="a\\\\b")
}

///|
test "escape/caret" {
  let escaped = @regex_syntax.escape("^abc")
  inspect(escaped, content="\\^abc")
}

///|
test "escape/dollar" {
  let escaped = @regex_syntax.escape("abc$")
  inspect(escaped, content="abc\\$")
}

///|
test "escape/hyphen" {
  let escaped = @regex_syntax.escape("a-b")
  inspect(
    escaped,
    content=(
      #|a-b
    ),
  )
}

///|
test "escape/multiple_special_chars" {
  let escaped = @regex_syntax.escape("a.b*c+d?e")
  inspect(escaped, content="a\\.b\\*c\\+d\\?e")
}

///|
test "escape/all_metacharacters" {
  let escaped = @regex_syntax.escape(".*()+[]{}|\\^$-")
  inspect(
    escaped,
    content=(
      #|\.\*\(\)\+\[\]\{\}\|\\\^\$-
    ),
  )
}

///|
test "escape/with_unicode" {
  let escaped = @regex_syntax.escape("你好.世界")
  inspect(escaped, content="你好\\.世界")
}

///|
test "escape/empty_string" {
  let escaped = @regex_syntax.escape("")
  inspect(escaped, content="")
}

///|
test "escape/only_special_chars" {
  let escaped = @regex_syntax.escape(".*+?")
  inspect(escaped, content="\\.\\*\\+\\?")
}
