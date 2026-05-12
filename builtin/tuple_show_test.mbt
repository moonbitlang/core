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
#warnings("-deprecated")
test "2-tuple to_json" {
  let pair = (42, "hello")
  @json.json_inspect(pair.to_string(), content="(42, \"hello\")")
}

///|
#warnings("-deprecated")
test "3-tuple to_json" {
  let triple = (42, "hello", true)
  @json.json_inspect(triple.to_string(), content="(42, \"hello\", true)")
}

///|
#warnings("-deprecated")
test "4-tuple to_json" {
  let tuple = (42, "hello", true, 3.14)
  @json.json_inspect(tuple.to_string(), content="(42, \"hello\", true, 3.14)")
}

///|
#warnings("-deprecated")
test "5-tuple to_json" {
  let tuple = (42, "hello", true, 3.14, 'a')
  @json.json_inspect(
    tuple.to_string(),
    content="(42, \"hello\", true, 3.14, 'a')",
  )
}

///|
#warnings("-deprecated")
test "6-tuple to_json" {
  let tuple = (42, "hello", true, 3.14, 'a', 1)
  @json.json_inspect(
    tuple.to_string(),
    content="(42, \"hello\", true, 3.14, 'a', 1)",
  )
}

///|
#warnings("-deprecated")
test "7-tuple to_json" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world")
  @json.json_inspect(
    tuple.to_string(),
    content="(42, \"hello\", true, 3.14, 'a', 1, \"world\")",
  )
}

///|
#warnings("-deprecated")
test "8-tuple to_json" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world", false)
  @json.json_inspect(
    tuple.to_string(),
    content="(42, \"hello\", true, 3.14, 'a', 1, \"world\", false)",
  )
}

///|
#warnings("-deprecated")
test "9-tuple to_json" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world", false, 2.71)
  @json.json_inspect(
    tuple.to_string(),
    content="(42, \"hello\", true, 3.14, 'a', 1, \"world\", false, 2.71)",
  )
}

///|
#warnings("-deprecated")
test "10-tuple to_json" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world", false, 2.71, 'b')
  @json.json_inspect(
    tuple.to_string(),
    content="(42, \"hello\", true, 3.14, 'a', 1, \"world\", false, 2.71, 'b')",
  )
}

///|
#warnings("-deprecated")
test "11-tuple to_json" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world", false, 2.71, 'b', 43UL)
  @json.json_inspect(
    tuple.to_string(),
    content="(42, \"hello\", true, 3.14, 'a', 1, \"world\", false, 2.71, 'b', 43)",
  )
}

///|
#warnings("-deprecated")
test "12-tuple to_json" {
  let tuple = (
    42, "hello", true, 3.14, 'a', 1, "world", false, 2.71, 'b', 43UL, 0x12345678U,
  )
  @json.json_inspect(
    tuple.to_string(),
    content="(42, \"hello\", true, 3.14, 'a', 1, \"world\", false, 2.71, 'b', 43, 305419896)",
  )
}

///|
#warnings("-deprecated")
test "13-tuple to_json" {
  let tuple = (
    42, "hello", true, 3.14, 'a', 1, "world", false, 2.71, 'b', 43UL, 0x12345678U,
    0x87654321L,
  )
  @json.json_inspect(
    tuple.to_string(),
    content="(42, \"hello\", true, 3.14, 'a', 1, \"world\", false, 2.71, 'b', 43, 305419896, 2271560481)",
  )
}

///|
#warnings("-deprecated")
test "14-tuple to_json" {
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
  @json.json_inspect(
    tuple.to_string(),
    content="(42, \"hello\", true, 3.14, 'a', 1, \"world\", false, 2.71, 'b', 43, 305419896, 2271560481, (11259375, 1234567890))",
  )
}

///|
#warnings("-deprecated")
test "15-tuple to_json" {
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
  @json.json_inspect(
    tuple.to_string(),
    content="(42, \"hello\", true, 3.14, 'a', 1, \"world\", false, 2.71, 'b', 43, 305419896, 2271560481, (11259375, 1234567890), (305419896, 2271560481, 11259375))",
  )
}

///|
#warnings("-deprecated")
test "16-tuple to_json" {
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
  @json.json_inspect(
    tuple.to_string(),
    content="(42, \"hello\", true, 3.14, 'a', 1, \"world\", false, 2.71, 'b', 43, 305419896, 2271560481, (11259375, 1234567890), (305419896, 2271560481, 11259375), (\"wow\", [2271560481, 1234567890]))",
  )
}
