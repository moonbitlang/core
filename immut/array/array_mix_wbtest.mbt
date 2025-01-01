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

test "DEADBEEF-2" {
  let rng = @random.new(seed=b"DEADBEEFDEADBEEFDEADBEEFDEADBEEF")
  let rs = random_test_gen(2, rng)
  println(rs)
  random_test!(rs)
}

///|
fn random_test_gen(times : Int, rng : @random.Rand) -> Array[Int] {
  // Hyperparameters
  let op_count = 3
  let max_len = branching_factor * branching_factor
  // *
  // branching_factor *
  // branching_factor
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
fn random_test(rs : Array[Int]) -> Unit! {
  fn check(a : Array[Int], t : T[Int]) -> Unit! {
    inspect!(t, content="@immut/array.of(\{a})")
  }

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
        a.push(rs[i])
        t = t.push(rs[i])
        i += 1
        check!(a, t)
      }
      1 => {
        // concat
        let len = rs[i]
        i += 1
        rs.blit_to(a, len~, src_offset=i, dst_offset=a.length())
        t = t.concat(T::from_iter(rs[i:i + len].iter()))
        i += len
        check!(a, t)
      }
      2 => {
        // set
        let idx = rs[i]
        let v = rs[i + 1]
        i += 2
        rs[idx] = v
        t = t.set(idx, v)
        check!(a, t)
      }
      _ => abort("Invalid op")
    }
  }
}
