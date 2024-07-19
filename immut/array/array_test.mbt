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

test "panic set with out-of-bounds index" {
  let v = @array.of([1, 2, 3, 4, 5])
  let v1 = v.set(10, 10) // This should trigger the panic in set function
  inspect!(v1, content="ImmutableVec::[1, 2, 3, 4, 5]")
}

test "panic set with negative index" {
  let v = @array.of([1, 2, 3, 4, 5])
  let v1 = v.set(-1, 10) // This should trigger the panic in set function
  inspect!(v1, content="ImmutableVec::[1, 2, 3, 4, 5]")
}

test "panic set with empty array" {
  let v = @array.empty()
  let v1 = v.set(0, 10) // This should trigger the panic in set function
  inspect!(v1, content="ImmutableVec::[]")
}

test "set with valid index" {
  let v = @array.of([1, 2, 3, 4, 5])
  let v1 = v.set(2, 10) // This should not trigger the panic
  inspect!(v1, content="@immut/array.of([1, 2, 10, 4, 5])")
}

test "set with valid index at end" {
  let v = @array.of([1, 2, 3, 4, 5])
  let v1 = v.set(4, 10) // This should not trigger the panic
  inspect!(v1, content="@immut/array.of([1, 2, 3, 4, 10])")
}
