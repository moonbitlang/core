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
  let rs = @splitmix.new(seed=1)
  let _ : @bigint.BigInt = @quickcheck.Arbitrary::arbitrary(1, rs)
}

///|
fn[K : Hash + Eq, V : Eq] verify_hashmap_content(
  map : @hashmap.HashMap[K, V],
  expected : Array[(K, V)],
) -> Unit raise {
  for entry in expected {
    let (k, v) = entry
    assert_true(map.contains_kv(k, v))
  }
  assert_true(map.length() == expected.length())
}

///|
test "Arbitrary for HashMap" {
  let samples : Array[@hashmap.HashMap[String, Int]] = @quickcheck.samples(20)
  let data : ReadOnlyArray[Array[(String, Int)]] = [
    [],
    [],
    [],
    [("", 0)],
    [("", 0)],
    [],
    [],
    [("", 0)],
    [("", 0)],
    [("", 0)],
    [("򹽐f)\u{02}", 3), ("", 0), ("󠃕", -2)],
    [("", 0)],
    [("񌗣j#", 1), ("2", 4), ("", 0), ("&G", 1), ("<F", 0), ("񈻼", -1)],
    [
      ("\u{0b},", 1),
      ("", 0),
      ("D", 4),
      ("}", 0),
      ("l\tX\u{16}񨩶", 1),
      ("⧺]/\u{0e}rDHH\u{15}", 10),
      ("󾥭nV", 0),
      ("󨶏𣷵C\u{13}Vdg񽔊", 3),
      ("\u{1e}", -1),
      ("B\u{1b}䝷\u{00}j", -7),
    ],
    [("򘺔", 2), ("", -2)],
    [("", 0)],
    [
      ("", 0),
      ("<", 0),
      ("0񾿒N", -3),
      ("\u{0f}\n/𲂭", -1),
      ("Bc", 1),
      ("=", 0),
    ],
    [("", 0)],
    [
      ("C\u{0e}\u{16}xT𢜇", -4),
      ("+", 0),
      ("`P񐈏", 11),
      ("", 0),
      ("􉑢", -8),
      ("^h8{", -2),
      ("\b𭑾\b~󨖜\u{1d}e\u{15}YQ", 3),
      ("nv", 4),
      ("%jD𶣸o", 5),
      ("񳌙p!", 0),
      ("񓨾\u{19}f}", 0),
      ("\r񳋐a:򇌒\u{07}", 4),
      ("x", 7),
      ("񩁕򵚭", 1),
    ],
    [
      ("8\u{0e}", 3),
      ("", 2),
      ("U", 1),
      ("4/!\u{1e}\u{10}Rd󠘟V", 3),
      ("(򃵍\u{10}`", -2),
      ("Mb", 0),
      ("EP", 4),
      ("􉞓\u{15}Q\u{07}P?Y", 1),
      ("\u{1d}CY+򏏻񶘶", 5),
      ("𰜫=\u{0f}\u{1d}", 1),
      ("񣙝x6", -2),
    ],
  ]
  for i, sample in samples {
    verify_hashmap_content(sample, data[i])
  }
}

///|
test "Arbitrary for Queue" {
  let samples : Array[@queue.Queue[Int]] = @quickcheck.samples(20)
  debug_inspect(
    samples[1:5],
    content=(
      #|<ArrayView: [<Queue: []>, <Queue: []>, <Queue: [0]>, <Queue: [0]>]>
    ),
  )
  debug_inspect(
    samples[15],
    content=(
      #|<Queue: []>
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
      #|    <SortedMap: {}>,
      #|    <SortedMap: { 0: 0 }>,
      #|    <SortedMap: { 0: 0 }>,
      #|    <SortedMap: { 0: 0 }>,
      #|  ]>
    ),
  )
  debug_inspect(
    map[11:15],
    content=(
      #|<ArrayView:
      #|  [
      #|    <SortedMap: { -3: 2, -1: 1, 0: 0, 2: 1 }>,
      #|    <SortedMap: { 0: 0 }>,
      #|    <SortedMap: { -8: 1, -2: 5, 0: 3, 3: 6, 7: 6 }>,
      #|    <SortedMap: { 0: 0 }>,
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
      #|[(0, ""), (0, ""), (0, ""), (-2, "l>"), (2, "C")]
    ),
  )
  let t : Array[(Int, String, UInt)] = @quickcheck.samples(5)
  debug_inspect(
    t,
    content=(
      #|[(0, "", 0), (0, "", 0), (0, "", 1), (-2, ">s", 0), (2, "\u{11}", 0)]
    ),
  )
  let t : Array[(Int, String, UInt, Byte)] = @quickcheck.samples(5)
  debug_inspect(
    t,
    content=(
      #|[
      #|  (0, "", 0, 0x2a),
      #|  (0, "", 0, 0x77),
      #|  (0, "", 1, 0x0d),
      #|  (-2, ">s", 1, 0x4a),
      #|  (2, "\u{11}", 0, 0xe5),
      #|]
    ),
  )
  let t : Array[(Int, String, UInt, Byte, Char)] = @quickcheck.samples(5)
  debug_inspect(
    t,
    content=(
      #|[
      #|  (0, "", 0, 0x89, 'b'),
      #|  (0, "", 0, 0x3b, '\u{1e}'),
      #|  (0, "", 1, 0x08, '\u{10}'),
      #|  (-2, ">s", 1, 0x23, '\r'),
      #|  (2, "\u{11}", 0, 0xb7, '`'),
      #|]
    ),
  )
  let t : Array[(Int, String, UInt, Byte, Char, Bool)] = @quickcheck.samples(5)
  debug_inspect(
    t,
    content=(
      #|[
      #|  (0, "", 0, 0x89, '񁌝', true),
      #|  (0, "", 0, 0x3b, '\n', true),
      #|  (0, "", 1, 0x08, 'A', true),
      #|  (-2, ">s", 1, 0x23, ';', false),
      #|  (2, "\u{11}", 0, 0xb7, 'D', true),
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
      #|  (0, "", 0, 0x89, '񁌝', false, ()),
      #|  (0, "", 0, 0x3b, '\n', true, ()),
      #|  (0, "", 1, 0x08, 'A', true, ()),
      #|  (-2, ">s", 1, 0x23, ';', true, ()),
      #|  (2, "\u{11}", 0, 0xb7, 'D', true, ()),
      #|]
    ),
  )
}

///|
test "Arbitrary for Ref" {
  let samples = (@quickcheck.samples(3) : Array[@ref.Ref[Int]])
  inspect(samples.length(), content="3")
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
      #|    <PriorityQueue: [0]>,
      #|    <PriorityQueue: [0, 0]>,
      #|    <PriorityQueue: [3, 2, 1, 0, 0, 0, 0]>,
      #|  ]>
    ),
  )
  debug_inspect(
    samples[11:15],
    content=(
      #|<ArrayView:
      #|  [
      #|    <PriorityQueue: [0, 0, 0, -1, -2]>,
      #|    <PriorityQueue: [8, 4, 0, 0, 0, 0, 0, 0, -2, -5]>,
      #|    <PriorityQueue: [2, 0, 0, -1]>,
      #|    <PriorityQueue: [0, 0]>,
      #|  ]>
    ),
  )
}

///|
test "Arbitrary for HashSet" {
  let samples : Array[@hashset.HashSet[Int]] = @quickcheck.samples(20)
  let cases : ReadOnlyArray[@hashset.HashSet[Int]] = [
    @hashset.from_array([]),
    @hashset.from_array([]),
    @hashset.from_array([]),
    @hashset.from_array([0]),
    @hashset.from_array([0]),
    @hashset.from_array([]),
    @hashset.from_array([]),
    @hashset.from_array([0]),
    @hashset.from_array([0]),
    @hashset.from_array([0, 3, 1, 2]),
    @hashset.from_array([0, 1, -2]),
    @hashset.from_array([-2, 0, -1]),
    @hashset.from_array([-5, 0, 8, 4, -2]),
    @hashset.from_array([0, 2, -1]),
    @hashset.from_array([0]),
    @hashset.from_array([]),
    @hashset.from_array([-2, 0, -3, -1]),
    @hashset.from_array([-1, 0, 3, 1, -6, 2]),
    @hashset.from_array([0]),
    @hashset.from_array([-5, -1, 6, 0, 2, -2]),
  ]
  for i in 0..<20 {
    assert_true(samples[i].symmetric_difference(cases[i]).is_empty())
  }
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
      #|  Some(-1),
      #|  Some(0),
      #|  None,
      #|  Some(0),
      #|  Some(-5),
      #|  Some(2),
      #|  None,
      #|  Some(4),
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
