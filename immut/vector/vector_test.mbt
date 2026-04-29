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
  let v = @vector.from_array([1, 2, 3, 4, 5])
  let ve : @vector.Vector[Int] = @vector.new()
  inspect(v.is_empty(), content="false")
  inspect(ve.is_empty(), content="true")
}

///|
test "arbitrary samples" {
  let samples = (@quickcheck.samples(3) : Array[@vector.Vector[Int]])
  inspect(samples.length(), content="3")
}

///|
test "set with valid index" {
  let v = @vector.from_array([1, 2, 3, 4, 5])
  let v1 = v.set(2, 10) // This should not trigger the panic
  inspect(v1, content="@immut/vector.from_array([1, 2, 10, 4, 5])")
}

///|
test "set with valid index at end" {
  let v = @vector.from_array([1, 2, 3, 4, 5])
  let v1 = v.set(4, 10) // This should not trigger the panic
  inspect(v1, content="@immut/vector.from_array([1, 2, 3, 4, 10])")
}

///|
test "to_string" {
  let v = @vector.from_array([1, 2, 3, 4, 5])
  let ve : @vector.Vector[Int] = @vector.new()
  inspect(v, content="@immut/vector.from_array([1, 2, 3, 4, 5])")
  inspect(ve, content="@immut/vector.from_array([])")
}

///|
test "singleton" {
  let v = @vector.singleton(7)
  inspect(v, content="@immut/vector.from_array([7])")
  inspect(v.length(), content="1")
}

///|
test "make with full leaf" {
  let v = @vector.make(32, 7)
  inspect(v.length(), content="32")
  inspect(v[0], content="7")
  inspect(v[31], content="7")
}

///|
test "to_array" {
  let v = @vector.from_array([1, 2, 3, 4])
  inspect(v.to_array().to_string(), content="[1, 2, 3, 4]")
  inspect(v.push(5).to_array().to_string(), content="[1, 2, 3, 4, 5]")
}

///|
test "to_array empty" {
  let v : @vector.Vector[Int] = @vector.new()
  inspect(v.to_array().to_string(), content="[]")
}

///|
test "to_json" {
  let v = @vector.from_iter((0).until(40))
  let expected = Json::array(Array::makei(40, i => i.to_json()))
  @json.json_inspect(v, content=expected)
  let empty : @vector.Vector[Int] = @vector.new()
  @json.json_inspect(empty, content=[])
}

///|
test "from_json" {
  for xs in (@quickcheck.samples(20) : Array[@vector.Vector[Int]]) {
    assert_eq(xs, @json.from_json(xs.to_json()))
  }
}

///|
test "from_json rejects invalid input" {
  let not_array : Result[@vector.Vector[Int], @json.JsonDecodeError] = try? @json.from_json({
      "a": 1,
    },
  )
  @json.json_inspect(not_array, content={
    "Err": ["JsonDecodeError", ["", "@immut/vector.from_json: expected array"]],
  })
  let bad_item : Result[@vector.Vector[Int], @json.JsonDecodeError] = try? @json.from_json([
      1, "x", 3,
    ],
  )
  @json.json_inspect(bad_item, content={
    "Err": ["JsonDecodeError", ["/1", "Int::from_json: expected number"]],
  })
}

///|
test "iter" {
  let buf = StringBuilder::new(size_hint=20)
  let v = @vector.from_array([1, 2, 3])
  v.iter().each(e => buf.write_string("[\{e}]"))
  inspect(buf, content="[1][2][3]")
  buf.reset()
  v.iter().take(2).each(e => buf.write_string("[\{e}]"))
  inspect(buf, content="[1][2]")
}

///|
test "length" {
  let v = @vector.from_array([1, 2, 3, 4, 5])
  let ve : @vector.Vector[Int] = @vector.new()
  inspect(v.length(), content="5")
  inspect(ve.length(), content="0")
}

///|
test "get" {
  let v = @vector.from_array([1, 2, 3, 4, 5])
  inspect(v[0], content="1")
  inspect(v[1], content="2")
  inspect(v[2], content="3")
  inspect(v[3], content="4")
  inspect(v[4], content="5")
}

///|
test "set" {
  let v = @vector.from_array([1, 2, 3, 4, 5])
  let v1 = v.set(1, 10)
  let v2 = v.set(2, 10)
  inspect(v1, content="@immut/vector.from_array([1, 10, 3, 4, 5])")
  inspect(v2, content="@immut/vector.from_array([1, 2, 10, 4, 5])")
}

///|
test "push" {
  let v = @vector.new().push(1).push(2).push(3)
  inspect(v, content="@immut/vector.from_array([1, 2, 3])")
  inspect(v.push(1), content="@immut/vector.from_array([1, 2, 3, 1])")
  inspect(v.push(2), content="@immut/vector.from_array([1, 2, 3, 2])")
  inspect(v.push(3), content="@immut/vector.from_array([1, 2, 3, 3])")
}

///|
test "from_array" {
  let v = @vector.from_array([1, 1, 4, 5, 1, 4])
  let vv = @vector.from_array(Array::make(30, 1))
  inspect(v, content="@immut/vector.from_array([1, 1, 4, 5, 1, 4])")
  inspect(
    vv,
    content="@immut/vector.from_array([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])",
  )
}

///|
test "Vector constructor" {
  let v = @vector.Vector([1, 1, 4, 5, 1, 4])
  inspect(v, content="@immut/vector.from_array([1, 1, 4, 5, 1, 4])")
}

///|
test "iteri" {
  let v : @vector.Vector[Int] = @vector.new()
  v.eachi((_i, _e) => abort("never reach"))
  let v = @vector.from_array([1, 2, 3, 4, 5])
  let mut s = 0
  v.eachi((i, e) => s = s + i * e)
  inspect(s, content="40")
  let vec = []
  v.eachi((i, _e) => vec.push(i))
  inspect(vec, content="[0, 1, 2, 3, 4]")
}

///|
test "equal" {
  let v0 : @vector.Vector[Int] = @vector.from_array([])
  let v1 = @vector.from_array([1, 2, 3, 4, 5])
  let v2 = @vector.from_array([1, 2, 3, 4, 5])
  let v3 = @vector.from_array([1, 2, 3, 4, 6])
  let v4 = @vector.from_array([1, 2, 3, 4])
  let v5 = @vector.make(5, 1)
  let v6 = @vector.from_array([1, 1, 1, 1, 1])
  inspect(v0 == @vector.new(), content="true")
  inspect(v1 == v2, content="true")
  inspect(v1 == v3, content="false")
  inspect(v1 == v4, content="false")
  inspect(v5 == v6, content="true")
}

///|
test "add concat" {
  let left = @vector.from_array([1, 2])
  let right = @vector.from_array([3, 4])
  inspect(left + right, content="@immut/vector.from_array([1, 2, 3, 4])")
}

///|
test "fold" {
  let e = @vector.new()
  let v = @vector.from_array([1, 2, 3, 4, 5])
  inspect(e.fold((a, b) => a + b, init=0), content="0")
  inspect(v.fold((a, b) => a + b, init=0), content="15")
}

///|
test "rev_fold" {
  let e = @vector.new()
  inspect(e.rev_fold((a, b) => a + b, init=0), content="0")
  let v = @vector.from_array([1, 2, 3, 4, 5])
  inspect(e.fold((a, b) => a + b, init=0), content="0")
  inspect(v.rev_fold((a, b) => a + b, init=0), content="15")
}

///|
test "map" {
  let v = @vector.from_array([1, 2, 3, 4, 5])
  inspect(
    v.map(e => e * 2),
    content="@immut/vector.from_array([2, 4, 6, 8, 10])",
  )
  inspect(
    v.map(e => e.to_string()),
    content=(
      #|@immut/vector.from_array(["1", "2", "3", "4", "5"])
    ),
  )
  inspect(
    v.map(e => e % 2 == 0),
    content="@immut/vector.from_array([false, true, false, true, false])",
  )
  inspect(
    @vector.new().map((e : Int) => e),
    content="@immut/vector.from_array([])",
  )
}

///|
test "filter" {
  let values = @vector.from_iter((0).until(40))
  inspect(
    values.filter(x => x % 7 == 0),
    content="@immut/vector.from_array([0, 7, 14, 21, 28, 35])",
  )
  inspect(values.filter(_ => false), content="@immut/vector.from_array([])")
}

///|
test "rev" {
  let values = @vector.from_iter((0).until(40))
  inspect(
    values.rev(),
    content=(
      #|@immut/vector.from_array([39, 38, 37, 36, 35, 34, 33, 32, 31, 30, 29, 28, 27, 26, 25, 24, 23, 22, 21, 20, 19, 18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0])
    ),
  )
  inspect(
    (@vector.new() : @vector.Vector[Int]).rev(),
    content="@immut/vector.from_array([])",
  )
}

///|
test "contains" {
  let values = @vector.from_iter((0).until(40))
  inspect(values.contains(0), content="true")
  inspect(values.contains(31), content="true")
  inspect(values.contains(39), content="true")
  inspect(values.contains(40), content="false")
  inspect((@vector.new() : @vector.Vector[Int]).contains(1), content="false")
}

///|
test "new" {
  let v = @vector.make(5, 1)
  let v2 = @vector.make(33, 10)
  inspect(v, content="@immut/vector.from_array([1, 1, 1, 1, 1])")
  inspect(
    v2,
    content="@immut/vector.from_array([10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10])",
  )
}

///|
test "new_with" {
  let v = @vector.makei(5, i => i)
  let v2 = @vector.makei(33, i => i * 10)
  inspect(v, content="@immut/vector.from_array([0, 1, 2, 3, 4])")
  inspect(
    v2,
    content="@immut/vector.from_array([0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320])",
  )
}

///|
test "from_iter multiple elements iter" {
  inspect(
    @vector.from_iter([1, 2, 3].iter()),
    content="@immut/vector.from_array([1, 2, 3])",
  )
  inspect(
    (0).until(32) |> @vector.from_iter(),
    content="@immut/vector.from_array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31])",
  )
  inspect(
    (0).until(33) |> @vector.from_iter(),
    content="@immut/vector.from_array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32])",
  )
}

///|
test "from_iter single element iter" {
  inspect(
    @vector.from_iter([1].iter()),
    content="@immut/vector.from_array([1])",
  )
}

///|
test "from_iter empty iter" {
  let pq : @vector.Vector[Int] = @vector.from_iter(Iter::empty())
  inspect(pq, content="@immut/vector.from_array([])")
}

///|
test "hash" {
  let l1 = @vector.from_array([1, 2, 3, 4, 5])
  let l2 = @vector.from_array([1, 2, 3, 4, 5])
  inspect(l1.hash() == l2.hash(), content="true")
  let l3 = @vector.from_array([5, 4, 3, 2, 1])
  inspect(l1.hash() == l3.hash(), content="false")
  let l4 : @vector.Vector[Int] = @vector.from_array([])
  inspect(l1.hash() == l4.hash(), content="false")
  inspect(l4.hash() == l4.hash(), content="true")
}

///|
test "concat_empty" {
  let a = @vector.from_array([1, 2, 3])
  let b : @vector.Vector[Int] = @vector.new()
  let c = a.concat(b)
  inspect(c, content="@immut/vector.from_array([1, 2, 3])")
  let a : @vector.Vector[Int] = @vector.new()
  let b = @vector.from_array([1, 2, 3])
  let c = a.concat(b)
  inspect(c, content="@immut/vector.from_array([1, 2, 3])")
}

///|
test "split" {
  let values = @vector.from_iter((0).until(40))
  let (left, right) = values.split(13)
  assert_eq(left.to_array(), Array::makei(13, i => i))
  assert_eq(right.to_array(), Array::makei(27, i => i + 13))
  let (empty, all) = values.split(0)
  assert_eq(empty.to_array(), [])
  assert_eq(all, values)
  let (all, empty) = values.split(40)
  assert_eq(all, values)
  assert_eq(empty.to_array(), [])
}

///|
test "take drop and slice" {
  let values = @vector.from_iter((0).until(40))
  assert_eq(values.take(5).to_array(), [0, 1, 2, 3, 4])
  assert_eq(values.take(100), values)
  assert_eq(values.take(-1).to_array(), [])
  assert_eq(values.drop(35).to_array(), [35, 36, 37, 38, 39])
  assert_eq(values.drop(100).to_array(), [])
  assert_eq(values.drop(-1), values)
  assert_eq(values.slice(7, 12).to_array(), [7, 8, 9, 10, 11])
  assert_eq(values.slice(0, 40), values)
  inspect(
    values.slice(10, 20),
    content=(
      #|@immut/vector.from_array([10, 11, 12, 13, 14, 15, 16, 17, 18, 19])
    ),
  )
}

///|
test "compare" {
  let arr1 = @vector.from_array([1, 2, 3])
  let arr2 = @vector.from_array([1, 2, 4])
  let arr3 = @vector.from_array([1, 2])
  let empty : @vector.Vector[Int] = @vector.new()
  inspect(arr1.compare(arr2), content="-1")
  inspect(arr1.compare(arr3), content="1")
  inspect(arr3.compare(arr1), content="-1")
  inspect(arr1.compare(arr1), content="0")
  inspect(empty.compare(empty), content="0")
}

///|
test "@vector.get/normal" {
  let arr = @vector.from_array([1, 2, 3, 4, 5])
  debug_inspect(arr.get(2), content="Some(3)")
}

///|
test "@vector.get/first" {
  let arr = @vector.from_array([42])
  debug_inspect(arr.get(0), content="Some(42)")
}

///|
test "@vector.get/out_of_bounds" {
  let arr = @vector.from_array([1, 2, 3])
  debug_inspect(arr.get(-1), content="None")
  debug_inspect(arr.get(3), content="None")
}
