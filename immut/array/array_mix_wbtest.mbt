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

/// The naming of test follows the format
///   random seed - number of operations - maximum level of the tree
/// If the given random seed is shorter than 32, it will be repeated
/// up to 32 chars.

test "DEADBEEF-10-4" {
  run_test!("DEADBEEF", 10, 4)
}

test "LIVEBEEF-50-3" {
  run_test!("LIVEBEEF", 50, 3)
}

test "HAPPYDOG-1000-2" {
  run_test!("HAPPYDOG", 200, 2)
}

///|
fn run_test(seed : String, rep : Int, max_lvl : Int) -> Unit! {
  let seed = repeat_up_to_32(seed)
  let rng = @random.new(seed~)
  let rs = random_test_gen(rng, rep, max_lvl)
  execute_array_test!(rs)
}

///|
/// Generate a random test sequence for the array,
/// following the format described in the `execute_array_test` function.
/// 
/// Inputs:
/// - `rng`: a random number generator
/// - `times`: the number of operations to be generated
/// - `max_lvl`: the maximum level of the tree
fn random_test_gen(
  rng : @random.Rand,
  times : Int,
  max_lvl : Int
) -> Array[Int] {
  // Hyperparameters
  let op_count = 3
  let max_len = branching_factor_power(max_lvl)
  let max_val = 2025

  // Start constructing the array
  let ret = []
  let mut cur_len = 0
  for i = 0; i < times; i = i + 1 {
    let op = rng.int(limit=op_count)
    match op {
      0 => {
        // push_end
        ret.push(op)
        let val = rng.int(limit=max_val)
        ret.push(val)
        cur_len += 1
      }
      1 => {
        // concat
        ret.push(op)
        let len = rng.int(limit=max_len)
        ret.push(len)
        for j = 0; j < len; j = j + 1 {
          let val = rng.int(limit=max_val)
          ret.push(val)
        }
        cur_len += len
      }
      2 => {
        // set
        if cur_len == 0 {
          continue
        }
        ret.push(op)
        let idx = rng.int(limit=cur_len)
        let val = rng.int(limit=max_val)
        ret.push(idx)
        ret.push(val)
      }
      _ => abort("Invalid op")
    }
  }
  ret
}

///|
/// This function runs a series of operations on an array and checks
/// if the result matches the expected array.
/// 
/// Currently, the operations are:
/// 0. push_end
/// 1. concat
/// 2. set
/// 
/// The `rs` array is a sequence of operations to be executed.
/// For each operation, the following value sequence are expected:
/// - push_end: 0 value
/// - concat: 1 length v0 v1 ... v_{length - 1}
/// - set: 2 index value
fn execute_array_test(rs : Array[Int]) -> Unit! {
  let mut t = T::new()
  let a = []
  let len = rs.length()
  let mut i = 0
  while i < len {
    let op = rs[i]
    i += 1
    match op {
      0 => {
        // push_end
        let rsi = rs[i]
        a.push(rsi)
        t = t.push(rsi)
        i += 1
        check_array_eq!(a, t)
      }
      1 => {
        // concat
        let len = rs[i]
        i += 1
        rs.blit_to(a, len~, src_offset=i, dst_offset=a.length())
        let t1 = T::from_iter(rs[i:i + len].iter())
        t = t.concat(t1)
        i += len
        check_array_eq!(a, t)
      }
      2 => {
        // set
        let idx = rs[i]
        let v = rs[i + 1]
        i += 2
        a[idx] = v
        t = t.set(idx, v)
        check_array_eq!(a, t)
      }
      _ => abort("Invalid op")
    }
  }
}

///|
/// Compute the power of the branching factor.
fn branching_factor_power(a : Int) -> Int {
  let mut ret = 1
  for i = 0; i < a; i = i + 1 {
    ret *= branching_factor
  }
  ret
}

///|
/// Repeat the given string up to 32 characters.
/// Used to generate a random seed for the test.
fn repeat_up_to_32(s : String) -> Bytes {
  let a_len = 32
  let s_len = s.length()
  let a = FixedArray::make(a_len, b'0')
  let mut j = 0
  for i = 0; i < a_len; i = i + 1 {
    let l = a.set_utf8_char(i, s[j])
    guard l == 1
    j = (j + 1) % s_len
  }
  Bytes::from_fixedarray(a)
}

///|
/// Use this function to check if the array and the @immut/array are equal.
/// If we `inspect` the array, it will raise an error if the arrays are too long.
/// I guess that's because it exceeds the heap limit of the VM.
fn check_array_eq(a : Array[Int], t : T[Int]) -> Unit! {
  assert_eq!(a.length(), t.size)
  let mut i = 0
  for tt in t.iter() {
    assert_eq!(tt, a[i])
    i += 1
  }
}
