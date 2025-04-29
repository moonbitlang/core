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
test "mix" {
  let mut v = new()
  inspect!(v.tree.is_empty_tree(), content="true")
  for i in 0..<100 {
    v = v.push(i)
  }
  inspect!(
    v,
    content="@immut/array.of([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99])",
  )
  let mut v2 = v
  for i in 0..<100 {
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
  let mut v = new()
  for i in 0..<large_const {
    v = v.push(i)
  }
  let vec = []
  v.eachi(fn(i, _e) { vec.push(i) })
  for i in 0..<large_const {
    assert_eq!(vec[i], i)
  }
}

///|
test "op_get" {
  let bf = branching_factor_power(4)
  let v_content = random_array(bf)
  let v = from_iter(v_content.iter())
  inspect!(v.length(), content=bf.to_string())
  inspect!(v[0], content=v_content[0].to_string())
  inspect!(v[bf - 1], content=v_content[bf - 1].to_string())
  inspect!(v[bf / 2], content=v_content[bf / 2].to_string())
  let bf = branching_factor
  let v_content = random_array(bf)
  let v = from_iter(v_content.iter())
  inspect!(v.length(), content=bf.to_string())
  inspect!(v[0], content=v_content[0].to_string())
  inspect!(v[bf - 1], content=v_content[bf - 1].to_string())
  inspect!(v[bf / 2], content=v_content[bf / 2].to_string())
}

///|
test "concat-two-full-tree" {
  let bf = branching_factor_power(4)
  execute_array_test!(gen_concat_seq_from_len_array([bf, bf]))
}

///|
test "concat-full-tree-and-a-leaf" {
  let bf = branching_factor_power(4)
  execute_array_test!(gen_concat_seq_from_len_array([bf, 1]))
}

///|
test "concat-a-leaf-and-full-tree" {
  let bf = branching_factor_power(4)
  execute_array_test!(gen_concat_seq_from_len_array([1, bf]))
}

///|
test "concat-two-leaf" {
  execute_array_test!(gen_concat_seq_from_len_array([1, 1]))
}

///|
test "concat-multiple-full-tree" {
  let bf = branching_factor_power(4)
  execute_array_test!(gen_concat_seq(3, fn(_i) { bf }))
}

///|
test "concat-multiple-random-tree" {
  let bf = branching_factor_power(2)
  let rng = Random({ val: 0UL })
  execute_array_test!(gen_concat_seq(2, fn(_i) { rng.int(limit=bf) }))
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
  for i in 0..<len.length() {
    ret.push(Op::Concat(random_array(len[i])))
  }
  ret
}
