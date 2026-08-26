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
test "shrink option" {
  debug_inspect(
    @shrink.Shrink::shrink((None : Unit?)).collect(),
    content=(
      #|[]
    ),
  )
  debug_inspect(
    @shrink.Shrink::shrink(Some(1000)).collect(),
    content=(
      #|[
      #|  Some(999),
      #|  Some(997),
      #|  Some(993),
      #|  Some(985),
      #|  Some(969),
      #|  Some(938),
      #|  Some(875),
      #|  Some(750),
      #|  Some(500),
      #|  Some(0),
      #|  None,
      #|]
    ),
  )
}

///|
test "shrink result" {
  let b : Result[Bool, Int] = Err(100)
  let x : Result[Bool, Int] = Ok(true)
  debug_inspect(
    @shrink.Shrink::shrink(b).collect(),
    content=(
      #|[Err(99), Err(97), Err(94), Err(88), Err(75), Err(50), Err(0)]
    ),
  )
  debug_inspect(
    @shrink.Shrink::shrink(x).collect(),
    content=(
      #|[Ok(false)]
    ),
  )
}

///|
test "shrink array" {
  let ar = [1, 2, 3, 4, 5, 6]
  debug_inspect(
    @shrink.Shrink::shrink(ar).collect(),
    content=(
      #|[
      #|  [],
      #|  [4, 5, 6],
      #|  [1, 2, 3],
      #|  [2, 3, 4, 5, 6],
      #|  [1, 3, 4, 5, 6],
      #|  [1, 2, 4, 5, 6],
      #|  [1, 2, 3, 5, 6],
      #|  [1, 2, 3, 4, 6],
      #|  [1, 2, 3, 4, 5],
      #|  [0, 2, 3, 4, 5, 6],
      #|  [1, 1, 3, 4, 5, 6],
      #|  [1, 0, 3, 4, 5, 6],
      #|  [1, 2, 2, 4, 5, 6],
      #|  [1, 2, 0, 4, 5, 6],
      #|  [1, 2, 3, 3, 5, 6],
      #|  [1, 2, 3, 2, 5, 6],
      #|  [1, 2, 3, 0, 5, 6],
      #|  [1, 2, 3, 4, 4, 6],
      #|  [1, 2, 3, 4, 3, 6],
      #|  [1, 2, 3, 4, 0, 6],
      #|  [1, 2, 3, 4, 5, 5],
      #|  [1, 2, 3, 4, 5, 3],
      #|  [1, 2, 3, 4, 5, 0],
      #|]
    ),
  )
}

///|
test "shrink fixed array" {
  let input : FixedArray[Int] = [2, 1]
  debug_inspect(
    @shrink.Shrink::shrink(input).collect(),
    content=(
      #|[
      #|  <FixedArray: []>,
      #|  <FixedArray: [1]>,
      #|  <FixedArray: [2]>,
      #|  <FixedArray: [1, 1]>,
      #|  <FixedArray: [0, 1]>,
      #|  <FixedArray: [2, 0]>,
      #|]
    ),
  )
}

///|
test "shrink array view" {
  let source = [9, 3, 1, 9]
  let input = source[1:3]
  debug_inspect(
    @shrink.Shrink::shrink(input).collect(),
    content=(
      #|[
      #|  <ArrayView: []>,
      #|  <ArrayView: [1]>,
      #|  <ArrayView: [3]>,
      #|  <ArrayView: [2, 1]>,
      #|  <ArrayView: [0, 1]>,
      #|  <ArrayView: [3, 0]>,
      #|]
    ),
  )
}

///|
test "shrink readonly array" {
  let input : ReadOnlyArray[Int] = ReadOnlyArray::from_array([2, 1])
  let candidates = @shrink.Shrink::shrink(input)
    .map(candidate => candidate[:].to_owned())
    .collect()
  debug_inspect(
    candidates,
    content=(
      #|[[], [1], [2], [1, 1], [0, 1], [2, 0]]
    ),
  )
}

///|
test "shrink ref into fresh refs" {
  let input = @ref.Ref(4)
  let candidates = @shrink.Shrink::shrink(input).collect()
  debug_inspect(
    candidates.map(candidate => candidate.val),
    content=(
      #|[3, 2, 0]
    ),
  )
  candidates[0].val = 99
  debug_inspect(
    (input.val, candidates.map(candidate => candidate.val)),
    content=(
      #|(4, [99, 2, 0])
    ),
  )
}

///|
test "shrink tuple" {
  let x = (120, true)
  debug_inspect(
    @shrink.Shrink::shrink(x).collect(),
    content=(
      #|[
      #|  (119, true),
      #|  (117, true),
      #|  (113, true),
      #|  (105, true),
      #|  (90, true),
      #|  (60, true),
      #|  (0, true),
      #|  (120, false),
      #|]
    ),
  )
}

///|
test "shrink 6-tuple" {
  let x = (20, 'A', 30U, true, true, true)
  debug_inspect(
    @shrink.Shrink::shrink(x).collect(),
    content=(
      #|[
      #|  (19, 'A', 30, true, true, true),
      #|  (18, 'A', 30, true, true, true),
      #|  (15, 'A', 30, true, true, true),
      #|  (10, 'A', 30, true, true, true),
      #|  (0, 'A', 30, true, true, true),
      #|  (20, 'a', 30, true, true, true),
      #|  (20, 'b', 30, true, true, true),
      #|  (20, 'c', 30, true, true, true),
      #|  (20, 'A', 29, true, true, true),
      #|  (20, 'A', 27, true, true, true),
      #|  (20, 'A', 23, true, true, true),
      #|  (20, 'A', 15, true, true, true),
      #|  (20, 'A', 0, true, true, true),
      #|  (20, 'A', 30, false, true, true),
      #|  (20, 'A', 30, true, false, true),
      #|  (20, 'A', 30, true, true, false),
      #|]
    ),
  )
}
