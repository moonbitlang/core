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

test "new_by_leaves" {
  let e : T[Int] = new_by_leaves(0, fn(_s, _l) { abort("never reach") })
  let v = new_by_leaves(5, fn(_s, l) { FixedArray::make(l, 1) })
  let v2 = new_by_leaves(33, fn(_s, l) { FixedArray::make(l, 10) })
  inspect!(e, content="@immut/array.of([])")
  inspect!(v, content="@immut/array.of([1, 1, 1, 1, 1])")
  inspect!(
    v2,
    content="@immut/array.of([10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10])",
  )
  let v3 = new_by_leaves(32, fn(_s, l) { FixedArray::make(l, 10) })
  inspect!(
    v3,
    content="@immut/array.of([10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10])",
  )
}

test "mix" {
  let mut v = T::new()
  inspect!(v.tree.is_empty_tree(), content="true")
  for i = 0; i < 100; i = i + 1 {
    v = v.push(i)
  }
  inspect!(
    v,
    content="@immut/array.of([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99])",
  )
  let mut v2 = v.copy()
  for i = 0; i < 100; i = i + 1 {
    v2 = v2.set(i, i * 2)
  }
  let mut ct = 0
  v.each(fn(e) { ct = ct + e })
  inspect!(ct, content="4950")
  v2.each(fn(e) { ct = ct + e })
  inspect!(ct, content="14850")
  v2 = v2.map(fn(e) { e * 2 })
  let ct1 = v2.fold(fn(a, b) { a + b }, init=0)
  let ct2 = v2.rev_fold(fn(a, b) { a + b }, init=0)
  inspect!(ct1, content="19800")
  inspect!(ct2, content="19800")
  inspect!(v.tree.is_empty_tree(), content="false")
  let large_const = branching_factor * branching_factor + 1
  let mut v = T::new()
  for i = 0; i < large_const; i = i + 1 {
    v = v.push(i)
  }
  let vec = []
  v.eachi(fn(i, _e) { vec.push(i) })
  for i = 0; i < large_const; i = i + 1 {
    assert_eq!(vec[i], i)
  }
}

test "concat-two-full-tree" {
  let bf2 = branching_factor * branching_factor
  let v_content = []
  for i = 0; i < bf2; i = i + 1 {
    v_content.push(i)
  }
  let v_content = FixedArray::from_array(v_content)
  let v = T::of(v_content)
  inspect!(v, content="@immut/array.of(\{v_content})")
  let v2_content = []
  for i = 0; i < bf2; i = i + 1 {
    v2_content.push(i)
  }
  let v2_content = FixedArray::from_array(v2_content)
  let v2 = T::of(v2_content)
  inspect!(v2, content="@immut/array.of(\{v2_content})")
  let c = v.concat(v2)
  let c_content = v_content + v2_content
  inspect!(c, content="@immut/array.of(\{c_content})")
}

test "concat-full-tree-and-a-leaf" {
  let bf2 = branching_factor * branching_factor
  let v_content = []
  for i = 0; i < bf2; i = i + 1 {
    v_content.push(i)
  }
  let v_content = FixedArray::from_array(v_content)
  let v = T::of(v_content)
  inspect!(v, content="@immut/array.of(\{v_content})")
  let v2_content = FixedArray::from_array([0])
  let v2 = T::of(v2_content)
  inspect!(v2, content="@immut/array.of(\{v2_content})")
  let c = v.concat(v2)
  let c_content = v_content + v2_content
  inspect!(c, content="@immut/array.of(\{c_content})")
}

test "concat-a-leaf-and-full-tree" {
  let v_content = FixedArray::from_array([0])
  let v = T::of(v_content)
  inspect!(v, content="@immut/array.of(\{v_content})")
  let bf2 = branching_factor * branching_factor
  let v2_content = []
  for i = 0; i < bf2; i = i + 1 {
    v2_content.push(i)
  }
  let v2_content = FixedArray::from_array(v2_content)
  let v2 = T::of(v2_content)
  inspect!(v2, content="@immut/array.of(\{v2_content})")
  let c = v.concat(v2)
  let c_content = v_content + v2_content
  inspect!(c, content="@immut/array.of(\{c_content})")
}

test "concat-two-leaf" {
  let v_content = FixedArray::makei(branching_factor, fn(i) { i })
  let v = T::of(v_content)
  inspect!(v, content="@immut/array.of(\{v_content})")
  let v2_content = FixedArray::makei(branching_factor, fn(i) {
    i + branching_factor
  })
  let v2 = T::of(v2_content)
  inspect!(v2, content="@immut/array.of(\{v2_content})")
  let c = v.concat(v2)
  let c_content = v_content + v2_content
  inspect!(c, content="@immut/array.of(\{c_content})")
}

test "concat-multiple-full-tree" {
  let bf2 = branching_factor * branching_factor
  seq_concat_test!(
    42,
    fn(_i) { FixedArray::makei(bf2, fn(i) { i }) },
    FixedArray::from_array([]),
  )
}

test "concat-multiple-random-tree" {
  let bq4 = branching_factor *
    branching_factor *
    branching_factor *
    branching_factor
  let max_val = 2024
  seq_concat_test!(
    42,
    fn(_i) {
      let len = rand(bq4)
      FixedArray::makei(len, fn(_i) { rand(max_val) })
    },
    FixedArray::from_array([]),
  )
}

///|
fn rand(upper : Int) -> Int {
  let rng = @random.new()
  rng.int() % upper
}

///|
fn seq_concat_test[A : Show](
  rep : Int,
  gen : (Int) -> FixedArray[A],
  init : FixedArray[A]
) -> Unit! {
  let mut t = T::of(init)
  let mut t_content = init
  for i = 0; i < rep; i = i + 1 {
    let v1_content = gen(i)
    let v1 = T::of(v1_content)
    inspect!(v1, content="@immut/array.of(\{v1_content})")
    t = t.concat(v1)
    t_content = t_content + v1_content
    inspect!(init, content="@immut/array.of(\{t_content})")
  }
}
