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

test "new_with_capacity" {
  let d : Deque[Int] = new(capacity=0)
  @test.eq(d.buf.length(), 0)!
}

test "new_with_capacity_non_zero" {
  let d : Deque[Int] = new(capacity=10)
  @test.eq(d.buf.length(), 10)!
}

test "realloc" {
  let dv = of([1, 2, 3, 4, 5])
  @test.eq(dv.pop_front(), Some(1))!
  @test.eq(dv.pop_front(), Some(2))!
  @test.eq(dv.pop_front(), Some(3))!
  dv.push_back(6)
  dv.push_back(7)
  dv.push_back(8)
  dv.push_back(9)
  dv.push_back(10)
  let result = Array::make(7, 0)
  let mut i = 0
  dv.each(
    fn(x) {
      result[i] = x
      i += 1
    },
  )
  @test.eq(result, [4, 5, 6, 7, 8, 9, 10])!
}

test "push_realloc" {
  let dv : Deque[Int] = new()
  dv.push_front(1)
  @test.eq(dv.pop_front(), Some(1))!
  @test.is_true(dv.capacity() > 0)!
  let dv : Deque[Int] = new()
  dv.push_back(1)
  @test.eq(dv.pop_back(), Some(1))!
  @test.is_true(dv.capacity() > 0)!
}

test "reserve_and_push" {
  // capacity > 0, len = 0
  let a : Deque[Int?] = new(capacity=2)
  a.push_back(Some(1))
  inspect!(a.front(), content="Some(Some(1))")
  inspect!(a.back(), content="Some(Some(1))")
  // capacity = 0, len = 0
  let b : Deque[Int?] = new(capacity=0)
  b.push_back(Some(1))
  inspect!(b.front(), content="Some(Some(1))")
  inspect!(b.back(), content="Some(Some(1))")
  // capacity > 0, len = 0
  let c : Deque[Int?] = new(capacity=2)
  c.push_front(Some(1))
  inspect!(c.front(), content="Some(Some(1))")
  inspect!(c.back(), content="Some(Some(1))")
  // capacity = 0, len = 0
  let d : Deque[Int?] = new(capacity=0)
  d.push_front(Some(1))
  inspect!(d.front(), content="Some(Some(1))")
  inspect!(d.back(), content="Some(Some(1))")
}
