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
fn[T] Tree::is_empty_tree(self : Tree[T]) -> Bool {
  self is Empty
}

///|
test "mix" {
  let mut v = new()
  inspect(v.tree.is_empty_tree(), content="true")
  for i in 0..<100 {
    v = v.push(i)
  }
  inspect(
    v,
    content="@immut/array.from_array([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99])",
  )
  let v2 = for i in 0..<100; v2 = v {
    continue v2.set(i, i * 2)
  } nobreak {
    v2
  }
  let mut ct = 0
  v.each(e => ct = ct + e)
  inspect(ct, content="4950")
  v2.each(e => ct = ct + e)
  inspect(ct, content="14850")
  let v2 = v2.map(e => e * 2)
  let ct1 = v2.fold((a, b) => a + b, init=0)
  let ct2 = v2.rev_fold((a, b) => a + b, init=0)
  inspect(ct1, content="19800")
  inspect(ct2, content="19800")
  inspect(v.tree.is_empty_tree(), content="false")
  let large_const = branching_factor * branching_factor + 1
  let v = for i in 0..<large_const; v = (new() : T[Int]) {
    continue v.push(i)
  } nobreak {
    v
  }
  let vec = []
  v.eachi((i, _e) => vec.push(i))
  for i, v in vec {
    assert_eq(v, i)
  }
}

///|
test "get" {
  let bf = branching_factor_power(4)
  let v_content = random_array(bf)
  let v = from_iter(v_content.iter())
  inspect(v.length(), content=bf.to_string())
  inspect(v[0], content=v_content[0].to_string())
  inspect(v[bf - 1], content=v_content[bf - 1].to_string())
  inspect(v[bf / 2], content=v_content[bf / 2].to_string())
  let bf = branching_factor
  let v_content = random_array(bf)
  let v = from_iter(v_content.iter())
  inspect(v.length(), content=bf.to_string())
  inspect(v[0], content=v_content[0].to_string())
  inspect(v[bf - 1], content=v_content[bf - 1].to_string())
  inspect(v[bf / 2], content=v_content[bf / 2].to_string())
}

///|
test "concat-two-full-tree" {
  let bf = branching_factor_power(4)
  execute_array_test(gen_concat_seq_from_len_array([bf, bf]))
}

///|
test "concat-full-tree-and-a-leaf" {
  let bf = branching_factor_power(4)
  execute_array_test(gen_concat_seq_from_len_array([bf, 1]))
}

///|
test "concat-a-leaf-and-full-tree" {
  let bf = branching_factor_power(4)
  execute_array_test(gen_concat_seq_from_len_array([1, bf]))
}

///|
test "concat-two-leaf" {
  execute_array_test(gen_concat_seq_from_len_array([1, 1]))
}

///|
test "concat-multiple-full-tree" {
  let bf = branching_factor_power(4)
  execute_array_test(gen_concat_seq(3, _i => bf))
}

///|
test "concat-multiple-random-tree" {
  let bf = branching_factor_power(2)
  let rng = Random(@ref.Ref(0UL))
  execute_array_test(gen_concat_seq(2, _i => rng.int(limit=bf)))
}

///|
test "from_iter keeps trailing chunk in tail" {
  let values = from_iter((0).until(40))
  inspect(values.tree.is_empty_tree(), content="false")
  inspect(values.tail.length(), content="8")
  inspect(values.tail[0], content="32")
  inspect(values.tail[7], content="39")
}

///|
test "push flushes full tail into tree" {
  let values = from_iter((0).until(branching_factor))
  let pushed = values.push(branching_factor)
  inspect(pushed.tree.is_empty_tree(), content="false")
  inspect(pushed.tail.length(), content="1")
  inspect(pushed.tail[0], content=branching_factor.to_string())
}

///|
test "concat small right array stays in tail" {
  let left = from_iter((0).until(40))
  let right = from_iter((40).until(48))
  let combined = left.concat(right)
  inspect(combined.tail.length(), content="16")
  inspect(combined.tail[0], content="32")
  inspect(combined.tail[15], content="47")
}

///|
test "concat preserves right tail when right has tree prefix" {
  let left = from_iter((0).until(40))
  let right = from_iter((40).until(80))
  let combined = left.concat(right)
  assert_eq(combined.tail.length(), 8)
  assert_eq(combined.tail[0], 72)
  assert_eq(combined.tail[7], 79)
  assert_eq(combined.to_array(), Array::makei(80, i => i))
}

///|
test "concat with exact-multiple inputs keeps result tree-only" {
  let left = from_iter((0).until(64))
  let right = from_iter((64).until(128))
  let combined = left.concat(right)
  inspect(combined.tree.is_empty_tree(), content="false")
  assert_eq(combined.shift, num_bits)
  assert_eq(combined.tail.length(), 0)
  assert_eq(combined.to_array(), Array::makei(128, i => i))
}

///|
test "pop singleton tail promotes previous leaf into tail" {
  let values = from_iter((0).until(33))
  let popped = values.pop().unwrap()
  inspect(popped.tree.is_empty_tree(), content="true")
  assert_eq(popped.shift, 0)
  assert_eq(popped.tail.length(), branching_factor)
  assert_eq(popped.tail[0], 0)
  assert_eq(popped.tail[branching_factor - 1], branching_factor - 1)
  assert_eq(popped.to_array(), Array::makei(branching_factor, i => i))
}

///|
test "pop tree-only suffix promotes partial leaf into tail" {
  let values = from_iter((0).until(80)).slice(0, 50)
  let popped = values.pop().unwrap()
  inspect(popped.tree.is_empty_tree(), content="false")
  assert_eq(popped.shift, 0)
  assert_eq(popped.tail.length(), 17)
  assert_eq(popped.tail[0], 32)
  assert_eq(popped.tail[16], 48)
  assert_eq(popped.to_array(), Array::makei(49, i => i))
}

///|
test "pop shrinks top after removing last branch" {
  let size = branching_factor * branching_factor + branching_factor + 1
  let values = from_iter((0).until(size))
  let popped = values.pop().unwrap()
  assert_eq(popped.length(), size - 1)
  assert_eq(popped.shift, num_bits)
  assert_eq(popped.tail.length(), branching_factor)
  assert_eq(popped.tail[0], branching_factor * branching_factor)
  assert_eq(popped.tail[branching_factor - 1], size - 2)
  assert_eq(popped.to_array(), Array::makei(size - 1, i => i))
}

///|
test "slice within tail stays tail-only" {
  let values = from_iter((0).until(40))
  let sliced = values.slice(34, 40)
  inspect(sliced.tree.is_empty_tree(), content="true")
  assert_eq(sliced.tail.length(), 6)
  assert_eq(sliced.tail[0], 34)
  assert_eq(sliced.tail[5], 39)
}

///|
test "slice across tree and tail preserves right tail chunk" {
  let values = from_iter((0).until(40))
  let sliced = values.slice(20, 36)
  inspect(sliced.tree.is_empty_tree(), content="false")
  assert_eq(sliced.tail.length(), 4)
  assert_eq(sliced.tail[0], 32)
  assert_eq(sliced.tail[3], 35)
  assert_eq(sliced.to_array(), Array::makei(16, i => i + 20))
}

///|
/// Generate a sequence of concatenation operations as a test case,
/// 
/// Inputs:
/// - `n`: the number of operations to be generated
/// - `len_gen`: a function that generates the length of the array to be concatenated
fn gen_concat_seq(n : Int, len_gen : (Int) -> Int) -> Array[Op] {
  let ret = []
  for i in 0..<n {
    ret.push(Op::Concat(random_array(len_gen(i))))
  }
  ret
}

///|
/// Generate a sequence of concatenation operations as a test case,
/// similar to `gen_concat_seq`, but this time, the length of the array
/// to be concatenated is given as an array.
fn gen_concat_seq_from_len_array(len : Array[Int]) -> Array[Op] {
  let ret = []
  for l in len {
    ret.push(Op::Concat(random_array(l)))
  }
  ret
}
