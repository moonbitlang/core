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
  inspect!(empty, content="[]")
  let a0 = [0]
  inspect!(a0, content="[0]")
  a0.push(1)
  inspect!(a0, content="[0, 1]")
  a0.push(2)
  inspect!(a0, content="[0, 1, 2]")
}

test "get" {
  let v = [3]
  inspect!(v.get(-1), content="None")
  inspect!(v.get(0), content="Some(3)")
  inspect!(v.get(1), content="None")
}

test "op_add" {
  inspect!(([] : Array[Int]) + [], content="[]")
  inspect!(([] : Array[Int]) + [1, 2, 3, 4, 5], content="[1, 2, 3, 4, 5]")
  inspect!([1, 2, 3, 4, 5] + [], content="[1, 2, 3, 4, 5]")
  inspect!(
    [1, 2, 3, 4, 5] + [6, 7, 8, 9, 10],
    content="[1, 2, 3, 4, 5, 6, 7, 8, 9, 10]",
  )
}

test "op_equal" {
  let v1 = [3, 4, 5]
  let v2 = [3, 4, 5]
  let v3 = [3, 4, 6]
  @test.is_true!(v1 == v2)
  @test.is_false!(v1 == v3)
}

test "pop" {
  let v = []
  v.push(3)
  v.push(4)
  @test.eq!(v.length(), 2)
  @test.eq!(v.pop(), Some(4))
  @test.eq!(v.pop(), Some(3))
  @test.eq!(v.length(), 0)
  @test.eq!(v.pop(), None)
}

test "pop_exn" {
  let v = []
  v.push(3)
  v.push(4)
  @test.eq!(v.length(), 2)
  @test.eq!(v.pop_exn(), 4)
  @test.eq!(v.pop_exn(), 3)
  @test.eq!(v.length(), 0)
}

test "push" {
  let v = [3, 4, 5]
  @test.eq!(v, [3, 4, 5])
  v[0] = 6
  @test.eq!(v, [6, 4, 5])
}

test "push_iter" {
  let u = [1, 2, 3]
  let v = [4, 5, 6]
  u.push_iter(v.iter())
  inspect!(u, content="[1, 2, 3, 4, 5, 6]")
}

test "drain" {
  let v = [3, 4, 5]
  let v2 = [1, 2, 3, 4, 5]
  let vv = v.drain(1, 2)
  let v2v = v2.drain(2, 5)
  @test.eq!(v, [3, 5])
  @test.eq!(vv, [4])
  @test.eq!(v2, [1, 2])
  @test.eq!(v2v, [3, 4, 5])
}

test "append" {
  let v1 = [3, 4, 5]
  let v2 = [6, 7, 8]
  v1.append(v2)
  @test.eq!(v1, [3, 4, 5, 6, 7, 8])
  @test.eq!(v1.length(), 6)
}

test "each" {
  let v = [3, 4, 5]
  let mut sum = 0
  v.each(fn(x) { sum = sum + x })
  @test.eq!(sum, 12)
}

test "each_rev" {
  let v = Array::new(capacity=3)
  v.push(3)
  v.push(4)
  v.push(5)
  let mut sum = 0
  v.rev_each(fn(x) { sum = sum + x })
  @test.eq!(sum, 12)
}

test "eachi" {
  let v = [3, 4, 5]
  let mut sum = 0
  v.eachi(fn(i, x) { sum = sum + x + i })
  @test.eq!(sum, 15)
}

test "each_revi" {
  let v = [3, 4, 5]
  let mut sum = 0
  v.rev_eachi(fn(i, x) { sum = sum + x + i })
  @test.eq!(sum, 15)
}

test "clear" {
  let v = [3, 4, 5]
  v.clear()
  @test.eq!(v.length(), 0)
}

test "map" {
  let v = [3, 4, 5]
  let e : Array[Int] = []
  inspect!(v.map(fn(x) { x + 1 }), content="[4, 5, 6]")
  inspect!(
    v.map(fn(x) { x.to_string() }),
    content=
      #|["3", "4", "5"]
    ,
  )
  inspect!(e.map(fn(x) { x + 1 }), content="[]")
  // Is it correct?
  inspect!(
    ["a", "b", "c"],
    content=
      #|["a", "b", "c"]
    ,
  )
}

test "map_inplace" {
  let v = [3, 4, 5]
  let e : Array[Int] = []
  v.map_inplace(fn(x) { x + 1 })
  e.map_inplace(fn(x) { x + 1 })
  inspect!(v, content="[4, 5, 6]")
  inspect!(e, content="[]")
}

test "mapi" {
  let v = [3, 4, 5]
  let e : Array[Int] = []
  inspect!(v.mapi(fn(i, x) { x + i }), content="[3, 5, 7]")
  inspect!(
    v.mapi(fn(i, x) { (x + i).to_string() }),
    content=
      #|["3", "5", "7"]
    ,
  )
  inspect!(e.mapi(fn(_i, x) { x + 1 }), content="[]")
}

test "mapi_inplace" {
  let v = [3, 4, 5]
  let e : Array[Int] = []
  v.mapi_inplace(fn(i, x) { x + i })
  e.mapi_inplace(fn(_i, x) { x + 1 })
  inspect!(v, content="[3, 5, 7]")
  inspect!(e, content="[]")
}

test "filter" {
  let arr = [1, 2, 3, 4, 5, 6]
  inspect!(arr.filter(fn(x) { x % 2 == 0 }), content="[2, 4, 6]")
}

test "is_empty" {
  let v = []
  @test.is_true!(v.is_empty())
  v.push(3)
  @test.is_false!(v.is_empty())
}

test "is_sorted" {
  let v : Array[Int] = []
  @test.is_true!(v.is_sorted())
  let v = [3, 4, 5]
  @test.is_true!(v.is_sorted())
  let v2 = [3, 5, 4]
  @test.is_false!(v2.is_sorted())
}

test "rev_inplace" {
  let v = [3, 4, 5]
  v.rev_inplace()
  @test.eq!(v, [5, 4, 3])
  v.rev_inplace()
  @test.eq!(v, [3, 4, 5])
  let v = [3, 4]
  v.rev_inplace()
  @test.eq!(v, [4, 3])
  v.rev_inplace()
  @test.eq!(v, [3, 4])
  let empty : Array[Int] = []
  @test.eq!(empty, empty)
}

test "rev" {
  let v = [3, 4, 5]
  let vv = v.rev()
  @test.eq!(v, [3, 4, 5])
  @test.eq!(vv, [5, 4, 3])
  let vv2 = vv.rev()
  @test.eq!(vv2, [3, 4, 5])
}

test "split_at" {
  let v = [3, 4, 5]
  let (v1, v2) = v.split_at(1)
  @test.eq!(v1, [3])
  @test.eq!(v2, [4, 5])
}

test "contains" {
  let v = [3, 4, 5]
  @test.is_true!(v.contains(3))
  @test.is_true!(v.contains(4))
  @test.is_true!(v.contains(5))
  @test.is_false!(v.contains(6))
}

test "starts_with" {
  let v = [3, 4, 5]
  @test.is_true!(v.starts_with([3, 4]))
  @test.is_true!(v.starts_with([3, 4, 5]))
  @test.is_false!(v.starts_with([3, 4, 6]))
  @test.is_false!(v.starts_with([3, 4, 5, 6]))
}

test "ends_with" {
  let v = [3, 4, 5]
  @test.is_true!(v.ends_with([4, 5]))
  @test.is_true!(v.ends_with([3, 4, 5]))
  @test.is_false!(v.ends_with([3, 4, 6]))
  @test.is_false!(v.ends_with([2, 3, 4, 5]))
}

test "strip_prefix" {
  let v = [3, 4, 5]
  let sv = v.strip_prefix([3])
  @test.eq!(v, [3, 4, 5])
  @test.eq!(sv, Some([4, 5]))
  @test.eq!(v.strip_prefix([4]), None)
}

test "strip_suffix" {
  let v = [3, 4, 5]
  let sv = v.strip_suffix([5])
  @test.eq!(v, [3, 4, 5])
  @test.eq!(sv, Some([3, 4]))
  @test.eq!(v.strip_suffix([4]), None)
}

test "search" {
  let v = [3, 4, 5]
  @test.eq!(v.search(3), Some(0))
  @test.eq!(v.search(4), Some(1))
  @test.eq!(v.search(5), Some(2))
  @test.eq!(v.search(6), None)
}

test "swap" {
  let v = [3, 4, 5]
  v.swap(0, 2)
  @test.eq!(v, [5, 4, 3])
  v.swap(0, 2)
  @test.eq!(v, [3, 4, 5])
}

test "remove" {
  let v = [3, 4, 5]
  @test.eq!(v.remove(1), 4)
  @test.eq!(v, [3, 5])
}

test "retain" {
  let v = [3, 4, 5]
  v.retain(fn(x) { x > 3 })
  @test.eq!(v, [4, 5])
}

test "resize" {
  let v = [3, 4, 5]
  v.resize(5, 0)
  @test.eq!(v, [3, 4, 5, 0, 0])
  @test.eq!(v.length(), 5)
  let vv = [3, 4, 5]
  vv.resize(2, 0)
  @test.eq!(vv, [3, 4])
  @test.eq!(vv.length(), 2)
}

test "insert" {
  let v = [3, 4, 5]
  v.insert(1, 6)
  @test.eq!(v, [3, 6, 4, 5])
  @test.eq!(v.length(), 4)
}

test "flatten" {
  let v = [[3, 4], [5, 6]]
  let vv = v.flatten()
  @test.eq!(vv, [3, 4, 5, 6])
  @test.eq!(vv.length(), 4)
}

test "repeat" {
  let v = [3, 4]
  let vv = v.repeat(2)
  @test.eq!(vv, [3, 4, 3, 4])
  @test.eq!(vv.length(), 4)
}

test "flatten" {
  let v = [[3, 4], [5, 6]]
  let vv = v.flatten()
  @test.eq!(vv, [3, 4, 5, 6])
  @test.eq!(vv.length(), 4)
}

test "join" {
  let v = [3, 4, 5]
  let s = v.join(", ")
  @test.eq!(s, "3, 4, 5")
}

test "fold_left" {
  let sum = [1, 2, 3, 4, 5].fold_left(init=0, fn { sum, elem => sum + elem })
  @test.eq!(sum, 15)
}

test "fold_right" {
  let sum = [1, 2, 3, 4, 5].fold_right(init=0, fn { sum, elem => sum + elem })
  @test.eq!(sum, 15)
}

test "fold_lefti" {
  let sum = [1, 2, 3, 4, 5].fold_lefti(
    init=0,
    fn { index, sum, _elem => sum + index },
  )
  @test.eq!(sum, 10)
}

test "fold_righti" {
  let sum = [1, 2, 3, 4, 5].fold_righti(
    init=0,
    fn { index, sum, _elem => sum + index },
  )
  @test.eq!(sum, 10)
}

test "dedup" {
  let v = [3, 4, 4, 5, 5, 5]
  v.dedup()
  @test.eq!(v, [3, 4, 5])
  @test.eq!(v.length(), 3)
}

test "extract_if" {
  let v = [3, 4, 5]
  let vv = v.extract_if(fn(x) { x > 3 })
  @test.eq!(v, [3])
  @test.eq!(v.length(), 1)
  @test.eq!(vv, [4, 5])
}

test "chunks" {
  let v = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  let chunks = v.chunks(3)
  let chunks2 = v.chunks(2)
  @test.eq!(chunks, [[1, 2, 3], [4, 5, 6], [7, 8, 9]])
  @test.eq!(chunks2, [[1, 2], [3, 4], [5, 6], [7, 8], [9]])
}

test "chunk_by" {
  let v = [1, 1, 2, 3, 2, 3, 2, 3, 4]
  let chunks = v.chunk_by(fn(x, y) { x <= y })
  @test.eq!(chunks[0], [1, 1, 2, 3])
  @test.eq!(chunks[1], [2, 3])
  @test.eq!(chunks[2], [2, 3, 4])
}

test "split" {
  let v = [1, 0, 2, 0, 3, 0, 4]
  let chunks = v.split(fn(x) { x == 0 })
  @test.eq!(chunks, [[1], [2], [3], [4]])
  @test.eq!(chunks.length(), 4)
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
  let v = Array::new(capacity=10)
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

test "iter" {
  let buf = Buffer::new(size_hint=5)
  [1, 2, 3, 4, 5].iter().each(fn { x => buf.write_string(x.to_string()) })
  inspect!(buf, content="12345")
  buf.reset()
  [1, 2, 3, 4, 5].iter().take(2).each(
    fn { x => buf.write_string(x.to_string()) },
  )
  inspect!(buf, content="12")
}

test "shuffle_in_place" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 6, 7]
  fn rand(upper : Int) -> Int {
    let rng = @random.init_state(seed=37)
    rng.gen_int() % upper
  }

  Array::shuffle_in_place(arr, ~rand)
  inspect!(arr, content="[3, 4, 7, 1, 6, 5, 2]")
}

test "shuffle" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 6, 7]
  fn rand(upper : Int) -> Int {
    let rng = @random.init_state(seed=42)
    rng.gen_int() % upper
  }

  let shuffled = Array::shuffle(arr, ~rand)
  inspect!(shuffled, content="[1, 5, 3, 4, 7, 6, 2]")
}

test "find_index" {
  let arr : Array[Int] = [1, 2, 3, 4, 5, 6, 7]
  let index = arr.find_index(fn(x) { x == 3 })
  @test.eq!(index, Some(2))
}

test "copy" {
  let arr = [1, 2, 3, 4, 5]
  let copied = arr.copy()
  @test.eq!(copied, [1, 2, 3, 4, 5])
  @test.is_not!(arr, copied)
  inspect!(([] : Array[Int]).copy(), content="[]")
}

test "Array::make_with_index with positive length" {
  let arr = Array::make_with_index(5, fn(i) { i * 2 })
  @test.eq!(arr, [0, 2, 4, 6, 8])
}

test "Array::make_with_index with zero length" {
  let arr = Array::make_with_index(0, fn(i) { i * 2 })
  @test.eq!(arr, [])
}

test "Array::make_with_index with negative length" {
  let arr = Array::make_with_index(-1, fn(i) { i * 2 })
  @test.eq!(arr, [])
}
