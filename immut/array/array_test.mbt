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
test "is_empty" {
  let v = @array.from_array([1, 2, 3, 4, 5])
  let ve : @array.T[Int] = @array.new()
  inspect(v.is_empty(), content="false")
  inspect(ve.is_empty(), content="true")
}

///|
test "arbitrary samples" {
  let samples = (@quickcheck.samples(3) : Array[@array.T[Int]])
  inspect(samples.length(), content="3")
}

///|
test "set with valid index" {
  let v = @array.from_array([1, 2, 3, 4, 5])
  let v1 = v.set(2, 10) // This should not trigger the panic
  inspect(v1, content="@immut/array.from_array([1, 2, 10, 4, 5])")
}

///|
test "set with valid index at end" {
  let v = @array.from_array([1, 2, 3, 4, 5])
  let v1 = v.set(4, 10) // This should not trigger the panic
  inspect(v1, content="@immut/array.from_array([1, 2, 3, 4, 10])")
}

///|
test "to_string" {
  let v = @array.from_array([1, 2, 3, 4, 5])
  let ve : @array.T[Int] = @array.new()
  inspect(v, content="@immut/array.from_array([1, 2, 3, 4, 5])")
  inspect(ve, content="@immut/array.from_array([])")
}

///|
test "make with full leaf" {
  let v = @array.make(32, 7)
  inspect(v.length(), content="32")
  inspect(v[0], content="7")
  inspect(v[31], content="7")
}

///|
test "to_array" {
  let v = @array.from_array([1, 2, 3, 4])
  inspect(v.to_array().to_string(), content="[1, 2, 3, 4]")
  inspect(v.push(5).to_array().to_string(), content="[1, 2, 3, 4, 5]")
}

///|
test "to_array empty" {
  let v : @array.T[Int] = @array.new()
  inspect(v.to_array().to_string(), content="[]")
}

///|
test "iter" {
  let buf = StringBuilder::new(size_hint=20)
  let v = @array.from_array([1, 2, 3])
  v.iter().each(e => buf.write_string("[\{e}]"))
  inspect(buf, content="[1][2][3]")
  buf.reset()
  v.iter().take(2).each(e => buf.write_string("[\{e}]"))
  inspect(buf, content="[1][2]")
}

///|
test "length" {
  let v = @array.from_array([1, 2, 3, 4, 5])
  let ve : @array.T[Int] = @array.new()
  inspect(v.length(), content="5")
  inspect(ve.length(), content="0")
}

///|
test "get" {
  let v = @array.from_array([1, 2, 3, 4, 5])
  inspect(v[0], content="1")
  inspect(v[1], content="2")
  inspect(v[2], content="3")
  inspect(v[3], content="4")
  inspect(v[4], content="5")
}

///|
test "set" {
  let v = @array.from_array([1, 2, 3, 4, 5])
  let v1 = v.set(1, 10)
  let v2 = v.set(2, 10)
  inspect(v1, content="@immut/array.from_array([1, 10, 3, 4, 5])")
  inspect(v2, content="@immut/array.from_array([1, 2, 10, 4, 5])")
}

///|
test "push" {
  let v = @array.new().push(1).push(2).push(3)
  inspect(v, content="@immut/array.from_array([1, 2, 3])")
  inspect(v.push(1), content="@immut/array.from_array([1, 2, 3, 1])")
  inspect(v.push(2), content="@immut/array.from_array([1, 2, 3, 2])")
  inspect(v.push(3), content="@immut/array.from_array([1, 2, 3, 3])")
}

///|
test "from_array" {
  let v = @array.from_array([1, 1, 4, 5, 1, 4])
  let vv = @array.from_array(Array::make(30, 1))
  inspect(v, content="@immut/array.from_array([1, 1, 4, 5, 1, 4])")
  inspect(
    vv,
    content="@immut/array.from_array([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])",
  )
}

///|
test "iteri" {
  let v : @array.T[Int] = @array.new()
  v.eachi((_i, _e) => abort("never reach"))
  let v = @array.from_array([1, 2, 3, 4, 5])
  let mut s = 0
  v.eachi((i, e) => s = s + i * e)
  inspect(s, content="40")
  let vec = []
  v.eachi((i, _e) => vec.push(i))
  inspect(vec, content="[0, 1, 2, 3, 4]")
}

///|
test "equal" {
  let v0 : @array.T[Int] = @array.from_array([])
  let v1 = @array.from_array([1, 2, 3, 4, 5])
  let v2 = @array.from_array([1, 2, 3, 4, 5])
  let v3 = @array.from_array([1, 2, 3, 4, 6])
  let v4 = @array.from_array([1, 2, 3, 4])
  let v5 = @array.make(5, 1)
  let v6 = @array.from_array([1, 1, 1, 1, 1])
  inspect(v0 == @array.new(), content="true")
  inspect(v1 == v2, content="true")
  inspect(v1 == v3, content="false")
  inspect(v1 == v4, content="false")
  inspect(v5 == v6, content="true")
}

///|
test "add concat" {
  let left = @array.from_array([1, 2])
  let right = @array.from_array([3, 4])
  inspect(left + right, content="@immut/array.from_array([1, 2, 3, 4])")
}

///|
test "fold" {
  let e = @array.new()
  let v = @array.from_array([1, 2, 3, 4, 5])
  inspect(e.fold((a, b) => a + b, init=0), content="0")
  inspect(v.fold((a, b) => a + b, init=0), content="15")
}

///|
test "rev_fold" {
  let e = @array.new()
  inspect(e.rev_fold((a, b) => a + b, init=0), content="0")
  let v = @array.from_array([1, 2, 3, 4, 5])
  inspect(e.fold((a, b) => a + b, init=0), content="0")
  inspect(v.rev_fold((a, b) => a + b, init=0), content="15")
}

///|
test "map" {
  let v = @array.from_array([1, 2, 3, 4, 5])
  inspect(
    v.map(e => e * 2),
    content="@immut/array.from_array([2, 4, 6, 8, 10])",
  )
  inspect(
    v.map(e => e.to_string()),
    content=(
      #|@immut/array.from_array(["1", "2", "3", "4", "5"])
    ),
  )
  inspect(
    v.map(e => e % 2 == 0),
    content="@immut/array.from_array([false, true, false, true, false])",
  )
  inspect(
    @array.new().map((e : Int) => e),
    content="@immut/array.from_array([])",
  )
}

///|
test "new" {
  let v = @array.make(5, 1)
  let v2 = @array.make(33, 10)
  inspect(v, content="@immut/array.from_array([1, 1, 1, 1, 1])")
  inspect(
    v2,
    content="@immut/array.from_array([10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10])",
  )
}

///|
test "new_with" {
  let v = @array.makei(5, i => i)
  let v2 = @array.makei(33, i => i * 10)
  inspect(v, content="@immut/array.from_array([0, 1, 2, 3, 4])")
  inspect(
    v2,
    content="@immut/array.from_array([0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320])",
  )
}

///|
test "from_iter multiple elements iter" {
  inspect(
    @array.from_iter([1, 2, 3].iter()),
    content="@immut/array.from_array([1, 2, 3])",
  )
  inspect(
    (0).until(32) |> @array.from_iter(),
    content="@immut/array.from_array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31])",
  )
  inspect(
    (0).until(33) |> @array.from_iter(),
    content="@immut/array.from_array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32])",
  )
}

///|
test "from_iter single element iter" {
  inspect(@array.from_iter([1].iter()), content="@immut/array.from_array([1])")
}

///|
test "from_iter empty iter" {
  let pq : @array.T[Int] = @array.from_iter(Iter::empty())
  inspect(pq, content="@immut/array.from_array([])")
}

///|
test "hash" {
  let l1 = @array.from_array([1, 2, 3, 4, 5])
  let l2 = @array.from_array([1, 2, 3, 4, 5])
  inspect(l1.hash() == l2.hash(), content="true")
  let l3 = @array.from_array([5, 4, 3, 2, 1])
  inspect(l1.hash() == l3.hash(), content="false")
  let l4 : @array.T[Int] = @array.from_array([])
  inspect(l1.hash() == l4.hash(), content="false")
  inspect(l4.hash() == l4.hash(), content="true")
}

///|
test "concat_empty" {
  let a = @array.from_array([1, 2, 3])
  let b : @array.T[Int] = @array.new()
  let c = a.concat(b)
  inspect(c, content="@immut/array.from_array([1, 2, 3])")
  let a : @array.T[Int] = @array.new()
  let b = @array.from_array([1, 2, 3])
  let c = a.concat(b)
  inspect(c, content="@immut/array.from_array([1, 2, 3])")
}

///|
test "compare" {
  let arr1 = @array.from_array([1, 2, 3])
  let arr2 = @array.from_array([1, 2, 4])
  let arr3 = @array.from_array([1, 2])
  let empty : @array.T[Int] = @array.new()
  inspect(arr1.compare(arr2), content="-1")
  inspect(arr1.compare(arr3), content="1")
  inspect(arr3.compare(arr1), content="-1")
  inspect(arr1.compare(arr1), content="0")
  inspect(empty.compare(empty), content="0")
}

///|
test "@array.get/normal" {
  let arr = @array.from_array([1, 2, 3, 4, 5])
  inspect(arr.get(2), content="Some(3)")
}

///|
test "@array.get/first" {
  let arr = @array.from_array([42])
  inspect(arr.get(0), content="Some(42)")
}

///|
test "@array.get/out_of_bounds" {
  let arr = @array.from_array([1, 2, 3])
  inspect(arr.get(-1), content="None")
  inspect(arr.get(3), content="None")
}
