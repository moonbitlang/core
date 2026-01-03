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
test "panic unsafe_pop_front" {
  @deque.from_array(([] : Array[Int])).unsafe_pop_front()
}

///|
test "panic unsafe_pop_back" {
  @deque.from_array(([] : Array[Int])).unsafe_pop_back()
}

///|
test "panic get" {
  @deque.from_array([1, 2, 3])[-1] |> ignore
}

///|
test "panic Deque::set" {
  @deque.from_array([1, 2, 3])[-1] = 1
}

///|
test "panic insert out of bounds" {
  @deque.from_array([1, 2, 3]).insert(4, 9)
}

///|
test "panic remove out of bounds" {
  @deque.from_array([1, 2, 3]).remove(3) |> ignore
}
