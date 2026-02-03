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
test "inspect" {
  @debug.debug_inspect(
    Some("msg"),
    content=(
      #|Some("msg")
    ),
  )
  @debug.debug_inspect(
    @list.from_array(["data1", "data2"]),
    content=(
      #|<List: ["data1", "data2"]>
    ),
  )
}

///|
test "tuple Debug implementations" {
  @debug.debug_inspect(
    (1, "a"),
    content=(
      #|(1, "a")
    ),
  )

  // Test tuple3
  @debug.debug_inspect(
    (1, "a", true),
    content=(
      #|(1, "a", true)
    ),
  )

  // Test tuple4
  @debug.debug_inspect(
    (1, "a", true, 2.0),
    content=(
      #|(1, "a", true, 2)
    ),
  )

  // Test tuple5
  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c'),
    content=(
      #|(1, "a", true, 2, 'c')
    ),
  )

  // Test tuple6
  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6),
    content=(
      #|(1, "a", true, 2, 'c', 6)
    ),
  )

  // Test tuple7
  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g"),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g")
    ),
  )

  // Test tuple8
  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false)
    ),
  )

  // Test tuple9
  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9)
    ),
  )

  // Test tuple10
  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j"),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j")
    ),
  )

  // Test tuple11
  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11)
    ),
  )

  // Test tuple12
  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l"),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11, "l")
    ),
  )

  // Test tuple13
  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11, "l", 13)
    ),
  )

  // Test tuple14
  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n"),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n")
    ),
  )

  // Test tuple15
  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15)
    ),
  )

  // Test tuple16
  @debug.debug_inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p"),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|)
    ),
  )

  // Test tuple17
  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|)
    ),
  )

  // Test tuple18
  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r",
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|)
    ),
  )

  // Test tuple19
  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r", 19,
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|  19,
      #|)
    ),
  )

  // Test tuple20
  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r", 19, "t",
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|  19,
      #|  "t",
      #|)
    ),
  )

  // Test tuple21
  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r", 19, "t", 21,
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|  19,
      #|  "t",
      #|  21,
      #|)
    ),
  )

  // Test tuple22
  @debug.debug_inspect(
    (
      1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15, "p", 17,
      "r", 19, "t", 21, "v",
    ),
    content=(
      #|(
      #|  1,
      #|  "a",
      #|  true,
      #|  2,
      #|  'c',
      #|  6,
      #|  "g",
      #|  false,
      #|  9,
      #|  "j",
      #|  11,
      #|  "l",
      #|  13,
      #|  "n",
      #|  15,
      #|  "p",
      #|  17,
      #|  "r",
      #|  19,
      #|  "t",
      #|  21,
      #|  "v",
      #|)
    ),
  )
}

///|
#warnings("-deprecated")
test "core data structures Debug implementations" {
  @debug.debug_inspect((1 : Int16), content="1")
  @debug.debug_inspect((1 : UInt16), content="1")
  @debug.debug_inspect((1 : UInt64), content="1")
  @debug.debug_inspect((1.0 : Float), content="1")
  let b : Bytes = b"ab"
  @debug.debug_inspect(b, content="<Bytes: [0x61, 0x62]>")
  let bv : BytesView = b[:]
  @debug.debug_inspect(bv, content="<BytesView: [0x61, 0x62]>")
  let sv : StringView = "abc"[:]
  @debug.debug_inspect(
    sv,
    content=(
      #|<StringView: "abc">
    ),
  )
  let av : ArrayView[Int] = [1, 2, 3][1:3]
  @debug.debug_inspect(av, content="<ArrayView: [2, 3]>")
  let fa : FixedArray[Int] = [1, 2, 3]
  @debug.debug_inspect(fa, content="<FixedArray: [1, 2, 3]>")
  let ro : ReadOnlyArray[Int] = [1, 2, 3]
  @debug.debug_inspect(ro, content="<ReadOnlyArray: [1, 2, 3]>")
  let lst : @list.List[Int] = @list.from_array([1, 2, 3])
  @debug.debug_inspect(lst, content="<List: [1, 2, 3]>")
  let dq : @deque.Deque[Int] = @deque.from_array([1, 2, 3])
  @debug.debug_inspect(dq, content="<Deque: [1, 2, 3]>")
  let q : @queue.Queue[Int] = @queue.from_array([1, 2, 3])
  @debug.debug_inspect(q, content="<Queue: [1, 2, 3]>")
  let pq : @priority_queue.PriorityQueue[Int] = @priority_queue.from_array([
    3, 1, 2,
  ])
  @debug.debug_inspect(pq, content="<PriorityQueue: [3, 2, 1]>")
  let buf = @buffer.new()
  buf.write_bytes(b"ab")
  @debug.debug_inspect(buf, content="<Buffer: [0x61, 0x62]>")
  let r : Ref[Int] = @ref.new(1)
  @debug.debug_inspect(r, content="<Ref: 1>")
  let mv : MutArrayView[Int] = [1, 2, 3].mut_view(start=1, end=3)
  @debug.debug_inspect(mv, content="<MutArrayView: [2, 3]>")
  @debug.debug_inspect((Ok(1) : Result[Int, String]), content="Ok(1)")
  @debug.debug_inspect(
    (Err("e") : Result[Int, String]),
    content=(
      #|Err("e")
    ),
  )

  // Test immut containers
  let immut_arr = @immut_array.from_array([1, 2, 3])
  @debug.debug_inspect(immut_arr, content="<Array: [1, 2, 3]>")
  let immut_pq = @immut_priority_queue.from_array([3, 1, 2])
  @debug.debug_inspect(immut_pq, content="<PriorityQueue: [3, 2, 1]>")
  let immut_sm = @immut_sorted_map.from_array([(1, "a"), (2, "b")])
  @debug.debug_inspect(
    immut_sm,
    content=(
      #|<SortedMap: { 1: "a", 2: "b" }>
    ),
  )
  let immut_ss = @immut_sorted_set.from_array([3, 1, 2])
  @debug.debug_inspect(immut_ss, content="<SortedSet: [1, 2, 3]>")
}

///|
test "Debug for hash-based collections" {
  // The order is unstable.
  let hm : @hashmap.HashMap[Int, String] = @hashmap.from_array([(2, "b")])
  @debug.debug_inspect(
    hm,
    content=(
      #|<HashMap: { 2: "b" }>
    ),
  )
  let hs : @hashset.HashSet[Int] = @hashset.from_array([1])
  @debug.debug_inspect(hs, content="<HashSet: [1]>")
  let immut_hm = @immut_hashmap.from_array([(2, "b")])
  @debug.debug_inspect(
    immut_hm,
    content=(
      #|<HashMap: { 2: "b" }>
    ),
  )
  let immut_hs = @immut_hashset.from_array([3])
  @debug.debug_inspect(immut_hs, content="<HashSet: [3]>")
}

///|
fn output(x : Result[Unit, Error]) -> String {
  match x {
    Err(Failure::Failure(s)) => s
    Ok(_) => "ok"
    Err(e) => "\{e}"
  }
}

///|
test "assert_eq" {
  inspect(output(try? @debug.assert_eq(1, 1)), content="ok")
  inspect(
    output(try? @debug.assert_eq(1, 2)),
    content=(
      #|debug_blackbox_test/debug_test.mbt:459:17-459:39@moonbitlang/core FAILED: `1 != 2`
      #|diff:
      #|-1 +2
    ),
  )
  inspect(
    output(try? @debug.assert_eq("a", "b")),
    content=(
      #|debug_blackbox_test/debug_test.mbt:467:17-467:43@moonbitlang/core FAILED: `"a" != "b"`
      #|diff:
      #|-"a" +"b"
    ),
  )
  inspect(output(try? @debug.assert_eq([1, 2, 3], [1, 2, 3])), content="ok")
  inspect(
    output(try? @debug.assert_eq([1, 2, 3], [1, 222, 3])),
    content=(
      #|debug_blackbox_test/debug_test.mbt:477:17-477:57@moonbitlang/core FAILED: `[1, 2, 3] != [1, 222, 3]`
      #|diff:
      #|[1, -2 +222, 3]
    ),
  )
  inspect(
    output(try? @debug.assert_eq((true, "string", 123), (true, "s", 1))),
    content=(
      #|debug_blackbox_test/debug_test.mbt:486:17-486:72@moonbitlang/core FAILED: `(true, "string", 123) != (true, "s", 1)`
      #|diff:
      #|(true, -"string" +"s", -123 +1)
    ),
  )
  inspect(
    output(try? @debug.assert_eq({ "k1": 1.0, "k2": 2 }, { "k1": 2, "k3": 5 })),
    content=(
      #|debug_blackbox_test/debug_test.mbt:495:17-495:79@moonbitlang/core FAILED: `{ "k1": 1, "k2": 2 } != { "k1": 2, "k3": 5 }`
      #|diff:
      #|{ "k1": -1 +2, -"k2": 2 +"k3": 5 }
    ),
  )
  inspect(
    output(try? @debug.assert_eq(1, 2, msg="numbers mismatch")),
    content="debug_blackbox_test/debug_test.mbt:504:17-504:63@moonbitlang/core FAILED: numbers mismatch",
  )
  inspect(
    output(try? @debug.assert_eq(Some(1), Some(2))),
    content=(
      #|debug_blackbox_test/debug_test.mbt:508:17-508:51@moonbitlang/core FAILED: `Some(1) != Some(2)`
      #|diff:
      #|Some(-1 +2)
    ),
  )
  inspect(
    output(try? @debug.assert_eq(Result::Ok(1), Err("e"))),
    content=(
      #|debug_blackbox_test/debug_test.mbt:517:17-517:58@moonbitlang/core FAILED: `Ok(1) != Err("e")`
      #|diff:
      #|-Ok(1) +Err("e")
    ),
  )
}

///|
test "assert_eq for arrays" {
  inspect(
    output(try? @debug.assert_eq([1, 2], [1, 2, 3])),
    content=(
      #|debug_blackbox_test/debug_test.mbt:533:17-533:52@moonbitlang/core FAILED: `[1, 2] != [1, 2, 3]`
      #|diff:
      #|[1, 2, +3]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([1, 2], [1, 2, 3, 4])),
    content=(
      #|debug_blackbox_test/debug_test.mbt:549:17-549:55@moonbitlang/core FAILED: `[1, 2] != [1, 2, 3, 4]`
      #|diff:
      #|[1, 2, +3, +4]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([1, 2, 3], [1, 2])),
    content=(
      #|debug_blackbox_test/debug_test.mbt:559:17-559:52@moonbitlang/core FAILED: `[1, 2, 3] != [1, 2]`
      #|diff:
      #|[1, 2, -3]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([1, 2, 3, 4], [1, 2])),
    content=(
      #|debug_blackbox_test/debug_test.mbt:568:17-568:55@moonbitlang/core FAILED: `[1, 2, 3, 4] != [1, 2]`
      #|diff:
      #|[1, 2, -3, -4]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([1, 2, 3, 4], [1, 4])),
    content=(
      #|debug_blackbox_test/debug_test.mbt:577:17-577:55@moonbitlang/core FAILED: `[1, 2, 3, 4] != [1, 4]`
      #|diff:
      #|[1, -2 +4, -3, -4]
    ),
  )
  inspect(
    output(try? @debug.assert_eq([1, 4], [1, 2, 3, 4])),
    content=(
      #|debug_blackbox_test/debug_test.mbt:586:17-586:55@moonbitlang/core FAILED: `[1, 4] != [1, 2, 3, 4]`
      #|diff:
      #|[1, -4 +2, +3, +4]
    ),
  )
}
