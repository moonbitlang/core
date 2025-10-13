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
test {
  // (a+b+)
  let instructions = [
    Save(0),
    Char(['a', 'a']),
    Split(1, 3),
    Char(['b', 'b']),
    Split(3, 5),
    Save(1),
    Matched,
  ]
  let captures = vm(instructions, "aab", 1)
  inspect(captures, content="[0, 3]")
  inspect("aab".view(start_offset=0, end_offset=3), content="aab")
}

///|
test "lazy capture" {
  // (a+?)aaaa
  let instructions = [
    Save(0),
    Save(2),
    Split(3, 5),
    Char(['a', 'a']),
    Jump(1),
    Save(3),
    Char(['a', 'a']),
    Char(['a', 'a']),
    Char(['a', 'a']),
    Char(['a', 'a']),
    Save(1),
    Matched,
  ]
  let captures = vm(instructions, "aaaa", 2)
  inspect(captures, content="[0, 4, 0, 0]")
}

///|
test "priority" (t : @test.T) {
  // (a.*)(b.*)(c.*)
  let instructions = [
    Save(0),
    Save(2),
    Char(['a', 'a']),
    Split(4, 6),
    // any
    Char(['\u{0}', '\u{10FFFF}']),
    Jump(3),
    Save(3),
    Save(4),
    Char(['b', 'b']),
    Split(10, 12),
    // any
    Char(['\u{0}', '\u{10FFFF}']),
    Jump(9),
    Save(5),
    Save(6),
    Char(['c', 'c']),
    Split(16, 18),
    // any
    Char(['\u{0}', '\u{10FFFF}']),
    Jump(15),
    Save(7),
    Save(1),
    Matched,
  ]
  let captures = vm(instructions, "aabbcc", 4)
  inspect(captures, content="[0, 6, 0, 3, 3, 5, 5, 6]")
  for i = 0; i < captures.length(); i = i + 2 {
    t.writeln(
      "aabbcc".view(start_offset=captures[i], end_offset=captures[i + 1]),
    )
  }
  t.snapshot(filename="priority.txt")
}

///|
test "alternate capture" {
  // a(b|c)*d
  let instructions = [
    Save(0),
    Char(['a', 'a']),
    Split(3, 10),
    Save(2),
    Split(5, 7),
    Char(['b', 'b']),
    Jump(8),
    Char(['c', 'c']),
    Save(3),
    Jump(2),
    Char(['d', 'd']),
    Save(1),
    Matched,
  ]
  let captures = vm(instructions, "abbd", 2)
  inspect(captures, content="[0, 4, 2, 3]")
}

///|
test "assertions" {
  // ^a$
  let instructions = [
    Save(0),
    Assertion(BeginText),
    Char(['a', 'a']),
    Assertion(EndText),
    Save(1),
    Matched,
  ]
  let capture = vm(instructions, "a", 1)
  inspect(capture, content="[0, 1]")
  let capture = vm(instructions, "ab", 1)
  inspect(capture, content="[]")
  // \b
  let instructions = [Save(0), Assertion(WordBoundary), Save(1), Matched]
  let capture = vm(instructions, "", 1)
  inspect(capture, content="[]")
  let capture = vm(instructions, "a", 1)
  inspect(capture, content="[0, 0]")
  // \B
  let instructions = [Save(0), Assertion(NoWordBoundary), Save(1), Matched]
  let capture = vm(instructions, "", 1)
  inspect(capture, content="[0, 0]")
  let capture = vm(instructions, "a", 1)
  inspect(capture, content="[]")
}

///|
test "backreference" {
  // \1(a)\1
  let instructions = [
    Save(0),
    Backreference(1),
    Save(2),
    Char(['a', 'a']),
    Save(3),
    Save(4),
    Backreference(1),
    Save(5),
    Save(1),
    Matched,
  ]
  let capture = vm(instructions, "aa", 3)
  inspect(capture, content="[0, 2, 0, 1, 1, 2]")

  // (b*a)\1
  let instructions = [
    Save(0),
    Save(2),
    Split(3, 5),
    Char(['b', 'b']),
    Jump(2),
    Char(['a', 'a']),
    Save(3),
    Backreference(1),
    Save(1),
    Matched,
  ]
  let capture = vm(instructions, "bbabba", 2)
  inspect(capture, content="[0, 6, 0, 3]")

  // (a|b)\1
  let instructions = [
    Save(0),
    Save(2),
    Split(3, 5),
    Char(['a', 'a']),
    Jump(6),
    Char(['b', 'b']),
    Save(3),
    Backreference(1),
    Save(1),
    Matched,
  ]
  let capture = vm(instructions, "aa", 2)
  inspect(capture, content="[0, 2, 0, 1]")
  let capture = vm(instructions, "bb", 2)
  inspect(capture, content="[0, 2, 0, 1]")

  // (aa|bb)\1cd
  let instructions = [
    Save(0),
    Save(2),
    Split(3, 6),
    Char(['a', 'a']),
    Char(['a', 'a']),
    Jump(8),
    Char(['b', 'b']),
    Char(['b', 'b']),
    Save(3),
    Backreference(1),
    Char(['c', 'c']),
    Char(['d', 'd']),
    Save(1),
    Matched,
  ]
  let capture = vm(instructions, "aaaacd", 2)
  inspect(capture, content="[0, 6, 0, 2]")
  let capture = vm(instructions, "bbbbcd", 2)
  inspect(capture, content="[0, 6, 0, 2]")

  // (abc)(\1|ab)
  let instructions = [
    Save(0),
    Save(2),
    Char(['a', 'a']),
    Char(['b', 'b']),
    Char(['c', 'c']),
    Save(3),
    Save(4),
    Split(8, 10),
    Backreference(1),
    Jump(12),
    Char(['a', 'a']),
    Char(['b', 'b']),
    Save(5),
    Save(1),
    Matched,
  ]
  let capture = vm(instructions, "abcabc", 3)
  inspect(capture, content="[0, 6, 0, 3, 3, 6]")
  let capture = vm(instructions, "abcab", 3)
  inspect(capture, content="[0, 5, 0, 3, 3, 5]")

  // (abc)(ab|\1)d
  let instructions = [
    Save(0),
    Save(2),
    Char(['a', 'a']),
    Char(['b', 'b']),
    Char(['c', 'c']),
    Save(3),
    Save(4),
    Split(8, 11),
    Char(['a', 'a']),
    Char(['b', 'b']),
    Jump(12),
    Backreference(1),
    Save(5),
    Char(['d', 'd']),
    Save(1),
    Matched,
  ]
  let capture = vm(instructions, "abcabcd", 3)
  inspect(capture, content="[0, 7, 0, 3, 3, 6]")
  let capture = vm(instructions, "abcabd", 3)
  inspect(capture, content="[0, 6, 0, 3, 3, 5]")
}
