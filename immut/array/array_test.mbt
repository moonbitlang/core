// Copyright 2025 International Digital Economy Academy
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
  let v = @array.of([1, 2, 3, 4, 5])
  let ve : @array.T[Int] = @array.new()
  inspect!(v.is_empty(), content="false")
  inspect!(ve.is_empty(), content="true")
}

///|
test "set with valid index" {
  let v = @array.of([1, 2, 3, 4, 5])
  let v1 = v.set(2, 10) // This should not trigger the panic
  inspect!(v1, content="@immut/array.of([1, 2, 10, 4, 5])")
}

///|
test "set with valid index at end" {
  let v = @array.of([1, 2, 3, 4, 5])
  let v1 = v.set(4, 10) // This should not trigger the panic
  inspect!(v1, content="@immut/array.of([1, 2, 3, 4, 10])")
}

///|
test "to_string" {
  let v = @array.of([1, 2, 3, 4, 5])
  let ve : @array.T[Int] = @array.new()
  inspect!(v, content="@immut/array.of([1, 2, 3, 4, 5])")
  inspect!(ve, content="@immut/array.of([])")
}

///|
test "to_array" {
  let v = @array.of([1, 2, 3, 4])
  inspect!(v.to_array().to_string(), content="[1, 2, 3, 4]")
  inspect!(v.push(5).to_array().to_string(), content="[1, 2, 3, 4, 5]")
}

///|
test "iter" {
  let buf = StringBuilder::new(size_hint=20)
  let v = @array.of([1, 2, 3])
  v.iter().each(fn(e) { buf.write_string("[\{e}]") })
  inspect!(buf, content="[1][2][3]")
  buf.reset()
  v.iter().take(2).each(fn(e) { buf.write_string("[\{e}]") })
  inspect!(buf, content="[1][2]")
}

///|
test "length" {
  let v = @array.of([1, 2, 3, 4, 5])
  let ve : @array.T[Int] = @array.new()
  inspect!(v.length(), content="5")
  inspect!(ve.length(), content="0")
}

///|
test "op_get" {
  let v = @array.of([1, 2, 3, 4, 5])
  inspect!(v[0], content="1")
  inspect!(v[1], content="2")
  inspect!(v[2], content="3")
  inspect!(v[3], content="4")
  inspect!(v[4], content="5")
}

///|
test "set" {
  let v = @array.of([1, 2, 3, 4, 5])
  let v1 = v.set(1, 10)
  let v2 = v.set(2, 10)
  inspect!(v1, content="@immut/array.of([1, 10, 3, 4, 5])")
  inspect!(v2, content="@immut/array.of([1, 2, 10, 4, 5])")
}

///|
test "push" {
  let v = @array.new().push(1).push(2).push(3)
  inspect!(v, content="@immut/array.of([1, 2, 3])")
  inspect!(v.push(1), content="@immut/array.of([1, 2, 3, 1])")
  inspect!(v.push(2), content="@immut/array.of([1, 2, 3, 2])")
  inspect!(v.push(3), content="@immut/array.of([1, 2, 3, 3])")
}

///|
test "from_array" {
  let v = @array.of([1, 1, 4, 5, 1, 4])
  let vv = @array.from_array(Array::make(30, 1))
  inspect!(v, content="@immut/array.of([1, 1, 4, 5, 1, 4])")
  inspect!(
    vv,
    content="@immut/array.of([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])",
  )
}

///|
test "iter" {
  let v = @array.of([1, 2, 3, 4, 5])
  let mut s = 0
  v.each(fn(e) { s = s + e })
  inspect!(s, content="15")
  let v : @array.T[Int] = @array.new()
  v.each(fn(_e) { abort("never reach") })
}

///|
test "iteri" {
  let v : @array.T[Int] = @array.new()
  v.eachi(fn(_i, _e) { abort("never reach") })
  let v = @array.of([1, 2, 3, 4, 5])
  let mut s = 0
  v.eachi(fn(i, e) { s = s + i * e })
  inspect!(s, content="40")
  let vec = []
  v.eachi(fn(i, _e) { vec.push(i) })
  inspect!(vec, content="[0, 1, 2, 3, 4]")
}

///|
test "op_equal" {
  let v0 : @array.T[Int] = @array.of([])
  let v1 = @array.of([1, 2, 3, 4, 5])
  let v2 = @array.of([1, 2, 3, 4, 5])
  let v3 = @array.of([1, 2, 3, 4, 6])
  let v4 = @array.of([1, 2, 3, 4])
  let v5 = @array.make(5, 1)
  let v6 = @array.of([1, 1, 1, 1, 1])
  inspect!(v0 == @array.new(), content="true")
  inspect!(v1 == v2, content="true")
  inspect!(v1 == v3, content="false")
  inspect!(v1 == v4, content="false")
  inspect!(v5 == v6, content="true")
}

///|
test "fold" {
  let e = @array.new()
  let v = @array.of([1, 2, 3, 4, 5])
  inspect!(e.fold(fn(a, b) { a + b }, init=0), content="0")
  inspect!(v.fold(fn(a, b) { a + b }, init=0), content="15")
}

///|
test "rev_fold" {
  let e = @array.new()
  inspect!(e.rev_fold(fn(a, b) { a + b }, init=0), content="0")
  let v = @array.of([1, 2, 3, 4, 5])
  inspect!(e.fold(fn(a, b) { a + b }, init=0), content="0")
  inspect!(v.rev_fold(fn(a, b) { a + b }, init=0), content="15")
}

///|
test "map" {
  let v = @array.of([1, 2, 3, 4, 5])
  inspect!(v.map(fn(e) { e * 2 }), content="@immut/array.of([2, 4, 6, 8, 10])")
  inspect!(
    v.map(fn(e) { e.to_string() }),
    content=
      #|@immut/array.of(["1", "2", "3", "4", "5"])
    ,
  )
  inspect!(
    v.map(fn(e) { e % 2 == 0 }),
    content="@immut/array.of([false, true, false, true, false])",
  )
  inspect!(@array.new().map(fn(e : Int) { e }), content="@immut/array.of([])")
}

///|
test "new" {
  let v = @array.make(5, 1)
  let v2 = @array.make(33, 10)
  inspect!(v, content="@immut/array.of([1, 1, 1, 1, 1])")
  inspect!(
    v2,
    content="@immut/array.of([10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10])",
  )
}

///|
test "new_with" {
  let v = @array.makei(5, fn(i) { i })
  let v2 = @array.makei(33, fn(i) { i * 10 })
  inspect!(v, content="@immut/array.of([0, 1, 2, 3, 4])")
  inspect!(
    v2,
    content="@immut/array.of([0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320])",
  )
}

///|
test "from_iter multiple elements iter" {
  inspect!(
    @array.from_iter([1, 2, 3].iter()),
    content="@immut/array.of([1, 2, 3])",
  )
  inspect!(
    (0).until(32) |> @array.from_iter(),
    content="@immut/array.of([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31])",
  )
  inspect!(
    (0).until(33) |> @array.from_iter(),
    content="@immut/array.of([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32])",
  )
}

///|
test "from_iter single element iter" {
  inspect!(@array.from_iter([1].iter()), content="@immut/array.of([1])")
}

///|
test "from_iter empty iter" {
  let pq : @array.T[Int] = @array.from_iter(Iter::empty())
  inspect!(pq, content="@immut/array.of([])")
}

///|
test "hash" {
  let l1 = @array.of([1, 2, 3, 4, 5])
  let l2 = @array.of([1, 2, 3, 4, 5])
  inspect!(l1.hash() == l2.hash(), content="true")
  let l3 = @array.of([5, 4, 3, 2, 1])
  inspect!(l1.hash() == l3.hash(), content="false")
  let l4 : @array.T[Int] = @array.of([])
  inspect!(l1.hash() == l4.hash(), content="false")
  inspect!(l4.hash() == l4.hash(), content="true")
}

///|
test "concat_empty" {
  let a = @array.of([1, 2, 3])
  let b : @array.T[Int] = @array.new()
  let c = a.concat(b)
  inspect!(c, content="@immut/array.of([1, 2, 3])")
  let a : @array.T[Int] = @array.new()
  let b = @array.of([1, 2, 3])
  let c = a.concat(b)
  inspect!(c, content="@immut/array.of([1, 2, 3])")
}
