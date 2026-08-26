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
      #|[50, 75, 88, 94, 97, 99, 0]
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
      #|  5000,
      #|  7500,
      #|  8750,
      #|  9375,
      #|  9688,
      #|  9844,
      #|  9922,
      #|  9961,
      #|  9981,
      #|  9991,
      #|  9996,
      #|  9998,
      #|  9999,
      #|  0,
      #|]
    ),
  )
}

///|
test "shrink signed integer minimum values toward zero without overflow" {
  let ints = @shrink.Shrink::shrink((-2147483647 - 1 : Int)).collect()
  let int64s = @shrink.Shrink::shrink((-9223372036854775807L - 1L : Int64)).collect()
  debug_inspect(
    (ints.length(), ints[:3], ints.last()),
    content=(
      #|(32, <ArrayView: [-1073741824, -1610612736, -1879048192]>, Some(0))
    ),
  )
  debug_inspect(
    (int64s.length(), int64s[:3], int64s.last()),
    content=(
      #|(
      #|  64,
      #|  <ArrayView:
      #|    [-4611686018427387904, -6917529027641081856, -8070450532247928832]>,
      #|  Some(0),
      #|)
    ),
  )
}

///|
test "shrink int16" {
  debug_inspect(
    @shrink.Shrink::shrink((100 : Int16)).collect(),
    content=(
      #|[50, 75, 88, 94, 97, 99, 0]
    ),
  )
}

///|
test "shrink uint16" {
  debug_inspect(
    @shrink.Shrink::shrink((100 : UInt16)).collect(),
    content=(
      #|[50, 75, 88, 94, 97, 99, 0]
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
      #|  18500,
      #|  27750,
      #|  32375,
      #|  34688,
      #|  35844,
      #|  36422,
      #|  36711,
      #|  36856,
      #|  36928,
      #|  36964,
      #|  36982,
      #|  36991,
      #|  36996,
      #|  36998,
      #|  36999,
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
      #|  21000,
      #|  31500,
      #|  36750,
      #|  39375,
      #|  40688,
      #|  41344,
      #|  41672,
      #|  41836,
      #|  41918,
      #|  41959,
      #|  41980,
      #|  41990,
      #|  41995,
      #|  41998,
      #|  41999,
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
      #|[0x64, 0x96, 0xaf, 0xbc, 0xc2, 0xc5, 0xc7, 0x00]
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
      #|  <Bytes: [0x34, 0x37]>,
      #|  <Bytes: [0x4e, 0x37]>,
      #|  <Bytes: [0x5b, 0x37]>,
      #|  <Bytes: [0x61, 0x37]>,
      #|  <Bytes: [0x64, 0x37]>,
      #|  <Bytes: [0x66, 0x37]>,
      #|  <Bytes: [0x00, 0x37]>,
      #|  <Bytes: [0x67, 0x1c]>,
      #|  <Bytes: [0x67, 0x2a]>,
      #|  <Bytes: [0x67, 0x31]>,
      #|  <Bytes: [0x67, 0x34]>,
      #|  <Bytes: [0x67, 0x36]>,
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
      #|[2, 3, 0, 1.8, 2.7, 3.1, 3.3, 3.4, 0]
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
      #|[5.5, -3, -5, 0, -2.8, -4.2, -4.9, -5.2, -5.4, 0]
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
