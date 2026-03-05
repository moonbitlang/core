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
fn run_diag_range(
  old : Array[Int],
  new : Array[Int],
  lhs_offset : Int,
  lhs_limit : Int,
  rhs_offset : Int,
  rhs_limit : Int,
  too_expensive : Int,
  find_minimal : Bool,
) -> Partition {
  let forward_search_diagonal = FixedArray::make(
    old.length() + new.length() + 3,
    0,
  )
  let backward_search_diagonal = FixedArray::make(
    old.length() + new.length() + 3,
    0,
  )
  let diagonal_shift = new.length() + 1
  diag(
    forward_search_diagonal~,
    backward_search_diagonal~,
    diagonal_shift~,
    lhs_get=fn(i) { old[i] },
    rhs_get=fn(i) { new[i] },
    lhs_offset~,
    lhs_limit~,
    rhs_offset~,
    rhs_limit~,
    too_expensive~,
    find_minimal~,
  )
}

///|
fn run_diag(
  old : Array[Int],
  new : Array[Int],
  too_expensive : Int,
  find_minimal : Bool,
) -> Partition {
  run_diag_range(
    old,
    new,
    0,
    old.length(),
    0,
    new.length(),
    too_expensive,
    find_minimal,
  )
}

///|
fn patterned_array(length : Int, shift : Int, modulo : Int) -> Array[Int] {
  let result = Array::make(length, 0)
  for i = 0; i < length; i = i + 1 {
    result[i] = (i + shift) % modulo
  }
  result
}

///|
test "diag reaches lower diagonal boundary when old is longer" {
  let partition = run_diag([1, 2, 3, 4, 5], [10], 1024, true)
  assert_true(partition.lo_minimal)
  assert_true(partition.hi_minimal)
  assert_true(partition.lhs_midpoint >= 0 && partition.lhs_midpoint <= 5)
  assert_true(partition.rhs_midpoint >= 0 && partition.rhs_midpoint <= 1)
}

///|
test "diag reaches upper diagonal boundary when new is longer" {
  let partition = run_diag([1], [10, 11, 12, 13, 14], 1024, true)
  assert_true(partition.lo_minimal)
  assert_true(partition.hi_minimal)
  assert_true(partition.lhs_midpoint >= 0 && partition.lhs_midpoint <= 1)
  assert_true(partition.rhs_midpoint >= 0 && partition.rhs_midpoint <= 5)
}

///|
test "diag odd parity can return from forward search" {
  let partition = run_diag([1, 2], [9], 1024, true)
  assert_true(partition.lo_minimal)
  assert_true(partition.hi_minimal)
}

///|
test "diag heuristic path can choose either side" {
  let saw_forward = @ref.Ref::new(false)
  let saw_backward = @ref.Ref::new(false)
  for n = 3; n <= 8; n = n + 1 {
    for m = 3; m <= 8; m = m + 1 {
      for old_shift = 0; old_shift < 5; old_shift = old_shift + 1 {
        for new_shift = 0; new_shift < 5; new_shift = new_shift + 1 {
          let old = patterned_array(n, old_shift, 5)
          let new = patterned_array(m, new_shift, 5)
          for xoff = 0; xoff <= 1; xoff = xoff + 1 {
            for yoff = 0; yoff <= 1; yoff = yoff + 1 {
              if xoff < n && yoff < m {
                let partition = run_diag_range(
                  old, new, xoff, n, yoff, m, 0, false,
                )
                if partition.lo_minimal && !partition.hi_minimal {
                  saw_forward.val = true
                }
                if !partition.lo_minimal && partition.hi_minimal {
                  saw_backward.val = true
                }
              }
            }
          }
        }
      }
    }
  }
  assert_true(saw_forward.val)
  assert_true(saw_backward.val)
}
