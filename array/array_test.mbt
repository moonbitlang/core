// Copyright 2024 International Digital Economy Academy
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

test "to_string" {
  let empty : Array[Int] = []
  inspect(empty, content="[]")?
  let a0 = [0]
  inspect(a0, content="[0]")?
  a0.push(1)
  inspect(a0, content="[0, 1]")?
  a0.push(2)
  inspect(a0, content="[0, 1, 2]")?
}

test "get" {
  let v = [3]
  inspect(v.get(-1), content="None")?
  inspect(v.get(0), content="Some(3)")?
  inspect(v.get(1), content="None")?
}

test "op_add" {
  inspect(([] : Array[Int]) + [], content="[]")?
  inspect(([] : Array[Int]) + [1, 2, 3, 4, 5], content="[1, 2, 3, 4, 5]")?
  inspect([1, 2, 3, 4, 5] + [], content="[1, 2, 3, 4, 5]")?
  inspect(
    [1, 2, 3, 4, 5] + [6, 7, 8, 9, 10],
    content="[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]",
  )?
}

test "op_equal" {
  let v1 = [3, 4, 5]
  let v2 = [3, 4, 5]
  let v3 = [3, 4, 6]
  @assertion.assert_true(v1 == v2)?
  @assertion.assert_false(v1 == v3)?
}

test "pop" {
  let v = []
  v.push(3)
  v.push(4)
  @assertion.assert_eq(v.length(), 2)?
  @assertion.assert_eq(v.pop(), Some(4))?
  @assertion.assert_eq(v.pop(), Some(3))?
  @assertion.assert_eq(v.length(), 0)?
  @assertion.assert_eq(v.pop(), None)?
}

test "pop_exn" {
  let v = []
  v.push(3)
  v.push(4)
  @assertion.assert_eq(v.length(), 2)?
  @assertion.assert_eq(v.pop_exn(), 4)?
  @assertion.assert_eq(v.pop_exn(), 3)?
  @assertion.assert_eq(v.length(), 0)?
}

test "push" {
  let v = [3, 4, 5]
  @assertion.assert_eq(v, [3, 4, 5])?
  v[0] = 6
  @assertion.assert_eq(v, [6, 4, 5])?
}

test "drain" {
  let v = [3, 4, 5]
  let v2 = [1, 2, 3, 4, 5]
  let vv = v.drain(1, 2)
  let v2v = v2.drain(2, 5)
  @assertion.assert_eq(v, [3, 5])?
  @assertion.assert_eq(vv, [4])?
  @assertion.assert_eq(v2, [1, 2])?
  @assertion.assert_eq(v2v, [3, 4, 5])?
}

test "append" {
  let v1 = [3, 4, 5]
  let v2 = [6, 7, 8]
  v1.append(v2)
  @assertion.assert_eq(v1, [3, 4, 5, 6, 7, 8])?
  @assertion.assert_eq(v1.length(), 6)?
}

test "iter" {
  let v = [3, 4, 5]
  let mut sum = 0
  v.iter(fn(x) { sum = sum + x })
  @assertion.assert_eq(sum, 12)?
}

test "iter_rev" {
  let v = with_capacity(3)
  v.push(3)
  v.push(4)
  v.push(5)
  let mut sum = 0
  v.iter_rev(fn(x) { sum = sum + x })
  @assertion.assert_eq(sum, 12)?
}

test "iteri" {
  let v = [3, 4, 5]
  let mut sum = 0
  v.iteri(fn(i, x) { sum = sum + x + i })
  @assertion.assert_eq(sum, 15)?
}

test "iter_revi" {
  let v = [3, 4, 5]
  let mut sum = 0
  v.iter_revi(fn(i, x) { sum = sum + x + i })
  @assertion.assert_eq(sum, 15)?
}

test "clear" {
  let v = [3, 4, 5]
  v.clear()
  @assertion.assert_eq(v.length(), 0)?
}

test "map" {
  let v = [3, 4, 5]
  let e : Array[Int] = []
  inspect(v.map(fn(x) { x + 1 }), content="[4, 5, 6]")?
  inspect(v.map(fn(x) { x.to_string() }), content="[3, 4, 5]")?
  inspect(e.map(fn(x) { x + 1 }), content="[]")?
  // Is it correct?
  inspect(["a", "b", "c"], content="[a, b, c]")?
}

test "map_inplace" {
  let v = [3, 4, 5]
  let e : Array[Int] = []
  v.map_inplace(fn(x) { x + 1 })
  e.map_inplace(fn(x) { x + 1 })
  inspect(v, content="[4, 5, 6]")?
  inspect(e, content="[]")?
}

test "mapi" {
  let v = [3, 4, 5]
  let e : Array[Int] = []
  inspect(v.mapi(fn(i, x) { x + i }), content="[3, 5, 7]")?
  inspect(v.mapi(fn(i, x) { (x + i).to_string() }), content="[3, 5, 7]")?
  inspect(e.mapi(fn(_i, x) { x + 1 }), content="[]")?
}

test "mapi_inplace" {
  let v = [3, 4, 5]
  let e : Array[Int] = []
  v.mapi_inplace(fn(i, x) { x + i })
  e.mapi_inplace(fn(_i, x) { x + 1 })
  inspect(v, content="[3, 5, 7]")?
  inspect(e, content="[]")?
}

test "filter" {
  let arr = [1, 2, 3, 4, 5, 6]
  inspect(arr.filter(fn(x) { x % 2 == 0 }), content="[2, 4, 6]")?
}

test "is_empty" {
  let v = []
  @assertion.assert_true(v.is_empty())?
  v.push(3)
  @assertion.assert_false(v.is_empty())?
}

test "is_sorted" {
  let v : Array[Int] = []
  @assertion.assert_true(v.is_sorted())?
  let v = [3, 4, 5]
  @assertion.assert_true(v.is_sorted())?
  let v2 = [3, 5, 4]
  @assertion.assert_false(v2.is_sorted())?
}

test "reverse" {
  let v = [3, 4, 5]
  v.reverse()
  @assertion.assert_eq(v, [5, 4, 3])?
  v.reverse()
  @assertion.assert_eq(v, [3, 4, 5])?
  let v = [3, 4]
  v.reverse()
  @assertion.assert_eq(v, [4, 3])?
  v.reverse()
  @assertion.assert_eq(v, [3, 4])?
  let empty : Array[Int] = []
  @assertion.assert_eq(empty, empty)?
}

test "split_at" {
  let v = [3, 4, 5]
  let (v1, v2) = v.split_at(1)
  @assertion.assert_eq(v1, [3])?
  @assertion.assert_eq(v2, [4, 5])?
}

test "contains" {
  let v = [3, 4, 5]
  @assertion.assert_true(v.contains(3))?
  @assertion.assert_true(v.contains(4))?
  @assertion.assert_true(v.contains(5))?
  @assertion.assert_false(v.contains(6))?
}

test "starts_with" {
  let v = [3, 4, 5]
  @assertion.assert_true(v.starts_with([3, 4]))?
  @assertion.assert_true(v.starts_with([3, 4, 5]))?
  @assertion.assert_false(v.starts_with([3, 4, 6]))?
  @assertion.assert_false(v.starts_with([3, 4, 5, 6]))?
}

test "ends_with" {
  let v = [3, 4, 5]
  @assertion.assert_true(v.ends_with([4, 5]))?
  @assertion.assert_true(v.ends_with([3, 4, 5]))?
  @assertion.assert_false(v.ends_with([3, 4, 6]))?
  @assertion.assert_false(v.ends_with([2, 3, 4, 5]))?
}

test "strip_prefix" {
  let v = [3, 4, 5]
  let sv = v.strip_prefix([3])
  @assertion.assert_eq(v, [3, 4, 5])?
  @assertion.assert_eq(sv, Some([4, 5]))?
  @assertion.assert_eq(v.strip_prefix([4]), None)?
}

test "strip_suffix" {
  let v = [3, 4, 5]
  let sv = v.strip_suffix([5])
  @assertion.assert_eq(v, [3, 4, 5])?
  @assertion.assert_eq(sv, Some([3, 4]))?
  @assertion.assert_eq(v.strip_suffix([4]), None)?
}

test "search" {
  let v = [3, 4, 5]
  @assertion.assert_eq(v.search(3), Some(0))?
  @assertion.assert_eq(v.search(4), Some(1))?
  @assertion.assert_eq(v.search(5), Some(2))?
  @assertion.assert_eq(v.search(6), None)?
}

test "swap" {
  let v = [3, 4, 5]
  v.swap(0, 2)
  @assertion.assert_eq(v, [5, 4, 3])?
  v.swap(0, 2)
  @assertion.assert_eq(v, [3, 4, 5])?
}

test "remove" {
  let v = [3, 4, 5]
  @assertion.assert_eq(v.remove(1), 4)?
  @assertion.assert_eq(v, [3, 5])?
}

test "retain" {
  let v = [3, 4, 5]
  v.retain(fn(x) { x > 3 })
  @assertion.assert_eq(v, [4, 5])?
}

test "resize" {
  let v = [3, 4, 5]
  v.resize(5, 0)
  @assertion.assert_eq(v, [3, 4, 5, 0, 0])?
  @assertion.assert_eq(v.length(), 5)?
  let vv = [3, 4, 5]
  vv.resize(2, 0)
  @assertion.assert_eq(vv, [3, 4])?
  @assertion.assert_eq(vv.length(), 2)?
}

test "insert" {
  let v = [3, 4, 5]
  v.insert(1, 6)
  @assertion.assert_eq(v, [3, 6, 4, 5])?
  @assertion.assert_eq(v.length(), 4)?
}

test "flatten" {
  let v = [[3, 4], [5, 6]]
  let vv = v.flatten()
  @assertion.assert_eq(vv, [3, 4, 5, 6])?
  @assertion.assert_eq(vv.length(), 4)?
}

test "repeat" {
  let v = [3, 4]
  let vv = v.repeat(2)
  @assertion.assert_eq(vv, [3, 4, 3, 4])?
  @assertion.assert_eq(vv.length(), 4)?
}

test "join" {
  let v = [[3, 4], [5, 6]]
  let vv = v.join(0)
  @assertion.assert_eq(vv, [3, 4, 0, 5, 6])?
  @assertion.assert_eq(vv.length(), 5)?
}

test "fold_left" {
  let sum = [1, 2, 3, 4, 5].fold_left(init=0, fn { sum, elem => sum + elem })
  @assertion.assert_eq(sum, 15)?
}

test "fold_right" {
  let sum = [1, 2, 3, 4, 5].fold_right(init=0, fn { sum, elem => sum + elem })
  @assertion.assert_eq(sum, 15)?
}

test "fold_lefti" {
  let sum = [1, 2, 3, 4, 5].fold_lefti(
    init=0,
    fn { index, sum, _elem => sum + index },
  )
  @assertion.assert_eq(sum, 10)?
}

test "fold_righti" {
  let sum = [1, 2, 3, 4, 5].fold_righti(
    init=0,
    fn { index, sum, _elem => sum + index },
  )
  @assertion.assert_eq(sum, 10)?
}

test "dedup" {
  let v = [3, 4, 4, 5, 5, 5]
  v.dedup()
  @assertion.assert_eq(v, [3, 4, 5])?
  @assertion.assert_eq(v.length(), 3)?
}

test "extract_if" {
  let v = [3, 4, 5]
  let vv = v.extract_if(fn(x) { x > 3 })
  @assertion.assert_eq(v, [3])?
  @assertion.assert_eq(v.length(), 1)?
  @assertion.assert_eq(vv, [4, 5])?
}

test "chunks" {
  let v = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  let chunks = v.chunks(3)
  let chunks2 = v.chunks(2)
  @assertion.assert_eq(chunks, [[1, 2, 3], [4, 5, 6], [7, 8, 9]])?
  @assertion.assert_eq(chunks2, [[1, 2], [3, 4], [5, 6], [7, 8], [9]])?
}

test "chunk_by" {
  let v = [1, 1, 2, 3, 2, 3, 2, 3, 4]
  let chunks = v.chunk_by(fn(x, y) { x <= y })
  @assertion.assert_eq(chunks[0], [1, 1, 2, 3])?
  @assertion.assert_eq(chunks[1], [2, 3])?
  @assertion.assert_eq(chunks[2], [2, 3, 4])?
}

test "split" {
  let v = [1, 0, 2, 0, 3, 0, 4]
  let chunks = v.split(fn(x) { x == 0 })
  @assertion.assert_eq(chunks, [[1], [2], [3], [4]])?
  @assertion.assert_eq(chunks.length(), 4)?
}

test "reserve_capacity" {
  let v = [1]
  // Only test that it doesn't panic
  v.reserve_capacity(10)
}

test "reserve_capacity_2" {
  let v = [1, 2, 3, 4, 5]
  // Only test that it doesn't panic
  v.reserve_capacity(3)
}

test "shrink_to_fit" {
  let v = with_capacity(10)
  v.push(1)
  v.push(2)
  v.push(3)
  // Only test that it doesn't panic
  v.shrink_to_fit()
}

test "shrink_to_fit_2" {
  let v = [1, 2, 3]
  // Only test that it doesn't panic
  v.shrink_to_fit()
}

test "as_iter" {
  let buf = Buffer::make(5)
  [1, 2, 3, 4, 5].as_iter().iter(fn { x => buf.write_string(x.to_string()) })
  inspect(buf, content="12345")?
  buf.reset()
  [1, 2, 3, 4, 5].as_iter().take(2).iter(
    fn { x => buf.write_string(x.to_string()) },
  )
  inspect(buf, content="12")?
}

test "shuffle_in_place" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 6, 7]
  fn rand(upper : Int) -> Int {
    let rng = @random.init_state(seed=37)
    rng.gen_int() % upper
  }

  Array::shuffle_in_place(arr, ~rand)
  inspect(arr, content="[5, 2, 1, 6, 3, 7, 4]")?
}

test "shuffle" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 6, 7]
  fn rand(upper : Int) -> Int {
    let rng = @random.init_state(seed=42)
    rng.gen_int() % upper
  }

  let shuffled = Array::shuffle(arr, ~rand)
  inspect(shuffled, content="[2, 7, 6, 1, 5, 3, 4]")?
}

test "find_index" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 6, 7]
  let index = arr.find_index(fn(x) { x == 3 })
  @assertion.assert_eq(index, Some(2))?
}

test "copy" {
  let arr = [1, 2, 3, 4, 5]
  let copied = arr.copy()
  @assertion.assert_eq(copied, [1, 2, 3, 4, 5])?
  @assertion.assert_is_not(arr, copied)?
}

test "new_with_index" {
  let arr = Array::new_with_index(5, fn(i) { i * 2 })
  @assertion.assert_eq(arr, [0, 2, 4, 6, 8])?
}

test "copy with non-empty array" {
  let arr = [1, 2, 3, 4, 5]
  let copied = arr.copy()
  @assertion.assert_eq(copied, [1, 2, 3, 4, 5])?
  @assertion.assert_is_not(arr, copied)?
}

test "new_with_index with positive length" {
  let arr = Array::new_with_index(5, fn(i) { i * 2 })
  @assertion.assert_eq(arr, [0, 2, 4, 6, 8])?
}
