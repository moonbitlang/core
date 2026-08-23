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
test "array_capacity" {
  let arr : Array[Int] = Array::new(capacity=10)
  assert_true(arr.capacity() >= 10)
}

///|
test "array_append_reuses_capacity" {
  let arr = Array::new(capacity=4)
  arr.push(1)
  arr.append([2, 3])
  inspect(arr.capacity(), content="4")
  debug_inspect(arr, content="[1, 2, 3]")
}

///|
test "array_append_grows_geometrically" {
  let arr = Array::new(capacity=4)
  arr.append([1, 2, 3, 4, 5])
  inspect(arr.capacity(), content="8")
  debug_inspect(arr, content="[1, 2, 3, 4, 5]")
}

///|
test "array_blit_to_reuses_and_grows_capacity" {
  let dst = Array::new(capacity=4)
  dst.push(0)
  [1, 2][:].blit_to(dst, dst_offset=1)
  inspect(dst.capacity(), content="4")
  [3, 4][:].blit_to(dst, dst_offset=3)
  inspect(dst.capacity(), content="8")
  debug_inspect(dst, content="[0, 1, 2, 3, 4]")
}

///|
test "array_retain" {
  let arr = [1, 2, 3, 4, 5]
  @test.assert_eq(arr.capacity(), 5)
  arr.retain(x => x % 2 == 0)
  @test.assert_eq(arr.length(), 2)
  @test.assert_eq(arr.capacity(), 5)
  @test.assert_eq(arr[0], 2)
  @test.assert_eq(arr[1], 4)
}

///|
test "shrink_to_fit" {
  let v = Array::new(capacity=10)
  v.push(1)
  v.push(2)
  v.push(3)
  inspect(v.capacity(), content="10")
  v.shrink_to_fit()
  inspect(v.capacity(), content="3")
  v.shrink_to_fit()
  inspect(v.capacity(), content="3")
}

///|
/// Removing elements must never leave a slot a view could read as
/// uninitialized memory, so nothing is written to the slots a removal vacates
/// and a view taken beforehand still sees the original elements.
test "clear leaves the emptied slots as they were" {
  let arr = ["a", "b", "c"]
  let view = arr[0:3]
  arr.clear()
  inspect(arr.length(), content="0")
  debug_inspect(
    view,
    content=(
      #|<ArrayView: ["a", "b", "c"]>
    ),
  )
}

///|
test "fill_unused after clear overwrites the whole buffer" {
  let arr = ["a", "b", "c"]
  let view = arr[0:3]
  arr.clear()
  arr.fill_unused("-")
  inspect(arr.length(), content="0")
  debug_inspect(
    view,
    content=(
      #|<ArrayView: ["-", "-", "-"]>
    ),
  )
}

///|
test "truncate keeps removed elements reachable until fill_unused" {
  let kept = ["a", "b", "c", "d"]
  let kept_view = kept[0:4]
  kept.truncate(2)
  debug_inspect(
    kept,
    content=(
      #|["a", "b"]
    ),
  )
  debug_inspect(
    kept_view,
    content=(
      #|<ArrayView: ["a", "b", "c", "d"]>
    ),
  )
  let filled = ["a", "b", "c", "d"]
  let filled_view = filled[0:4]
  filled.truncate(2)
  filled.fill_unused("-")
  debug_inspect(
    filled,
    content=(
      #|["a", "b"]
    ),
  )
  debug_inspect(
    filled_view,
    content=(
      #|<ArrayView: ["a", "b", "-", "-"]>
    ),
  )
}

///|
/// No shrinking operation replaces the buffer, so emptying an array never
/// costs an allocation -- whether it happens through `clear`, `truncate`,
/// `remove` or `drain`. A later push makes that observable: it lands in the
/// reused buffer, which a view taken beforehand still points at.
test "no shrinking operation replaces the buffer" {
  let cleared = ["a", "b", "c"]
  let cleared_view = cleared[0:3]
  cleared.clear()
  cleared.push("x")
  debug_inspect(
    cleared_view,
    content=(
      #|<ArrayView: ["x", "b", "c"]>
    ),
  )
  let truncated = ["a", "b", "c"]
  let truncated_view = truncated[0:3]
  truncated.truncate(0)
  truncated.push("x")
  debug_inspect(
    truncated_view,
    content=(
      #|<ArrayView: ["x", "b", "c"]>
    ),
  )
  let removed = ["a"]
  let removed_view = removed[0:1]
  let _ = removed.remove(0)
  removed.push("x")
  debug_inspect(
    removed_view,
    content=(
      #|<ArrayView: ["x"]>
    ),
  )
}

///|
test "fill_unused overwrites the tail a drain vacated" {
  let arr = ["a", "b", "c", "d"]
  let view = arr[0:4]
  let drained = arr.drain(1, 3)
  arr.fill_unused("-")
  debug_inspect(
    drained,
    content=(
      #|["b", "c"]
    ),
  )
  debug_inspect(
    arr,
    content=(
      #|["a", "d"]
    ),
  )
  debug_inspect(
    view,
    content=(
      #|<ArrayView: ["a", "d", "-", "-"]>
    ),
  )
}

///|
/// `pop`, `remove` and `retain` offer no fill value of their own, so the
/// elements they remove stay in the buffer until something overwrites them.
/// `fill_unused` is what releases them without reallocating, and a view taken
/// beforehand shows exactly which slots it reached.
test "fill_unused releases what pop and remove leave behind" {
  let popped = ["a", "b", "c"]
  let popped_view = popped[0:3]
  let _ = popped.pop()
  debug_inspect(
    popped_view,
    content=(
      #|<ArrayView: ["a", "b", "c"]>
    ),
  )
  popped.fill_unused("-")
  debug_inspect(
    popped_view,
    content=(
      #|<ArrayView: ["a", "b", "-"]>
    ),
  )
  let removed = ["a", "b", "c"]
  let removed_view = removed[0:3]
  let _ = removed.remove(0)
  removed.fill_unused("-")
  debug_inspect(
    removed,
    content=(
      #|["b", "c"]
    ),
  )
  debug_inspect(
    removed_view,
    content=(
      #|<ArrayView: ["b", "c", "-"]>
    ),
  )
}

///|
/// `fill_unused` covers the whole unused region, not just the slots the most
/// recent operation vacated, so one call settles a run of removals.
test "fill_unused spans every outstanding removal" {
  let arr = ["a", "b", "c", "d"]
  let view = arr[0:4]
  let _ = arr.pop()
  arr.truncate(1)
  arr.fill_unused("-")
  debug_inspect(
    arr,
    content=(
      #|["a"]
    ),
  )
  debug_inspect(
    view,
    content=(
      #|<ArrayView: ["a", "-", "-", "-"]>
    ),
  )
}
