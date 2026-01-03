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
test "2-tuple to_json" {
  let pair = (42, "hello")
  @json.inspect(pair, content=[42, "hello"])
}

///|
test "3-tuple to_json" {
  let triple = (42, "hello", true)
  @json.inspect(triple, content=[42, "hello", true])
}

///|
test "4-tuple to_json" {
  let tuple = (42, "hello", true, 3.14)
  @json.inspect(tuple, content=[42, "hello", true, 3.14])
}

///|
test "5-tuple to_json" {
  let tuple = (42, "hello", true, 3.14, 'a')
  @json.inspect(tuple, content=[42, "hello", true, 3.14, "a"])
}

///|
test "6-tuple to_json" {
  let tuple = (42, "hello", true, 3.14, 'a', 1)
  @json.inspect(tuple, content=[42, "hello", true, 3.14, "a", 1])
}

///|
test "7-tuple to_json" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world")
  @json.inspect(tuple, content=[42, "hello", true, 3.14, "a", 1, "world"])
}

///|
test "8-tuple to_json" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world", false)
  @json.inspect(tuple, content=[42, "hello", true, 3.14, "a", 1, "world", false])
}

///|
test "9-tuple to_json" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world", false, 2.71)
  @json.inspect(tuple, content=[
    42, "hello", true, 3.14, "a", 1, "world", false, 2.71,
  ])
}

///|
test "10-tuple to_json" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world", false, 2.71, 'b')
  @json.inspect(tuple, content=[
    42, "hello", true, 3.14, "a", 1, "world", false, 2.71, "b",
  ])
}

///|
test "11-tuple to_json" {
  let tuple = (42, "hello", true, 3.14, 'a', 1, "world", false, 2.71, 'b', 43UL)
  @json.inspect(tuple, content=[
    42, "hello", true, 3.14, "a", 1, "world", false, 2.71, "b", "43",
  ])
}

///|
test "12-tuple to_json" {
  let tuple = (
    42, "hello", true, 3.14, 'a', 1, "world", false, 2.71, 'b', 43UL, 0x12345678U,
  )
  @json.inspect(tuple, content=[
    42, "hello", true, 3.14, "a", 1, "world", false, 2.71, "b", "43", 305419896,
  ])
}

///|
test "13-tuple to_json" {
  let tuple = (
    42, "hello", true, 3.14, 'a', 1, "world", false, 2.71, 'b', 43UL, 0x12345678U,
    0x87654321L,
  )
  @json.inspect(tuple, content=[
    42, "hello", true, 3.14, "a", 1, "world", false, 2.71, "b", "43", 305419896,
    "2271560481",
  ])
}

///|
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
  @json.inspect(tuple, content=[
    42,
    "hello",
    true,
    3.14,
    "a",
    1,
    "world",
    false,
    2.71,
    "b",
    "43",
    305419896,
    "2271560481",
    [11259375, "1234567890"],
  ])
}

///|
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
  @json.inspect(tuple, content=[
    42,
    "hello",
    true,
    3.14,
    "a",
    1,
    "world",
    false,
    2.71,
    "b",
    "43",
    305419896,
    "2271560481",
    [11259375, "1234567890"],
    ["305419896", "2271560481", "11259375"],
  ])
}

///|
test "16-tuple to_json" {
  let tuple = (
    "hello",
    42,
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
    '码',
    -0.00001,
    ("wow", [0x87654321UL, 1234567890UL]),
  )
  @json.inspect(tuple, content=[
    "hello",
    42,
    true,
    3.14,
    "a",
    1,
    "world",
    false,
    2.71,
    "b",
    "43",
    305419896,
    "2271560481",
    "码",
    -0.00001,
    ["wow", ["2271560481", "1234567890"]],
  ])
}
