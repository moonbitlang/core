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

test "array_capacity" {
  let arr : Array[Int] = Array::new(capacity=10)
  assert_true!(arr.capacity() >= 10)
}

test "panic array_pop_exn_empty" {
  let arr : Array[Int] = Array::new()
  arr.unsafe_pop() |> ignore // This should panic
}

test "array_retain" {
  let arr = [1, 2, 3, 4, 5]
  assert_eq!(arr.capacity(), 5)
  arr.retain(fn(x) { x % 2 == 0 })
  assert_eq!(arr.length(), 2)
  assert_eq!(arr.capacity(), 5)
  assert_eq!(arr[0], 2)
  assert_eq!(arr[1], 4)
}

test "shrink_to_fit" {
  let v = Array::new(capacity=10)
  v.push(1)
  v.push(2)
  v.push(3)
  inspect!(v.capacity(), content="10")
  v.shrink_to_fit()
  inspect!(v.capacity(), content="3")
  v.shrink_to_fit()
  inspect!(v.capacity(), content="3")
}
