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
test "Arbitrary for BigInt" {
  let samples : Array[@bigint.BigInt] = @quickcheck.samples(10)
  debug_inspect(
    samples,
    content=(
      #|[
      #|  0,
      #|  2236702871533800590,
      #|  4899806414470401660,
      #|  -5076203457455444144,
      #|  -3206590268553584789,
      #|  -8738668918601119554,
      #|  -5822442221117384418,
      #|  4293417177517987002,
      #|  -174397816515637542,
      #|  -7574984457386592187,
      #|]
    ),
  )
}

///|
test "Arbitrary for builtin Map" {
  let samples : Array[Map[Int, Bool]] = @quickcheck.samples(20)
  debug_inspect(
    [samples[0], samples[10], samples[16], samples[19]],
    content=(
      #|[
      #|  {},
      #|  { -1465955831: false },
      #|  {
      #|    1771074214: false,
      #|    -576241283: false,
      #|    2: true,
      #|    1826945462: false,
      #|    803533007: false,
      #|    65535: false,
      #|    99999999: true,
      #|    -32769: false,
      #|    539581892: true,
      #|    2147483647: false,
      #|  },
      #|  {
      #|    1996268401: true,
      #|    1996008401: true,
      #|    -999999: true,
      #|    0: true,
      #|    -2: true,
      #|    1822781582: false,
      #|  },
      #|]
    ),
  )
}

///|
test "Arbitrary for linked Set" {
  let samples : Array[@set.Set[Int]] = @quickcheck.samples(20)
  debug_inspect(
    [samples[0], samples[9], samples[12], samples[17]],
    content=(
      #|[<Set: []>, <Set: []>, <Set: [-2, -1073741824]>, <Set: []>]
    ),
  )
}

///|
test "Arbitrary for Deque" {
  let samples : Array[@deque.Deque[Int]] = @quickcheck.samples(20)
  debug_inspect(
    [samples[0], samples[9], samples[12], samples[17]],
    content=(
      #|[<Deque: []>, <Deque: []>, <Deque: [-2, -1073741824]>, <Deque: []>]
    ),
  )
}

///|
test "Arbitrary for ReadOnlyArray" {
  let samples : Array[ReadOnlyArray[Int]] = @quickcheck.samples(20)
  debug_inspect(
    [samples[0], samples[9], samples[12], samples[17]],
    content=(
      #|[
      #|  <ReadOnlyArray: []>,
      #|  <ReadOnlyArray: []>,
      #|  <ReadOnlyArray: [-2, -1073741824]>,
      #|  <ReadOnlyArray: []>,
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
      #|  [20092, 1001, -1, 255, -2049, 1023, 257, -8568, 128, 0],
      #|  [20092, 1001, 5306, 65534, 62607, 38312, 32769, 45376, 65535, 257],
      #|)
    ),
  )
}

///|
test "Arbitrary for HashMap" {
  let samples : Array[@hashmap.HashMap[String, Int]] = @quickcheck.samples(20)
  let selected = [samples[0], samples[10], samples[13], samples[19]].map(sample => {
    let entries = sample.to_array()
    entries.sort()
    entries
  })
  debug_inspect(
    selected,
    content=(
      #|[
      #|  [],
      #|  [("", -2147483648), ("󠃕", 1345101380), ("򹽐f)\u{02}", -16777217)],
      #|  [
      #|    ("", 2147483646),
      #|    ("\u{1e}", 0),
      #|    ("D", 691939105),
      #|    ("}", -1),
      #|    ("\u{0b},", 2048),
      #|    ("󾥭nV", -1),
      #|    ("B\u{1b}䝷\u{00}j", -1001),
      #|    ("l\tX\u{16}񨩶", -928655867),
      #|    ("⧺]/\u{0e}rDHH\u{15}", -2147483648),
      #|    ("󨶏𣷵C\u{13}Vdg񽔊", 555102954),
      #|  ],
      #|  [
      #|    ("", 0),
      #|    ("U", -31),
      #|    ("8\u{0e}", 954766200),
      #|    ("EP", -2147483647),
      #|    ("Mb", -906462046),
      #|    ("񣙝x6", 130600888),
      #|    ("(򃵍\u{10}`", 1),
      #|    ("𰜫=\u{0f}\u{1d}", 2048),
      #|    ("\u{1d}CY+򏏻񶘶", 0),
      #|    ("􉞓\u{15}Q\u{07}P?Y", -268435457),
      #|    ("4/!\u{1e}\u{10}Rd󠘟V", 2147483646),
      #|  ],
      #|]
    ),
  )
}

///|
test "Arbitrary for Queue" {
  let samples : Array[@queue.Queue[Int]] = @quickcheck.samples(20)
  debug_inspect(
    samples[1:5],
    content=(
      #|<ArrayView:
      #|  [
      #|    <Queue: []>,
      #|    <Queue: []>,
      #|    <Queue: [1073741825]>,
      #|    <Queue: [-1721961329]>,
      #|  ]>
    ),
  )
  debug_inspect(
    samples[15],
    content=(
      #|<Queue:
      #|  [
      #|    -4095,
      #|    1413324993,
      #|    16777215,
      #|    1023,
      #|    -2,
      #|    -1535896498,
      #|    -1000000001,
      #|    -524289,
      #|    196506523,
      #|    -8,
      #|  ]>
    ),
  )
}

///|
test "Arbitrary for SortedSet" {
  let samples = (@quickcheck.samples(3) : Array[@sorted_set.SortedSet[Int]])
  inspect(samples.length(), content="3")
}

///|
test "Arbitrary for SortedMap" {
  let map : Array[@sorted_map.SortedMap[Int, UInt]] = @quickcheck.samples(20)
  debug_inspect(
    map[5:10],
    content=(
      #|<ArrayView:
      #|  [
      #|    <SortedMap: {}>,
      #|    <SortedMap: { 128: 694737253, 16777217: 9999999 }>,
      #|    <SortedMap:
      #|      { -10000000: 3715180460, 33554431: 2492501503, 46354256: 1201652877 }>,
      #|    <SortedMap: {}>,
      #|    <SortedMap:
      #|      {
      #|        -1440561833: 1073741823,
      #|        -10000000: 3561604458,
      #|        -2: 4294967293,
      #|        236090718: 1,
      #|        435439618: 3715395859,
      #|        2147483647: 1,
      #|      }>,
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
      #|        -1073741825: 1,
      #|        -2: 4294967293,
      #|        2: 33554432,
      #|        65536: 3,
      #|        262143: 9999999,
      #|        4194303: 2330119274,
      #|        67108865: 100000001,
      #|        595056541: 857196693,
      #|        683884621: 1,
      #|      }>,
      #|    <SortedMap:
      #|      {
      #|        -2018416849: 2147483648,
      #|        -1525628098: 0,
      #|        -2097151: 31,
      #|        65536: 100000,
      #|      }>,
      #|    <SortedMap:
      #|      {
      #|        -1277792779: 2147483648,
      #|        -1000000001: 999999999,
      #|        -523674093: 3793070879,
      #|        -1: 99999999,
      #|        0: 4286597806,
      #|        2: 954966244,
      #|        129: 11,
      #|        1009307620: 4294967295,
      #|        2147483646: 16383,
      #|      }>,
      #|    <SortedMap:
      #|      {
      #|        -536870911: 880725986,
      #|        -1: 0,
      #|        1: 4294967293,
      #|        9999: 4294967293,
      #|        536870912: 1607291096,
      #|        544347260: 1411634607,
      #|      }>,
      #|  ]>
    ),
  )
}

///|
test "Arbitrary for tuples" {
  let t : Array[(Int, String)] = @quickcheck.samples(5)
  debug_inspect(
    t,
    content=(
      #|[
      #|  (-99999, ""),
      #|  (-134217729, ""),
      #|  (16777217, ""),
      #|  (128, "e򴜞"),
      #|  (33554431, ""),
      #|]
    ),
  )
  let t : Array[(Int, String, UInt)] = @quickcheck.samples(5)
  debug_inspect(
    t,
    content=(
      #|[
      #|  (-99999, "", 2047),
      #|  (-134217729, "", 1023),
      #|  (16777217, "@", 16383),
      #|  (128, "򴜞", 1023),
      #|  (33554431, "\u{05}", 3709967457),
      #|]
    ),
  )
  let t : Array[(Int, String, UInt, Byte)] = @quickcheck.samples(5)
  debug_inspect(
    t,
    content=(
      #|[
      #|  (-99999, "", 228947857, 0x2a),
      #|  (-134217729, "", 101, 0xe5),
      #|  (16777217, "@", 10000001, 0x5a),
      #|  (128, "򴜞", 1532968982, 0x1c),
      #|  (33554431, "\u{05}", 807828953, 0x3d),
      #|]
    ),
  )
  let t : Array[(Int, String, UInt, Byte, Char)] = @quickcheck.samples(5)
  debug_inspect(
    t,
    content=(
      #|[
      #|  (-99999, "", 228947857, 0x89, 'b'),
      #|  (-134217729, "", 101, 0xb7, '`'),
      #|  (16777217, "@", 10000001, 0xd8, '\u{1a}'),
      #|  (128, "򴜞", 1532968982, 0x14, '󠚵'),
      #|  (33554431, "\u{05}", 807828953, 0xfc, '"'),
      #|]
    ),
  )
  let t : Array[(Int, String, UInt, Byte, Char, Bool)] = @quickcheck.samples(5)
  debug_inspect(
    t,
    content=(
      #|[
      #|  (-99999, "", 228947857, 0x89, '񁌝', true),
      #|  (-134217729, "", 101, 0xb7, 'D', true),
      #|  (16777217, "@", 10000001, 0xd8, '\\', false),
      #|  (128, "򴜞", 1532968982, 0x14, 'q', true),
      #|  (33554431, "\u{05}", 807828953, 0xfc, '$', false),
      #|]
    ),
  )
  let t : Array[(Int, String, UInt, Byte, Char, Bool, Unit)] = @quickcheck.samples(
    5,
  )
  debug_inspect(
    t,
    content=(
      #|[
      #|  (-99999, "", 228947857, 0x89, '񁌝', false, ()),
      #|  (-134217729, "", 101, 0xb7, 'D', true, ()),
      #|  (16777217, "@", 10000001, 0xd8, '\\', false, ()),
      #|  (128, "򴜞", 1532968982, 0x14, 'q', false, ()),
      #|  (33554431, "\u{05}", 807828953, 0xfc, '$', true, ()),
      #|]
    ),
  )
}

///|
test "Arbitrary for 8-tuple" {
  let samples : Array[(Int, String, UInt, Byte, Char, Bool, Unit, Int16)] = @quickcheck.samples(
    5,
  )
  debug_inspect(
    samples,
    content=(
      #|[
      #|  (-99999, "", 228947857, 0x89, '񁌝', false, (), -1),
      #|  (-134217729, "", 101, 0xb7, 'D', true, (), 10),
      #|  (16777217, "@", 10000001, 0xd8, '\\', false, (), -10415),
      #|  (128, "򴜞", 1532968982, 0x14, 'q', false, (), -400),
      #|  (33554431, "\u{05}", 807828953, 0xfc, '$', true, (), 2),
      #|]
    ),
  )
}

///|
test "Arbitrary for 9-tuple" {
  let samples : Array[(Int, String, UInt, Byte, Char, Bool, Unit, Int16, Byte)] = @quickcheck.samples(
    5,
  )
  debug_inspect(
    samples,
    content=(
      #|[
      #|  (-99999, "", 228947857, 0x89, '񁌝', false, (), 511, 0x6c),
      #|  (-134217729, "", 101, 0xb7, 'D', true, (), 1000, 0xc0),
      #|  (16777217, "@", 10000001, 0xd8, '\\', false, (), 32766, 0x33),
      #|  (128, "򴜞", 1532968982, 0x14, 'q', false, (), 1024, 0x38),
      #|  (33554431, "\u{05}", 807828953, 0xfc, '$', true, (), -1, 0xa5),
      #|]
    ),
  )
}

///|
test "Arbitrary for Ref" {
  let samples = (@quickcheck.samples(5) : Array[@ref.Ref[Int]])
  debug_inspect(
    samples,
    content=(
      #|[
      #|  <Ref: 1118850684>,
      #|  <Ref: -99999>,
      #|  <Ref: 846697896>,
      #|  <Ref: -134217729>,
      #|  <Ref: 67108863>,
      #|]
    ),
  )
}

///|
test "Arbitrary for PriorityQueue" {
  let samples : Array[@priority_queue.PriorityQueue[Int]] = @quickcheck.samples(
    20,
  )
  debug_inspect(
    samples[5:10],
    content=(
      #|<ArrayView:
      #|  [
      #|    <PriorityQueue: []>,
      #|    <PriorityQueue: []>,
      #|    <PriorityQueue: [67108863, 16777217, -134217729]>,
      #|    <PriorityQueue: [1144392696, 311628954, 128, -2, -65535, -999999999]>,
      #|    <PriorityQueue: []>,
      #|  ]>
    ),
  )
  debug_inspect(
    samples[11:15],
    content=(
      #|<ArrayView:
      #|  [
      #|    <PriorityQueue: [1, 0, -1025403238]>,
      #|    <PriorityQueue: [-2, -1073741824]>,
      #|    <PriorityQueue:
      #|      [
      #|        2147483647,
      #|        2147483646,
      #|        268435455,
      #|        7,
      #|        -64,
      #|        -1344599372,
      #|        -1465955831,
      #|        -1561148302,
      #|      ]>,
      #|    <PriorityQueue:
      #|      [
      #|        595056541,
      #|        67108865,
      #|        4194303,
      #|        65536,
      #|        513,
      #|        2,
      #|        2,
      #|        -2,
      #|        -2,
      #|        -262145,
      #|        -11086542,
      #|        -261363602,
      #|      ]>,
      #|  ]>
    ),
  )
}

///|
test "Arbitrary for HashSet" {
  let samples : ArrayView[@hashset.HashSet[Int]] = @quickcheck.samples(20)[8:12]
  debug_inspect(
    samples,
    content=(
      #|<ArrayView:
      #|  [
      #|    <HashSet: [-999999999, -2, 1144392696, -65535, 128, 311628954]>,
      #|    <HashSet: []>,
      #|    <HashSet: [322263955, -613468993, -1609132827]>,
      #|    <HashSet: [0, -1025403238, 1]>,
      #|  ]>
    ),
  )
}

///|
test "Option arbitrary" {
  let samples : Array[Int?] = @quickcheck.samples(10)
  debug_inspect(
    samples,
    content=(
      #|[
      #|  None,
      #|  None,
      #|  Some(1073741825),
      #|  Some(-1721961329),
      #|  Some(-1),
      #|  Some(1677256795),
      #|  Some(-1497190080),
      #|  None,
      #|  None,
      #|  Some(16777217),
      #|]
    ),
  )
}

///|
test "Arbitrary for immutable vector" {
  let samples = (@quickcheck.samples(3) : Array[@immut_vector.Vector[Int]])
  inspect(samples.length(), content="3")
}

///|
test "Arbitrary for immutable hashmap" {
  let samples : Array[@immut_hashmap.HashMap[Int, Int]] = @quickcheck.samples(
    10,
  )
  inspect(samples.length(), content="10")
}

///|
test "Arbitrary for immutable hashset" {
  let set : @immut_hashset.HashSet[Int] = @quickcheck.gen(size=10)
  let roundtrip = @immut_hashset.HashSet(set.iter().to_array())
  inspect(set == roundtrip, content="true")
}

///|
test "Arbitrary for immutable priority queue" {
  let samples : Array[@immut_priority_queue.PriorityQueue[Int]] = @quickcheck.samples(
    10,
  )
  inspect(samples.length(), content="10")
  inspect(
    samples.all(queue => queue.length() == queue.to_array().length()),
    content="true",
  )
}
