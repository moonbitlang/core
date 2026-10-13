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
fn is_power_of_two_bigint(value : @bigint.BigInt) -> Bool {
  value > 0N && (value & (value - 1N)) == 0N
}

///|
fn is_noncanonical_binary_boundary_bigint(value : @bigint.BigInt) -> Bool {
  let magnitude = if value < 0N { -value } else { value }
  magnitude > 10N &&
  [-1N, 0N, 1N].any(offset => is_power_of_two_bigint(magnitude + offset))
}

///|
test "Arbitrary for BigInt" {
  let samples : Array[@bigint.BigInt] = @quickcheck.samples(10)
  debug_inspect(
    samples,
    content=(
      #|[
      #|  625723451123566979,
      #|  9007199254740992,
      #|  -9513953816843832505,
      #|  -10,
      #|  2147483647,
      #|  388887127654859726275711508334709718284902566256656234085892195101315050381702870505752361834313,
      #|  2,
      #|  1,
      #|  16555243947080179383,
      #|  2,
      #|]
    ),
  )
}

///|
test "Arbitrary for BigInt favors boundaries across multiple limbs" {
  let samples : Array[@bigint.BigInt] = @quickcheck.samples(256)
  let canonical : Array[@bigint.BigInt] = [0N, 1N, -1N, 2N, -2N, 10N, -10N]
  let count : ((@bigint.BigInt) -> Bool) -> Int32 = predicate => {
    samples.iter().filter(predicate).count()
  }
  let is_wide : (@bigint.BigInt) -> Bool = value => value.bit_length() > 64
  let canonical_count = count(value => canonical.contains(value))
  let binary_boundary_count = count(is_noncanonical_binary_boundary_bigint)
  let wide_count = count(is_wide)
  let positive_wide_count = count(value => value > 0N && is_wide(value))
  let negative_wide_count = count(value => value < 0N && is_wide(value))
  let max_bit_length = samples.fold(init=0, (maximum, value) => {
    maximum.max(value.bit_length())
  })
  // canonical, binary boundary, wide, positive wide, negative wide, maximum bits
  debug_inspect(
    (
      canonical_count, binary_boundary_count, wide_count, positive_wide_count, negative_wide_count,
      max_bit_length,
    ),
    content=(
      #|(87, 53, 68, 33, 35, 768)
    ),
  )
}

///|
test "Arbitrary for builtin Map" {
  let samples : Array[Map[Int32, Bool]] = @quickcheck.samples(20)
  debug_inspect(
    [samples[0], samples[10], samples[16], samples[19]],
    content=(
      #|[
      #|  {},
      #|  { 1: true, -1023: false },
      #|  {
      #|    -2: true,
      #|    -1046276922: false,
      #|    1160700466: true,
      #|    -2147483648: true,
      #|    2: true,
      #|    536870912: true,
      #|    -1886994959: false,
      #|    1569984796: true,
      #|  },
      #|  { -2147483647: false, 1024: false, -1: true },
      #|]
    ),
  )
}

///|
test "Arbitrary for linked Set" {
  let samples : Array[@set.Set[Int32]] = @quickcheck.samples(20)
  debug_inspect(
    [samples[0], samples[9], samples[12], samples[17]],
    content=(
      #|[
      #|  <Set: []>,
      #|  <Set: [-1917693499, -2, -1677803622, 182122774, 134217729, 2]>,
      #|  <Set: [-1, 1727828472, 2147483646, -180216139, 2, -99, -2147483647]>,
      #|  <Set:
      #|    [
      #|      -8192,
      #|      -1,
      #|      1405857119,
      #|      -2,
      #|      -1000000,
      #|      2,
      #|      773703614,
      #|      536870912,
      #|      -1867690344,
      #|      -1886994959,
      #|    ]>,
      #|]
    ),
  )
}

///|
test "Arbitrary for Deque" {
  let samples : Array[@deque.Deque[Int32]] = @quickcheck.samples(20)
  debug_inspect(
    [samples[0], samples[9], samples[12], samples[17]],
    content=(
      #|[
      #|  <Deque: []>,
      #|  <Deque: [-1917693499, -2, -1677803622, 182122774, 134217729, 2]>,
      #|  <Deque: [-1, 1727828472, 2147483646, -180216139, 2, -99, -2147483647]>,
      #|  <Deque:
      #|    [
      #|      -8192,
      #|      -1,
      #|      1405857119,
      #|      -2,
      #|      -1000000,
      #|      2,
      #|      773703614,
      #|      536870912,
      #|      -1867690344,
      #|      -1886994959,
      #|    ]>,
      #|]
    ),
  )
}

///|
test "Arbitrary for ReadOnlyArray" {
  let samples : Array[ReadOnlyArray[Int32]] = @quickcheck.samples(20)
  debug_inspect(
    [samples[0], samples[9], samples[12], samples[17]],
    content=(
      #|[
      #|  <ReadOnlyArray: []>,
      #|  <ReadOnlyArray:
      #|    [-1917693499, -2, -1677803622, 182122774, 134217729, 2]>,
      #|  <ReadOnlyArray:
      #|    [-1, 1727828472, 2147483646, -180216139, 2, -99, -2147483647]>,
      #|  <ReadOnlyArray:
      #|    [
      #|      -8192,
      #|      -1,
      #|      1405857119,
      #|      -2,
      #|      -1000000,
      #|      2,
      #|      773703614,
      #|      536870912,
      #|      -1867690344,
      #|      -1886994959,
      #|    ]>,
      #|]
    ),
  )
}

///|
test "Arbitrary for 16-bit integers" {
  let signed_samples : Array[Int16] = @quickcheck.samples(10)
  let unsigned_samples : Array[UInt16] = @quickcheck.samples(10)
  debug_inspect(
    (signed_samples, unsigned_samples),
    content=(
      #|(
      #|  [25352, -2, -1, 13699, -16384, 0, -9852, -4774, 23006, 512],
      #|  [25352, 0, 3, 65534, 15048, 512, 0, 55684, 60762, 23006],
      #|)
    ),
  )
}

///|
test "Arbitrary for HashMap" {
  let samples : Array[@hashmap.HashMap[String, Int32]] = @quickcheck.samples(20)
  let selected = [samples[0], samples[10], samples[13], samples[19]].map(sample => {
    let entries = sample.to_array()
    entries.sort()
    entries
  })
  debug_inspect(
    selected,
    content=(
      #|[[], [("", -387504128), ("}", -2050939245)], [], [("", 0)]]
    ),
  )
}

///|
test "Arbitrary for Queue" {
  let samples : Array[@queue.Queue[Int32]] = @quickcheck.samples(20)
  debug_inspect(
    samples[1:5],
    content=(
      #|<ArrayView: [<Queue: []>, <Queue: []>, <Queue: []>, <Queue: []>]>
    ),
  )
  debug_inspect(
    samples[15],
    content=(
      #|<Queue:
      #|  [
      #|    2,
      #|    10000001,
      #|    -1934376517,
      #|    -1,
      #|    8388607,
      #|    67108863,
      #|    2,
      #|    -9,
      #|    -1001,
      #|    422821340,
      #|    -9,
      #|    -256,
      #|  ]>
    ),
  )
}

///|
test "Arbitrary for SortedSet" {
  let samples = (@quickcheck.samples(3) : Array[@sorted_set.SortedSet[Int32]])
  inspect(samples.length(), content="3")
}

///|
test "Arbitrary for SortedMap" {
  let map : Array[@sorted_map.SortedMap[Int32, UInt32]] = @quickcheck.samples(
    20,
  )
  debug_inspect(
    map[5:10],
    content=(
      #|<ArrayView:
      #|  [
      #|    <SortedMap: { -1510023416: 1, -1: 3275749438, 534197635: 2934521921 }>,
      #|    <SortedMap: {}>,
      #|    <SortedMap: { 63: 100, 33554432: 4294967295 }>,
      #|    <SortedMap:
      #|      {
      #|        1: 3759496233,
      #|        2: 1983292812,
      #|        4194303: 999999,
      #|        134217729: 0,
      #|        917696847: 3922029807,
      #|      }>,
      #|    <SortedMap:
      #|      { -2147483647: 0, -1225668791: 4294967295, -2: 2612208397, -1: 16383 }>,
      #|  ]>
    ),
  )
  debug_inspect(
    map[11:15],
    content=(
      #|<ArrayView:
      #|  [
      #|    <SortedMap:
      #|      {
      #|        -2040872899: 3507395928,
      #|        -1241482405: 0,
      #|        -129: 2928500796,
      #|        -99: 3907463168,
      #|        -9: 3491974036,
      #|        -1: 2056695795,
      #|        2: 4294967293,
      #|        555115237: 0,
      #|        2147483646: 1025,
      #|      }>,
      #|    <SortedMap: {}>,
      #|    <SortedMap:
      #|      {
      #|        -1550002727: 0,
      #|        -1: 1959726336,
      #|        1: 2,
      #|        10001: 4294967295,
      #|        669512388: 2,
      #|        772627794: 3,
      #|        895571608: 63,
      #|      }>,
      #|    <SortedMap: { -1001: 1905759605, -9: 3849031099, -2: 2 }>,
      #|  ]>
    ),
  )
}

///|
test "Arbitrary for tuples" {
  let t : Array[(Int32, String)] = @quickcheck.samples(5)
  debug_inspect(
    t,
    content=(
      #|[
      #|  (-2, ""),
      #|  (-2147483647, ""),
      #|  (512, ""),
      #|  (-1510023416, "f."),
      #|  (2147483646, ""),
      #|]
    ),
  )
  let t : Array[(Int32, String, UInt32)] = @quickcheck.samples(5)
  debug_inspect(
    t,
    content=(
      #|[
      #|  (-2, "", 10001),
      #|  (-2147483647, "", 1000000000),
      #|  (512, "\u{04}", 0),
      #|  (-1510023416, ".Y", 4138808970),
      #|  (2147483646, "H󝯋", 434966720),
      #|]
    ),
  )
  let t : Array[(Int32, String, UInt32, Byte)] = @quickcheck.samples(5)
  debug_inspect(
    t,
    content=(
      #|[
      #|  (-2, "", 512, 0x35),
      #|  (-2147483647, "", 4294967294, 0xdc),
      #|  (512, "\u{04}", 3512878256, 0x34),
      #|  (-1510023416, ".Y", 105848422, 0xb1),
      #|  (2147483646, "H󝯋", 4082111986, 0x42),
      #|]
    ),
  )
  let t : Array[(Int32, String, UInt32, Byte, Char)] = @quickcheck.samples(5)
  debug_inspect(
    t,
    content=(
      #|[
      #|  (-2, "", 512, 0xa7, 's'),
      #|  (-2147483647, "", 4294967294, 0xa8, '\u{e08a}'),
      #|  (512, "\u{04}", 3512878256, 0x82, 'b'),
      #|  (-1510023416, ".Y", 105848422, 0x39, '𝂂'),
      #|  (2147483646, "H󝯋", 4082111986, 0xe8, '\\'),
      #|]
    ),
  )
  let t : Array[(Int32, String, UInt32, Byte, Char, Bool)] = @quickcheck.samples(
    5,
  )
  debug_inspect(
    t,
    content=(
      #|[
      #|  (-2, "", 512, 0xa7, '񍵫', true),
      #|  (-2147483647, "", 4294967294, 0xa8, '\u{11}', false),
      #|  (512, "\u{04}", 3512878256, 0x82, '𠢬', false),
      #|  (-1510023416, ".Y", 105848422, 0x39, '\u{1069b3}', false),
      #|  (2147483646, "H󝯋", 4082111986, 0xe8, '@', true),
      #|]
    ),
  )
  let t : Array[(Int32, String, UInt32, Byte, Char, Bool, Unit)] = @quickcheck.samples(
    5,
  )
  debug_inspect(
    t,
    content=(
      #|[
      #|  (-2, "", 512, 0xa7, '񍵫', false, ()),
      #|  (-2147483647, "", 4294967294, 0xa8, '\u{11}', true, ()),
      #|  (512, "\u{04}", 3512878256, 0x82, '𠢬', true, ()),
      #|  (-1510023416, ".Y", 105848422, 0x39, '\u{1069b3}', true, ()),
      #|  (2147483646, "H󝯋", 4082111986, 0xe8, '@', true, ()),
      #|]
    ),
  )
}

///|
test "Arbitrary for 8-tuple" {
  let samples : Array[(Int32, String, UInt32, Byte, Char, Bool, Unit, Int16)] = @quickcheck.samples(
    5,
  )
  debug_inspect(
    samples,
    content=(
      #|[
      #|  (-2, "", 512, 0xa7, '񍵫', false, (), 1),
      #|  (-2147483647, "", 4294967294, 0xa8, '\u{11}', true, (), -1025),
      #|  (512, "\u{04}", 3512878256, 0x82, '𠢬', true, (), -1),
      #|  (-1510023416, ".Y", 105848422, 0x39, '\u{1069b3}', true, (), -10000),
      #|  (2147483646, "H󝯋", 4082111986, 0xe8, '@', true, (), 17),
      #|]
    ),
  )
}

///|
test "Arbitrary for 9-tuple" {
  let samples : Array[
    (Int32, String, UInt32, Byte, Char, Bool, Unit, Int16, Byte),
  ] = @quickcheck.samples(5)
  debug_inspect(
    samples,
    content=(
      #|[
      #|  (-2, "", 512, 0xa7, '񍵫', false, (), 1, 0x94),
      #|  (-2147483647, "", 4294967294, 0xa8, '\u{11}', true, (), -13361, 0x5a),
      #|  (512, "\u{04}", 3512878256, 0x82, '𠢬', true, (), 19986, 0xd7),
      #|  (-1510023416, ".Y", 105848422, 0x39, '\u{1069b3}', true, (), 2, 0xe1),
      #|  (2147483646, "H󝯋", 4082111986, 0xe8, '@', true, (), -10080, 0xac),
      #|]
    ),
  )
}

///|
test "Arbitrary for Ref" {
  let samples = (@quickcheck.samples(5) : Array[@ref.Ref[Int32]])
  debug_inspect(
    samples,
    content=(
      #|[
      #|  <Ref: -1757125880>,
      #|  <Ref: -2>,
      #|  <Ref: -1>,
      #|  <Ref: 534197635>,
      #|  <Ref: -1073741824>,
      #|]
    ),
  )
}

///|
test "Arbitrary for PriorityQueue" {
  let samples : Array[@priority_queue.PriorityQueue[Int32]] = @quickcheck.samples(
    20,
  )
  debug_inspect(
    samples[5:10],
    content=(
      #|<ArrayView:
      #|  [
      #|    <PriorityQueue: [2147483646, 534197635, -1073741824]>,
      #|    <PriorityQueue: [-1009767549, -1510023416]>,
      #|    <PriorityQueue: [90462686]>,
      #|    <PriorityQueue: [2147483646, 71960070, 33554432, 63, 2, -1045010830]>,
      #|    <PriorityQueue:
      #|      [182122774, 134217729, 2, -2, -1677803622, -1917693499]>,
      #|  ]>
    ),
  )
  debug_inspect(
    samples[11:15],
    content=(
      #|<ArrayView:
      #|  [
      #|    <PriorityQueue: [906256478, 8388608, 4095, 2, 1, -1023, -1902283067]>,
      #|    <PriorityQueue:
      #|      [2147483646, 1727828472, 2, -1, -99, -180216139, -2147483647]>,
      #|    <PriorityQueue:
      #|      [
      #|        555115237,
      #|        413164747,
      #|        114680314,
      #|        0,
      #|        -1,
      #|        -9,
      #|        -33,
      #|        -16385,
      #|        -2040872899,
      #|        -2147483648,
      #|      ]>,
      #|    <PriorityQueue: [895571608, -2147483647]>,
      #|  ]>
    ),
  )
}

///|
test "Arbitrary for HashSet" {
  let samples : ArrayView[@hashset.HashSet[Int32]] = @quickcheck.samples(20)[8:12]
  let selected = samples.map(sample => {
    let values = sample.to_array()
    values.sort()
    values
  })
  debug_inspect(
    selected,
    content=(
      #|[
      #|  [-1045010830, 2, 63, 33554432, 71960070, 2147483646],
      #|  [-1917693499, -1677803622, -2, 2, 134217729, 182122774],
      #|  [-2147483647, -1073741823, -245180965, 1, 310279802, 2147483647],
      #|  [-1902283067, -1023, 1, 2, 4095, 8388608, 906256478],
      #|]
    ),
  )
}

///|
test "Option arbitrary" {
  let samples : Array[Int32?] = @quickcheck.samples(10)
  debug_inspect(
    samples,
    content=(
      #|[
      #|  None,
      #|  None,
      #|  Some(895428393),
      #|  Some(-2147483647),
      #|  None,
      #|  Some(512),
      #|  Some(392092036),
      #|  Some(2147483646),
      #|  Some(33554432),
      #|  None,
      #|]
    ),
  )
}

///|
test "Arbitrary for immutable vector" {
  let samples = (@quickcheck.samples(3) : Array[@immut_vector.Vector[Int32]])
  inspect(samples.length(), content="3")
}

///|
test "Arbitrary for immutable hashmap" {
  let samples : Array[@immut_hashmap.HashMap[Int32, Int32]] = @quickcheck.samples(
    10,
  )
  inspect(samples.length(), content="10")
}

///|
test "Arbitrary for immutable hashset" {
  let set : @immut_hashset.HashSet[Int32] = @quickcheck.gen(size=10)
  let roundtrip = @immut_hashset.HashSet(set.iter().to_array())
  inspect(set == roundtrip, content="true")
}

///|
test "Arbitrary for immutable priority queue" {
  let samples : Array[@immut_priority_queue.PriorityQueue[Int32]] = @quickcheck.samples(
    10,
  )
  inspect(samples.length(), content="10")
  inspect(
    samples.all(queue => queue.length() == queue.to_array().length()),
    content="true",
  )
}
