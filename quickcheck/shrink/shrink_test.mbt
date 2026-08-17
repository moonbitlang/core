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
test "shrink int" {
  debug_inspect(
    @shrink.Shrink::shrink(100).collect(),
    content=(
      #|[99, 97, 94, 88, 75, 50, 0]
    ),
  )
  debug_inspect(
    @shrink.Shrink::shrink(0).collect(),
    content=(
      #|[]
    ),
  )
}

///|
test "shrink int64" {
  debug_inspect(
    @shrink.Shrink::shrink(10000L).collect(),
    content=(
      #|[
      #|  9999,
      #|  9998,
      #|  9996,
      #|  9991,
      #|  9981,
      #|  9961,
      #|  9922,
      #|  9844,
      #|  9688,
      #|  9375,
      #|  8750,
      #|  7500,
      #|  5000,
      #|  0,
      #|]
    ),
  )
}

///|
test "shrink int16" {
  debug_inspect(
    @shrink.Shrink::shrink((100 : Int16)).collect(),
    content=(
      #|[99, 97, 94, 88, 75, 50, 0]
    ),
  )
}

///|
test "shrink uint16" {
  debug_inspect(
    @shrink.Shrink::shrink((100 : UInt16)).collect(),
    content=(
      #|[99, 97, 94, 88, 75, 50, 0]
    ),
  )
}

///|
test "shrink arbitrary-precision bigint" {
  let input = @bigint.BigInt::from_string("100000000000000000000")
  let zero = @bigint.BigInt::from_int(0)
  let candidates = @shrink.Shrink::shrink(input).collect()
  let tail = candidates.length() - 3
  debug_inspect(
    (candidates.length(), candidates[:4], candidates[tail:]),
    content=(
      #|(
      #|  67,
      #|  <ArrayView:
      #|    [
      #|      99999999999999999999,
      #|      99999999999999999998,
      #|      99999999999999999995,
      #|      99999999999999999990,
      #|    ]>,
      #|  <ArrayView: [75000000000000000000, 50000000000000000000, 0]>,
      #|)
    ),
  )
  assert_true(
    candidates.all(candidate => candidate >= zero && candidate < input),
  )
}

///|
test "shrink negative arbitrary-precision bigint" {
  let input = @bigint.BigInt::from_string("-100000000000000000000")
  let zero = @bigint.BigInt::from_int(0)
  let candidates = @shrink.Shrink::shrink(input).collect()
  let tail = candidates.length() - 3
  debug_inspect(
    (candidates.length(), candidates[:4], candidates[tail:]),
    content=(
      #|(
      #|  67,
      #|  <ArrayView:
      #|    [
      #|      -99999999999999999999,
      #|      -99999999999999999998,
      #|      -99999999999999999995,
      #|      -99999999999999999990,
      #|    ]>,
      #|  <ArrayView: [-75000000000000000000, -50000000000000000000, 0]>,
      #|)
    ),
  )
  assert_true(
    candidates.all(candidate => candidate > input && candidate <= zero),
  )
}

///|
test "shrink bigint boundary values" {
  let negative_one = @bigint.BigInt::from_int(-1)
  let zero = @bigint.BigInt::from_int(0)
  let one = @bigint.BigInt::from_int(1)
  debug_inspect(
    (
      @shrink.Shrink::shrink(negative_one).collect(),
      @shrink.Shrink::shrink(zero).collect(),
      @shrink.Shrink::shrink(one).collect(),
    ),
    content=(
      #|([0], [], [0])
    ),
  )
}

///|
test "shrink uint" {
  debug_inspect(
    @shrink.Shrink::shrink(37000U).collect(),
    content=(
      #|[
      #|  36999,
      #|  36998,
      #|  36996,
      #|  36991,
      #|  36982,
      #|  36964,
      #|  36928,
      #|  36856,
      #|  36711,
      #|  36422,
      #|  35844,
      #|  34688,
      #|  32375,
      #|  27750,
      #|  18500,
      #|  0,
      #|]
    ),
  )
}

///|
test "shrink uint64" {
  debug_inspect(
    @shrink.Shrink::shrink((42000 : UInt64)).collect(),
    content=(
      #|[
      #|  41999,
      #|  41998,
      #|  41995,
      #|  41990,
      #|  41980,
      #|  41959,
      #|  41918,
      #|  41836,
      #|  41672,
      #|  41344,
      #|  40688,
      #|  39375,
      #|  36750,
      #|  31500,
      #|  21000,
      #|  0,
      #|]
    ),
  )
}

///|
test "shrink byte" {
  let s = @shrink.Shrink::shrink(Int::to_byte(200)).collect()
  debug_inspect(
    s,
    content=(
      #|[0xc7, 0xc5, 0xc2, 0xbc, 0xaf, 0x96, 0x64, 0x00]
    ),
  )
  debug_inspect(
    @shrink.Shrink::shrink(Int::to_byte(0)).collect(),
    content=(
      #|[]
    ),
  )
}

///|
test "shrink boolean" {
  debug_inspect(
    @shrink.Shrink::shrink(true).collect(),
    content=(
      #|[false]
    ),
  )
  debug_inspect(
    @shrink.Shrink::shrink(false).collect(),
    content=(
      #|[]
    ),
  )
}

///|
test "shrink char" {
  debug_inspect(
    @shrink.Shrink::shrink('测').collect(),
    content=(
      #|['\n', ' ', '1', '2', '3', 'A', 'B', 'C', 'a', 'b', 'c']
    ),
  )
}

///|
test "shrink uppercase char lowercases and removes duplicates" {
  debug_inspect(
    @shrink.Shrink::shrink('C').collect(),
    content=(
      #|['A', 'B', 'a', 'b', 'c']
    ),
  )
}

///|
test "shrink char respects character class order" {
  debug_inspect(
    @shrink.Shrink::shrink('d').collect(),
    content=(
      #|['a', 'b', 'c']
    ),
  )
  debug_inspect(
    @shrink.Shrink::shrink('4').collect(),
    content=(
      #|['1', '2', '3', 'A', 'B', 'C', 'a', 'b', 'c']
    ),
  )
}

///|
test "shrink whitespace char prefers space" {
  debug_inspect(
    @shrink.Shrink::shrink('\n').collect(),
    content=(
      #|[' ', '1', '2', '3', 'A', 'B', 'C', 'a', 'b', 'c']
    ),
  )
}

///|
test "shrink bytes through byte array" {
  debug_inspect(
    @shrink.Shrink::shrink(b"\x67\x37").collect(),
    content=(
      #|[
      #|  <Bytes: []>,
      #|  <Bytes: [0x37]>,
      #|  <Bytes: [0x67]>,
      #|  <Bytes: [0x66, 0x37]>,
      #|  <Bytes: [0x64, 0x37]>,
      #|  <Bytes: [0x61, 0x37]>,
      #|  <Bytes: [0x5b, 0x37]>,
      #|  <Bytes: [0x4e, 0x37]>,
      #|  <Bytes: [0x34, 0x37]>,
      #|  <Bytes: [0x00, 0x37]>,
      #|  <Bytes: [0x67, 0x36]>,
      #|  <Bytes: [0x67, 0x34]>,
      #|  <Bytes: [0x67, 0x31]>,
      #|  <Bytes: [0x67, 0x2a]>,
      #|  <Bytes: [0x67, 0x1c]>,
      #|  <Bytes: [0x67, 0x00]>,
      #|]
    ),
  )
}

///|
test "shrink string by Unicode characters" {
  debug_inspect(
    @shrink.Shrink::shrink("🤣").collect(),
    content=(
      #|["", "\n", " ", "1", "2", "3", "A", "B", "C", "a", "b", "c"]
    ),
  )
}

///|
test "shrink double: pi" {
  let s = @shrink.Shrink::shrink(3.14159).collect()
  assert_true(s.contains(3.0))
  assert_true(s.contains(0.0))
  assert_true(s.all(y => y < 3.14159))
}

///|
test "shrink double: exact output for 3.5" {
  debug_inspect(
    @shrink.Shrink::shrink(3.5).collect(),
    content=(
      #|[3, 2, 0, 3.4, 3.3, 3.1, 2.7, 1.8, 0]
    ),
  )
}

///|
test "shrink double: zero" {
  debug_inspect(
    @shrink.Shrink::shrink(0.0).collect(),
    content=(
      #|[]
    ),
  )
}

///|
test "shrink double: negative" {
  debug_inspect(
    @shrink.Shrink::shrink(-5.5).collect(),
    content=(
      #|[5.5, -5, -3, 0, -5.4, -5.2, -4.9, -4.2, -2.8, 0]
    ),
  )
}

///|
test "shrink double: nan" {
  debug_inspect(
    @shrink.Shrink::shrink(0.0 / 0.0).collect(),
    content=(
      #|[0, 1, -1, 2]
    ),
  )
}

///|
test "shrink double: infinity" {
  debug_inspect(
    @shrink.Shrink::shrink(1.0 / 0.0).collect(),
    content=(
      #|[0, 1, -1, 1000, -1000]
    ),
  )
}

///|
test "shrink double: small value" {
  debug_inspect(
    @shrink.Shrink::shrink(0.001).collect(),
    content=(
      #|[0, 0]
    ),
  )
}

///|
test "shrink float: basic" {
  let s = @shrink.Shrink::shrink((3.14 : Float)).collect()
  assert_true(s.contains(3.0))
  assert_true(s.contains(0.0))
}
