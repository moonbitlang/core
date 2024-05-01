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
  let empty : Vec[Int] = Vec::[]
  inspect(empty, content="Vec::[]")?
  let a0 = Vec::[0]
  inspect(a0, content="Vec::[0]")?
  a0.push(1)
  inspect(a0, content="Vec::[0, 1]")?
  a0.push(2)
  inspect(a0, content="Vec::[0, 1, 2]")?
}

test "realloc" {
  let v : Vec[Int] = Vec::new()
  v.realloc()
  v.realloc()
  @assertion.assert_eq(v.capacity(), 8)?
  for i = 0; i < 9; i = i + 1 {
    v.push(i)
  }
  @assertion.assert_eq(v.capacity(), 16)?
}

test "get" {
  let v = Vec::[3]
  inspect(v.get(-1), content="None")?
  inspect(v.get(0), content="Some(3)")?
  inspect(v.get(1), content="None")?
}

test "op_add" {
  inspect((Vec::[] : Vec[Int]) + Vec::[], content="Vec::[]")?
  inspect(
    (Vec::[] : Vec[Int]) + Vec::[1, 2, 3, 4, 5],
    content="Vec::[1, 2, 3, 4, 5]",
  )?
  inspect(Vec::[1, 2, 3, 4, 5] + Vec::[], content="Vec::[1, 2, 3, 4, 5]")?
  inspect(
    Vec::[1, 2, 3, 4, 5] + Vec::[6, 7, 8, 9, 10],
    content="Vec::[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]",
  )?
}

test "op_equal" {
  let v1 = Vec::[3, 4, 5]
  let v2 = Vec::[3, 4, 5]
  let v3 = Vec::[3, 4, 6]
  @assertion.assert_true(v1 == v2)?
  @assertion.assert_false(v1 == v3)?
}

test "pop" {
  let v = Vec::new()
  v.push(3)
  v.push(4)
  @assertion.assert_eq(v.length(), 2)?
  @assertion.assert_eq(v.pop(), Some(4))?
  @assertion.assert_eq(v.pop(), Some(3))?
  @assertion.assert_eq(v.length(), 0)?
  @assertion.assert_eq(v.pop(), None)?
}

test "pop_exn" {
  let v = Vec::new()
  v.push(3)
  v.push(4)
  @assertion.assert_eq(v.length(), 2)?
  @assertion.assert_eq(v.pop_exn(), 4)?
  @assertion.assert_eq(v.pop_exn(), 3)?
  @assertion.assert_eq(v.length(), 0)?
}

test "push" {
  let v = Vec::[3, 4, 5]
  @assertion.assert_eq(v, Vec::[3, 4, 5])?
  v[0] = 6
  @assertion.assert_eq(v, Vec::[6, 4, 5])?
}

test "drain" {
  let v = Vec::[3, 4, 5]
  let v2 = Vec::[1, 2, 3, 4, 5]
  let vv = v.drain(1, 2)
  let v2v = v2.drain(2, 5)
  @assertion.assert_eq(v, Vec::[3, 5])?
  @assertion.assert_eq(vv, Vec::[4])?
  @assertion.assert_eq(v2, Vec::[1, 2])?
  @assertion.assert_eq(v2v, Vec::[3, 4, 5])?
}

test "append" {
  let v1 = Vec::[3, 4, 5]
  let v2 = Vec::[6, 7, 8]
  v1.append(v2)
  @assertion.assert_eq(v1, Vec::[3, 4, 5, 6, 7, 8])?
  @assertion.assert_eq(v1.length(), 6)?
}

test "iter" {
  let v = Vec::[3, 4, 5]
  let mut sum = 0
  v.iter(fn(x) { sum = sum + x })
  @assertion.assert_eq(sum, 12)?
}

test "iter_rev" {
  let v = Vec::with_capacity(3)
  v.push(3)
  v.push(4)
  v.push(5)
  let mut sum = 0
  v.iter_rev(fn(x) { sum = sum + x })
  @assertion.assert_eq(sum, 12)?
}

test "iteri" {
  let v = Vec::[3, 4, 5]
  let mut sum = 0
  v.iteri(fn(i, x) { sum = sum + x + i })
  @assertion.assert_eq(sum, 15)?
}

test "iter_revi" {
  let v = Vec::[3, 4, 5]
  let mut sum = 0
  v.iter_revi(fn(i, x) { sum = sum + x + i })
  @assertion.assert_eq(sum, 15)?
}

test "clear" {
  let v = Vec::[3, 4, 5]
  v.clear()
  @assertion.assert_eq(v.length(), 0)?
  @assertion.assert_eq(v.capacity(), 3)?
}

test "map" {
  let v = Vec::[3, 4, 5]
  v.map(fn(x) { x + 1 })
  @assertion.assert_eq(v, Vec::[4, 5, 6])?
}

test "mapi" {
  let v = Vec::[3, 4, 5]
  v.mapi(fn(i, x) { x + i })
  @assertion.assert_eq(v, Vec::[3, 5, 7])?
}

test "is_empty" {
  let v = Vec::new()
  @assertion.assert_true(v.is_empty())?
  v.push(3)
  @assertion.assert_false(v.is_empty())?
}

test "is_sorted" {
  let v : Vec[Int] = Vec::[]
  @assertion.assert_true(v.is_sorted())?
  let v = Vec::[3, 4, 5]
  @assertion.assert_true(v.is_sorted())?
  let v2 = Vec::[3, 5, 4]
  @assertion.assert_false(v2.is_sorted())?
}

test "reverse" {
  let v = Vec::[3, 4, 5]
  v.reverse()
  @assertion.assert_eq(v, Vec::[5, 4, 3])?
  v.reverse()
  @assertion.assert_eq(v, Vec::[3, 4, 5])?
  let v = Vec::[3, 4]
  v.reverse()
  @assertion.assert_eq(v, Vec::[4, 3])?
  v.reverse()
  @assertion.assert_eq(v, Vec::[3, 4])?
  let empty : Vec[Int] = Vec::[]
  @assertion.assert_eq(empty, empty)?
}

test "split_at" {
  let v = Vec::[3, 4, 5]
  let (v1, v2) = v.split_at(1)
  @assertion.assert_eq(v1, Vec::[3])?
  @assertion.assert_eq(v2, Vec::[4, 5])?
}

test "contains" {
  let v = Vec::[3, 4, 5]
  @assertion.assert_true(v.contains(3))?
  @assertion.assert_true(v.contains(4))?
  @assertion.assert_true(v.contains(5))?
  @assertion.assert_false(v.contains(6))?
}

test "starts_with" {
  let v = Vec::[3, 4, 5]
  @assertion.assert_true(v.starts_with(Vec::[3, 4]))?
  @assertion.assert_true(v.starts_with(Vec::[3, 4, 5]))?
  @assertion.assert_false(v.starts_with(Vec::[3, 4, 6]))?
  @assertion.assert_false(v.starts_with(Vec::[3, 4, 5, 6]))?
}

test "ends_with" {
  let v = Vec::[3, 4, 5]
  @assertion.assert_true(v.ends_with(Vec::[4, 5]))?
  @assertion.assert_true(v.ends_with(Vec::[3, 4, 5]))?
  @assertion.assert_false(v.ends_with(Vec::[3, 4, 6]))?
  @assertion.assert_false(v.ends_with(Vec::[2, 3, 4, 5]))?
}

test "strip_prefix" {
  let v = Vec::[3, 4, 5]
  let sv = v.strip_prefix(Vec::[3])
  @assertion.assert_eq(v, Vec::[3, 4, 5])?
  @assertion.assert_eq(sv, Some(Vec::[4, 5]))?
  @assertion.assert_eq(v.strip_prefix(Vec::[4]), None)?
}

test "strip_suffix" {
  let v = Vec::[3, 4, 5]
  let sv = v.strip_suffix(Vec::[5])
  @assertion.assert_eq(v, Vec::[3, 4, 5])?
  @assertion.assert_eq(sv, Some(Vec::[3, 4]))?
  @assertion.assert_eq(v.strip_suffix(Vec::[4]), None)?
}

test "search" {
  let v = Vec::[3, 4, 5]
  @assertion.assert_eq(v.search(3), Some(0))?
  @assertion.assert_eq(v.search(4), Some(1))?
  @assertion.assert_eq(v.search(5), Some(2))?
  @assertion.assert_eq(v.search(6), None)?
}

test "swap" {
  let v = Vec::[3, 4, 5]
  v.swap(0, 2)
  @assertion.assert_eq(v, Vec::[5, 4, 3])?
  v.swap(0, 2)
  @assertion.assert_eq(v, Vec::[3, 4, 5])?
}

test "remove" {
  let v = Vec::[3, 4, 5]
  @assertion.assert_eq(v.remove(1), 4)?
  @assertion.assert_eq(v, Vec::[3, 5])?
}

test "retain" {
  let v = Vec::[3, 4, 5]
  v.retain(fn(x) { x > 3 })
  @assertion.assert_eq(v, Vec::[4, 5])?
}

test "resize" {
  let v = Vec::[3, 4, 5]
  v.resize(5, 0)
  @assertion.assert_eq(v, Vec::[3, 4, 5, 0, 0])?
  @assertion.assert_eq(v.length(), 5)?
  let vv = Vec::[3, 4, 5]
  vv.resize(2, 0)
  @assertion.assert_eq(vv, Vec::[3, 4])?
  @assertion.assert_eq(vv.length(), 2)?
}

test "insert" {
  let v = Vec::[3, 4, 5]
  v.insert(1, 6)
  @assertion.assert_eq(v, Vec::[3, 6, 4, 5])?
  @assertion.assert_eq(v.length(), 4)?
  @assertion.assert_eq(v.capacity(), 6)?
}

test "fill" {
  let v = Vec::with_capacity(3)
  v.fill(3)
  @assertion.assert_eq(v, Vec::[3, 3, 3])?
  @assertion.assert_eq(v.length(), 3)?
}

test "fill_with" {
  let v = Vec::with_capacity(3)
  v.fill_with(fn() { 3 })
  @assertion.assert_eq(v, Vec::[3, 3, 3])?
  @assertion.assert_eq(v.length(), 3)?
}

test "flatten" {
  let v = Vec::[Vec::[3, 4], Vec::[5, 6]]
  let vv = v.flatten()
  @assertion.assert_eq(vv, Vec::[3, 4, 5, 6])?
  @assertion.assert_eq(vv.length(), 4)?
}

test "repeat" {
  let v = Vec::[3, 4]
  let vv = v.repeat(2)
  @assertion.assert_eq(vv, Vec::[3, 4, 3, 4])?
  @assertion.assert_eq(vv.length(), 4)?
}

test "join" {
  let v = Vec::[Vec::[3, 4], Vec::[5, 6]]
  let vv = v.join(0)
  @assertion.assert_eq(vv, Vec::[3, 4, 0, 5, 6])?
  @assertion.assert_eq(vv.length(), 5)?
}

test "fold_left" {
  let sum = Vec::[1, 2, 3, 4, 5].fold_left(
    init=0,
    fn { sum, elem => sum + elem },
  )
  @assertion.assert_eq(sum, 15)?
}

test "fold_right" {
  let sum = Vec::[1, 2, 3, 4, 5].fold_right(
    init=0,
    fn { sum, elem => sum + elem },
  )
  @assertion.assert_eq(sum, 15)?
}

test "fold_lefti" {
  let sum = Vec::[1, 2, 3, 4, 5].fold_lefti(
    init=0,
    fn { index, sum, _elem => sum + index },
  )
  @assertion.assert_eq(sum, 10)?
}

test "fold_righti" {
  let sum = Vec::[1, 2, 3, 4, 5].fold_righti(
    init=0,
    fn { index, sum, _elem => sum + index },
  )
  @assertion.assert_eq(sum, 10)?
}

test "dedup" {
  let v = Vec::[3, 4, 4, 5, 5, 5]
  v.dedup()
  @assertion.assert_eq(v, Vec::[3, 4, 5])?
  @assertion.assert_eq(v.length(), 3)?
}

test "extract_if" {
  let v = Vec::[3, 4, 5]
  let vv = v.extract_if(fn(x) { x > 3 })
  @assertion.assert_eq(v, Vec::[3])?
  @assertion.assert_eq(v.length(), 1)?
  @assertion.assert_eq(vv, Vec::[4, 5])?
}

test "chunks" {
  let v = Vec::[1, 2, 3, 4, 5, 6, 7, 8, 9]
  let chunks = v.chunks(3)
  let chunks2 = v.chunks(2)
  @assertion.assert_eq(
    chunks,
    Vec::[Vec::[1, 2, 3], Vec::[4, 5, 6], Vec::[7, 8, 9]],
  )?
  @assertion.assert_eq(
    chunks2,
    Vec::[Vec::[1, 2], Vec::[3, 4], Vec::[5, 6], Vec::[7, 8], Vec::[9]],
  )?
}

test "chunk_by" {
  let v = Vec::[1, 1, 2, 3, 2, 3, 2, 3, 4]
  let chunks = v.chunk_by(fn(x, y) { x <= y })
  @assertion.assert_eq(chunks[0], Vec::[1, 1, 2, 3])?
  @assertion.assert_eq(chunks[1], Vec::[2, 3])?
  @assertion.assert_eq(chunks[2], Vec::[2, 3, 4])?
}

test "split" {
  let v = Vec::[1, 0, 2, 0, 3, 0, 4]
  let chunks = v.split(fn(x) { x == 0 })
  @assertion.assert_eq(chunks, Vec::[Vec::[1], Vec::[2], Vec::[3], Vec::[4]])?
  @assertion.assert_eq(chunks.length(), 4)?
}

test "to_list" {
  let ls = Vec::[1, 2, 3, 4, 5].to_list()
  @assertion.assert_eq(ls, Cons(1, Cons(2, Cons(3, Cons(4, Cons(5, Nil))))))?
}

test "reserve_capacity" {
  let v = Vec::[1]
  v.reserve_capacity(10)
  @assertion.assert_true(v.capacity() == 10)?
}

test "reserve_capacity_2" {
  let v = Vec::[1, 2, 3, 4, 5]
  v.reserve_capacity(3)
  @assertion.assert_true(v.capacity() == 5)?
}

test "shrink_to_fit" {
  let v = Vec::with_capacity(10)
  v.push(1)
  v.push(2)
  v.push(3)
  @assertion.assert_true(v.capacity() == 10)?
  v.shrink_to_fit()
  @assertion.assert_true(v.capacity() == 3)?
}

test "shrink_to_fit_2" {
  let v = Vec::[1, 2, 3]
  @assertion.assert_true(v.capacity() == 3)?
  v.shrink_to_fit()
  @assertion.assert_true(v.capacity() == 3)?
}

test "as_iter" {
  let buf = Buffer::make(5)
  Vec::[1, 2, 3, 4, 5].as_iter().iter(
    fn { x => buf.write_string(x.to_string()) },
  )
  inspect(buf, content="12345")?
  buf.reset()
  Vec::[1, 2, 3, 4, 5].as_iter().take(2).iter(
    fn { x => buf.write_string(x.to_string()) },
  )
  inspect(buf, content="12")?
}
