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
test "tree shift is derived from leaf count without element-capacity overflow" {
  @debug.debug_inspect(
    [
      shift_of_leaf_count(1),
      shift_of_leaf_count(32),
      shift_of_leaf_count(33),
      shift_of_leaf_count(33_554_432),
      shift_of_leaf_count(33_554_433),
      shift_of_leaf_count(67_108_863),
    ],
    content="[0, 5, 10, 25, 30, 30]",
  )
}

///|
test "tree element count is derived from leaf count" {
  @debug.debug_inspect(
    [
      tree_len_of_leaf_count(0),
      tree_len_of_leaf_count(1),
      tree_len_of_leaf_count(33_554_432),
      tree_len_of_leaf_count(67_108_863),
    ],
    content="[0, 32, 1073741824, 2147483616]",
  )
}

///|
test "push accepts the maximum Int length" {
  let mut v = singleton(false)
  for _ in 0..<30 {
    v = v.concat(v).push(false)
  }
  inspect(v.length(), content="2147483647")
  inspect(v.is_empty(), content="false")
  inspect(
    v[0],
    content=(
      #|false
    ),
  )
  inspect(
    v[2_147_483_646],
    content=(
      #|false
    ),
  )
}

///|
test "concat accepts the maximum Int length" {
  let mut left = singleton(false)
  for _ in 0..<30 {
    left = left.concat(left)
  }
  let mut right = singleton(false)
  for _ in 0..<29 {
    right = right.concat(right).push(false)
  }
  let v = left.concat(right)
  inspect(v.length(), content="2147483647")
  inspect(
    v[0],
    content=(
      #|false
    ),
  )
  inspect(
    v[2_147_483_646],
    content=(
      #|false
    ),
  )
}
