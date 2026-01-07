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
  @debug.inspect(
    Some("msg"),
    content=(
      #|Some("msg")
    ),
  )
  @debug.inspect(
    @list.from_array(["data1", "data2"]),
    content=(
      #|<List: ["data1", "data2"]>
    ),
  )
}

///|
test "tuple Debug implementations" {
  inspect(
    (1, "a"),
    content=(
      #|(1, "a")
    ),
  )

  // Test tuple3
  inspect(
    (1, "a", true),
    content=(
      #|(1, "a", true)
    ),
  )

  // Test tuple4
  inspect(
    (1, "a", true, 2.0),
    content=(
      #|(1, "a", true, 2)
    ),
  )

  // Test tuple5
  inspect(
    (1, "a", true, 2.0, 'c'),
    content=(
      #|(1, "a", true, 2, 'c')
    ),
  )

  // Test tuple6
  inspect(
    (1, "a", true, 2.0, 'c', 6),
    content=(
      #|(1, "a", true, 2, 'c', 6)
    ),
  )

  // Test tuple7
  inspect(
    (1, "a", true, 2.0, 'c', 6, "g"),
    content=(
      #|(1, "a", true, 2, 'c', 6, "g")
    ),
  )

  // Test tuple8
  inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false),
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
      #|)
    ),
  )

  // Test tuple9
  inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9),
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
      #|)
    ),
  )

  // Test tuple10
  inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j"),
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
      #|)
    ),
  )

  // Test tuple11
  inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11),
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
      #|)
    ),
  )

  // Test tuple12
  inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l"),
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
      #|)
    ),
  )

  // Test tuple13
  inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13),
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
      #|)
    ),
  )

  // Test tuple14
  inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n"),
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
      #|)
    ),
  )

  // Test tuple15
  inspect(
    (1, "a", true, 2.0, 'c', 6, "g", false, 9, "j", 11, "l", 13, "n", 15),
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
      #|)
    ),
  )

  // Test tuple16
  inspect(
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
  inspect(
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
  inspect(
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
  inspect(
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
  inspect(
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
  inspect(
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
  inspect(
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
  inspect((1 : Int16), content="1")
  inspect((1 : UInt16), content="1")
  inspect((1 : UInt64), content="1")
  inspect((1.0 : Float), content="1")
  let b : Bytes = b"ab"
  inspect(b, content="<Bytes: [0x61, 0x62]>")
  let bv : BytesView = b[:]
  inspect(bv, content="<BytesView: [0x61, 0x62]>")
  let sv : StringView = "abc"[:]
  inspect(
    sv,
    content=(
      #|<StringView: "abc">
    ),
  )
  let av : ArrayView[Int] = [1, 2, 3][1:3]
  inspect(av, content="<ArrayView: [2, 3]>")
  let fa : FixedArray[Int] = [1, 2, 3]
  inspect(fa, content="<FixedArray: [1, 2, 3]>")
  let ro : ReadOnlyArray[Int] = [1, 2, 3]
  inspect(ro, content="<ReadOnlyArray: [1, 2, 3]>")
  let lst : @list.List[Int] = @list.from_array([1, 2, 3])
  inspect(lst, content="<List: [1, 2, 3]>")
  let dq : @deque.Deque[Int] = @deque.from_array([1, 2, 3])
  inspect(dq, content="<Deque: [1, 2, 3]>")
  let q : @queue.Queue[Int] = @queue.from_array([1, 2, 3])
  inspect(q, content="<Queue: [1, 2, 3]>")
  let pq : @priority_queue.PriorityQueue[Int] = @priority_queue.from_array([
    3, 1, 2,
  ])
  inspect(pq, content="<PriorityQueue: [3, 2, 1]>")
  let buf = @buffer.new()
  buf.write_bytes(b"ab")
  inspect(buf, content="<Buffer: [0x61, 0x62]>")
  let r : Ref[Int] = @ref.new(1)
  inspect(r, content="<Ref: 1>")
  let mv : MutArrayView[Int] = [1, 2, 3].mut_view(start=1, end=3)
  inspect(mv, content="<MutArrayView: [2, 3]>")
  inspect((Ok(1) : Result[Int, String]), content="Ok(1)")
  inspect(
    (Err("e") : Result[Int, String]),
    content=(
      #|Err("e")
    ),
  )

  // Test immut containers
  let immut_lst = @immut_list.from_array([1, 2, 3])
  inspect(immut_lst, content="<List: [1, 2, 3]>")
  let immut_arr = @immut_array.from_array([1, 2, 3])
  inspect(immut_arr, content="<Array: [1, 2, 3]>")
  let immut_pq = @immut_priority_queue.from_array([3, 1, 2])
  inspect(immut_pq, content="<PriorityQueue: [3, 2, 1]>")
  let immut_sm = @immut_sorted_map.from_array([(1, "a"), (2, "b")])
  inspect(
    immut_sm,
    content=(
      #|<SortedMap:
      #|  { 1: "a", 2: "b" }>
    ),
  )
  let immut_ss = @immut_sorted_set.from_array([3, 1, 2])
  inspect(immut_ss, content="<SortedSet: [1, 2, 3]>")
}

///|
test "Debug for hash-based collections" {
  // The order is unstable.
  let hm : @hashmap.HashMap[Int, String] = @hashmap.from_array([(2, "b")])
  inspect(
    hm,
    content=(
      #|<HashMap: { 2: "b" }>
    ),
  )
  let hs : @hashset.HashSet[Int] = @hashset.from_array([1])
  inspect(hs, content="<HashSet: [1]>")
  let immut_hm = @immut_hashmap.from_array([(2, "b")])
  inspect(
    immut_hm,
    content=(
      #|<HashMap: { 2: "b" }>
    ),
  )
  let immut_hs = @immut_hashset.from_array([3])
  inspect(immut_hs, content="<HashSet: [3]>")
}
