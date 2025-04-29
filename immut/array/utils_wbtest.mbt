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
enum Op {
  PushEnd(Int)
  Concat(Array[Int])
  Set(Int, Int)
}

///|
/// Generate a random test sequence for the array,
/// following the format described in the `execute_array_test` function.
/// 
/// Inputs:
/// - `rng`: a random number generator
/// - `times`: the number of operations to be generated
/// - `max_lvl`: the maximum level of the tree
fn random_test_gen(rng : Random, times : Int, max_lvl : Int) -> Array[Op] {
  // Hyperparameters
  let op_count = 3
  let max_len = branching_factor_power(max_lvl)
  let max_val = 2025

  // Start constructing the array
  let ret = []
  let mut cur_len = 0
  for i in 0..<times {
    let op = rng.int(limit=op_count)
    match op {
      0 => {
        // push_end
        ret.push(Op::PushEnd(rng.int(limit=max_val)))
        cur_len += 1
      }
      1 => {
        // concat
        let len = rng.int(limit=max_len)
        let a = Array::make(len, rng.int(limit=max_val))
        cur_len += len
        ret.push(Op::Concat(a))
      }
      2 => {
        // set
        if cur_len == 0 {
          continue
        }
        let idx = rng.int(limit=cur_len)
        let val = rng.int(limit=max_val)
        ret.push(Op::Set(idx, val))
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
fn execute_array_test(rs : Array[Op]) -> Unit! {
  let mut t = new()
  let a : Array[Int] = []
  for op in rs {
    match op {
      PushEnd(v) => {
        // push_end
        a.push(v)
        t = t.push(v)
        check_array_eq!(a, t)
      }
      Concat(v) => {
        // concat
        let len = v.length()
        for i in 0..<len {
          a.push(v[i])
        }
        t = t.concat(from_array(v))
        check_array_eq!(a, t)
      }
      Set(idx, v) => {
        // set
        a[idx] = v
        t = t.set(idx, v)
        check_array_eq!(a, t)
      }
    }
  }
}

///|
/// Compute the power of the branching factor.
fn branching_factor_power(a : Int) -> Int {
  let mut ret = 1
  for i in 0..<a {
    ret *= branching_factor
  }
  ret
}

///|
/// Use this function to check if the array and the @immut/array are equal.
/// If we `inspect` the array, it will raise an error if the arrays are too long.
/// I guess that's because it exceeds the heap limit of the VM.
fn check_array_eq(a : Array[Int], t : T[Int]) -> Unit! {
  assert_eq!(a.length(), t.size)
  let len = t.size
  for i in 0..<len {
    assert_eq!(t[i], a[i])
  }
}

///|
/// Generate a random array of length `n`.
fn random_array(n : Int) -> Array[Int] {
  let rng = Random({ val: 0 })
  Array::makei(n, fn(i) { rng.int(limit=i) })
}

///|
type Random Ref[UInt64]

///|
fn int(self : Random, limit~ : Int) -> Int {
  let limit = if limit == 0 { 1L << 32 } else { limit.to_int64() }
  let a = 1UL << 48
  let c = 11UL
  let m = 25214903917UL
  self._.val = (a * self._.val + c) % m
  (self._.val.reinterpret_as_int64() % limit).to_int()
}
