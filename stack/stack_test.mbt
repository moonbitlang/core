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
test "new" {
  let s : @stack.T[Int] = @stack.new()
  assert_true(s.is_empty())
}

///|
test "push_pop" {
  let s : @stack.T[Int] = @stack.new()
  s.push(1)
  s.push(2)
  assert_eq(s.length(), 2)
  assert_eq(s.unsafe_pop(), 2)
  assert_eq(s.pop(), Some(1))
  assert_true(s.is_empty())
}

///|
test "peek" {
  let s = @stack.of([1,2,3])
  assert_eq(s.peek(), Some(3))
  assert_eq(s.unsafe_peek(), 3)
  s.clear()
  assert_eq(s.peek(), None)
}

///|
test "iter" {
  let s = @stack.of([1,2,3])
  inspect(s.iter().fold(fn(a,b){a+b}, init=0), content="6")
}
