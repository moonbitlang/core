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
test "2-tuple Debug" {
  let pair = (42, "hello")
  debug_inspect(pair, content="(42, \"hello\")")
}

///|
test "3-tuple Debug" {
  let triple = (42, "hello", true)
  debug_inspect(triple, content="(42, \"hello\", true)")
}

///|
test "4-tuple Debug" {
  let tuple = (42, "hello", true, 3.14)
  debug_inspect(tuple, content="(42, \"hello\", true, 3.14)")
}

///|
test "5-tuple Debug" {
  let tuple = (42, "hello", true, 3.14, 'a')
  debug_inspect(tuple, content="(42, \"hello\", true, 3.14, 'a')")
}

///|
test "6-tuple Debug" {
  let tuple = (42, "hello", true, 3.14, 'a', 1)
  debug_inspect(tuple, content="(42, \"hello\", true, 3.14, 'a', 1)")
}

///|
test "7-tuple Debug" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world")
  debug_inspect(tuple, content="(42, \"hello\", true, 3.14, 'a', 1, \"world\")")
}

///|
test "8-tuple Debug" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world", false)
  debug_inspect(
    tuple,
    content="(42, \"hello\", true, 3.14, 'a', 1, \"world\", false)",
  )
}

///|
test "9-tuple Debug" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world", false, 2.71)
  debug_inspect(
    tuple,
    content="(42, \"hello\", true, 3.14, 'a', 1, \"world\", false, 2.71)",
  )
}

///|
test "10-tuple Debug" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world", false, 2.71, 'b')
  debug_inspect(
    tuple,
    content="(42, \"hello\", true, 3.14, 'a', 1, \"world\", false, 2.71, 'b')",
  )
}

///|
test "11-tuple Debug" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world", false, 2.71, 'b', 43UL)
  debug_inspect(
    tuple,
    content="(42, \"hello\", true, 3.14, 'a', 1, \"world\", false, 2.71, 'b', 43)",
  )
}

///|
test "12-tuple Debug" {
  let tuple = (
    42, "hello", true, 3.14, 'a', 1, "world", false, 2.71, 'b', 43UL, 0x12345678U,
  )
  debug_inspect(
    tuple,
    content=(
      #|(
      #|  42,
      #|  "hello",
      #|  true,
      #|  3.14,
      #|  'a',
      #|  1,
      #|  "world",
      #|  false,
      #|  2.71,
      #|  'b',
      #|  43,
      #|  305419896,
      #|)
    ),
  )
}

///|
test "13-tuple Debug" {
  let tuple = (
    42, "hello", true, 3.14, 'a', 1, "world", false, 2.71, 'b', 43UL, 0x12345678U,
    0x87654321L,
  )
  debug_inspect(
    tuple,
    content=(
      #|(
      #|  42,
      #|  "hello",
      #|  true,
      #|  3.14,
      #|  'a',
      #|  1,
      #|  "world",
      #|  false,
      #|  2.71,
      #|  'b',
      #|  43,
      #|  305419896,
      #|  2271560481,
      #|)
    ),
  )
}

///|
test "14-tuple Debug" {
  let tuple = (
    42,
    "hello",
    true,
    3.14,
    'a',
    1,
    "world",
    false,
    2.71,
    'b',
    43UL,
    0x12345678U,
    0x87654321L,
    (0xabcdef, 1234567890UL),
  )
  debug_inspect(
    tuple,
    content=(
      #|(
      #|  42,
      #|  "hello",
      #|  true,
      #|  3.14,
      #|  'a',
      #|  1,
      #|  "world",
      #|  false,
      #|  2.71,
      #|  'b',
      #|  43,
      #|  305419896,
      #|  2271560481,
      #|  (11259375, 1234567890),
      #|)
    ),
  )
}

///|
test "15-tuple Debug" {
  let tuple = (
    42,
    "hello",
    true,
    3.14,
    'a',
    1,
    "world",
    false,
    2.71,
    'b',
    43UL,
    0x12345678U,
    0x87654321L,
    (0xabcdef, 1234567890UL),
    (0x12345678UL, 0x87654321UL, 0xabcdefUL),
  )
  debug_inspect(
    tuple,
    content=(
      #|(
      #|  42,
      #|  "hello",
      #|  true,
      #|  3.14,
      #|  'a',
      #|  1,
      #|  "world",
      #|  false,
      #|  2.71,
      #|  'b',
      #|  43,
      #|  305419896,
      #|  2271560481,
      #|  (11259375, 1234567890),
      #|  (305419896, 2271560481, 11259375),
      #|)
    ),
  )
}

///|
test "16-tuple Debug" {
  let tuple = (
    42,
    "hello",
    true,
    3.14,
    'a',
    1,
    "world",
    false,
    2.71,
    'b',
    43UL,
    0x12345678U,
    0x87654321L,
    (0xabcdef, 1234567890UL),
    (0x12345678UL, 0x87654321UL, 0xabcdefUL),
    ("wow", [0x87654321UL, 1234567890UL]),
  )
  debug_inspect(
    tuple,
    content=(
      #|(
      #|  42,
      #|  "hello",
      #|  true,
      #|  3.14,
      #|  'a',
      #|  1,
      #|  "world",
      #|  false,
      #|  2.71,
      #|  'b',
      #|  43,
      #|  305419896,
      #|  2271560481,
      #|  (11259375, 1234567890),
      #|  (305419896, 2271560481, 11259375),
      #|  ("wow", [2271560481, 1234567890]),
      #|)
    ),
  )
}
