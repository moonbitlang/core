// Copyright 2025 International Digital Economy Academy
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
fn literal(str : String) -> Ast {
  let regex = []
  for ch in str {
    regex.push(CharClass([ch, ch], neg=false))
  }
  Concat(regex)
}

///|
test "literal" {
  let regex = literal("abc")
  let instructions = regex.compile()
  let result = vm(instructions, "abc", 1)
  inspect(result, content="[0, 3]")
}

///|
test "char_class" {
  // ([ac])
  let regex = Ast::ZeroOrMore(
    Ast::CharClass(['a', 'c'], neg=false),
    greedy=true,
  )
  let instructions = regex.compile()
  let result = vm(instructions, "abc", 1)
  inspect(result, content="[0, 3]")
  // ([a])
  let regex = Ast::ZeroOrMore(
    Ast::CharClass(['a', 'a'], neg=false),
    greedy=true,
  )
  let instructions = regex.compile()
  let result = vm(instructions, "abc", 1)
  inspect(result, content="[0, 1]")
  // ([^ac])
  let regex = Ast::ZeroOrMore(Ast::CharClass(['a', 'c'], neg=true), greedy=true)
  let instructions = regex.compile()
  let result = vm(instructions, "abc", 1)
  inspect(result, content="[0, 0]")
}

///|
test "capture" {
  let regex = Ast::Capture(literal("abc"), index=1)
  let instructions = regex.compile()
  let result = vm(instructions, "abc", 2)
  inspect(result, content="[0, 3, 0, 3]")
  inspect(
    "abc".view(start_offset=result[1 * 2], end_offset=result[1 * 2 + 1]),
    content="abc",
  )
}

///|
test "zero_or_more" {
  let regex = Ast::ZeroOrMore(literal("abc"), greedy=true)
  let instructions = regex.compile()
  let result = vm(instructions, "abcabcab", 1)
  inspect(result, content="[0, 6]")
  let result = vm(instructions, "ab", 1)
  inspect(result, content="[0, 0]")
  let regex = Ast::ZeroOrMore(literal("abc"), greedy=false)
  let instructions = regex.compile()
  let result = vm(instructions, "abcabcab", 1)
  inspect(result, content="[0, 0]")
  let result = vm(instructions, "ab", 1)
  inspect(result, content="[0, 0]")
}

///|
test "one_or_more" {
  let regex = Ast::OneOrMore(literal("abc"), greedy=true)
  let instructions = regex.compile()
  let result = vm(instructions, "abcabcab", 1)
  inspect(result, content="[0, 6]")
  let result = vm(instructions, "ab", 1)
  inspect(result, content="[]")
  let regex = Ast::OneOrMore(literal("abc"), greedy=false)
  let instructions = regex.compile()
  let result = vm(instructions, "abcabcab", 1)
  inspect(result, content="[0, 3]")
  let result = vm(instructions, "ab", 1)
  inspect(result, content="[]")
}

///|
test "zero_or_one" {
  let regex = Ast::ZeroOrOne(literal("abc"), greedy=true)
  let instructions = regex.compile()
  let result = vm(instructions, "abc", 1)
  inspect(result, content="[0, 3]")
  let result = vm(instructions, "ab", 1)
  inspect(result, content="[0, 0]")
  let regex = Ast::ZeroOrOne(literal("abc"), greedy=false)
  let instructions = regex.compile()
  let result = vm(instructions, "abc", 1)
  inspect(result, content="[0, 0]")
  let result = vm(instructions, "ab", 1)
  inspect(result, content="[0, 0]")
}

///|
test "repeat" {
  // greedy
  let regex = Ast::Repeat(min=2, max=Some(4), literal("abc"), greedy=true)
  let instructions = regex.compile()
  let result = vm(instructions, "abcabcabcabc", 1)
  inspect(result, content="[0, 12]")
  let result = vm(instructions, "abcabc", 1)
  inspect(result, content="[0, 6]")
  let result = vm(instructions, "ab", 1)
  inspect(result, content="[]")
  // non-greedy
  let regex = Ast::Repeat(min=2, max=Some(4), literal("abc"), greedy=false)
  let instructions = regex.compile()
  let result = vm(instructions, "abcabcabcabc", 1)
  inspect(result, content="[0, 6]")
  let result = vm(instructions, "abcabc", 1)
  inspect(result, content="[0, 6]")
  let result = vm(instructions, "ab", 1)
  inspect(result, content="[]")
}

///|
test "concat" {
  let regex = Ast::Concat([literal("abc"), literal("def")])
  let instructions = regex.compile()
  let result = vm(instructions, "abcdef", 1)
  inspect(result, content="[0, 6]")
  let result = vm(instructions, "abc", 1)
  inspect(result, content="[]")
}

///|
test "alternate" {
  let regex = Ast::Alternate(literal("abc"), literal("def"))
  let instructions = regex.compile()
  let result = vm(instructions, "abc", 1)
  inspect(result, content="[0, 3]")
  let result = vm(instructions, "def", 1)
  inspect(result, content="[0, 3]")
  let result = vm(instructions, "xyz", 1)
  inspect(result, content="[]")
}

///|
test "empty" {
  let regex = Ast::Alternate(literal("abc"), Ast::Empty)
  let instructions = regex.compile()
  let result = vm(instructions, "abc", 1)
  inspect(result, content="[0, 3]")
  let result = vm(instructions, "xyz", 1)
  inspect(result, content="[0, 0]")

  /// Reversed
  let regex = Ast::Alternate(Ast::Empty, literal("abc"))
  let instructions = regex.compile()
  let result = vm(instructions, "abc", 1)
  inspect(result, content="[0, 0]")
}

///|
test "alternate capture" {
  let regex = OneOrMore(
    Alternate(
      Capture(CharClass(['a', 'a'], neg=false), index=1),
      Capture(CharClass(['b', 'b'], neg=false), index=2),
    ),
    greedy=true,
  )
  @json.inspect(regex.compile(), content=[
    ["Split", 3, 1],
    ["Chars", ["'\\u{00}'", "'\\u{10ffff}'"]],
    ["Jump", 0],
    ["Save", 0],
    ["Split", 5, 9],
    ["Save", 2],
    ["Chars", ["'a'", "'a'"]],
    ["Save", 3],
    ["Jump", 12],
    ["Save", 4],
    ["Chars", ["'b'", "'b'"]],
    ["Save", 5],
    ["Split", 4, 13],
    ["Save", 1],
    "Matched",
  ])
}

///|
test "backreference" {
  let regex = Concat([
    Capture(
      ZeroOrMore(Alternate(literal("a"), literal("b")), greedy=true),
      index=1,
    ),
    Backreference(1),
    Backreference(1),
  ])
  @json.inspect(regex.compile(), content=[
    ["Split", 3, 1],
    ["Chars", ["'\\u{00}'", "'\\u{10ffff}'"]],
    ["Jump", 0],
    ["Save", 0],
    ["Save", 2],
    ["Split", 6, 11],
    ["Split", 7, 9],
    ["Chars", ["'a'", "'a'"]],
    ["Jump", 10],
    ["Chars", ["'b'", "'b'"]],
    ["Split", 6, 11],
    ["Save", 3],
    ["Backreference", 1],
    ["Backreference", 1],
    ["Save", 1],
    "Matched",
  ])
}
