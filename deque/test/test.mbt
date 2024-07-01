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

test "search" {
  let dv = @deque.of([3, 4, 5])
  @test.eq(dv.search(3), Some(0))!
  @test.eq(dv.search(4), Some(1))!
  @test.eq(dv.search(5), Some(2))!
  @test.eq(dv.search(6), None)!
}

test "contains" {
  let dv = @deque.of([3, 4, 5])
  @test.is_true(dv.contains(3))!
  @test.is_true(dv.contains(4))!
  @test.is_true(dv.contains(5))!
  @test.is_false(dv.contains(6))!
}

test "reserve_capacity" {
  let dv = @deque.of([1, 2, 3, 4, 5])
  dv.pop_front() |> ignore() // 2, 3, 4, 5
  dv.push_back(1) // 2, 3, 4, 5, 1
  dv.pop_front() |> ignore() // 3, 4, 5, 1
  dv.pop_front() |> ignore() // 4, 5, 1
  dv.reserve_capacity(10)
  @test.is_true(dv.capacity() == 10)!
  @test.eq(dv[0], 4)!
  @test.eq(dv[1], 5)!
  @test.eq(dv[2], 1)!
}

test "reserve_capacity_2" {
  let dv = @deque.of([1, 2, 3, 4, 5])
  dv.reserve_capacity(3)
  @test.is_true(dv.capacity() == 5)!
}

test "shrink_to_fit" {
  let dv = @deque.of([1, 2, 3, 4, 5])
  dv.pop_front() |> ignore()
  dv.push_back(1)
  dv.pop_front() |> ignore()
  dv.pop_front() |> ignore()
  @test.is_true(dv.capacity() == 5)!
  dv.shrink_to_fit()
  @test.is_true(dv.capacity() == 3)!
  @test.eq(dv[0], 4)!
  @test.eq(dv[1], 5)!
  @test.eq(dv[2], 1)!
}

test "shrink_to_fit_2" {
  let dv = @deque.of([1, 2, 3])
  @test.is_true(dv.capacity() == 3)!
  dv.shrink_to_fit()
  @test.is_true(dv.capacity() == 3)!
}

test "iter" {
  let dv = @deque.of([1, 2, 3, 4, 5])
  let iter = dv.iter()
  let buf = Buffer::new(size_hint=0)
  let mut i = 0
  iter.each(
    fn(x) {
      buf.write_string(x.to_string())
      buf.write_char('\n')
      i = i + 1
    },
  )
  @test.eq(i, dv.length())!
  buf.expect(
    content=
      #|1
      #|2
      #|3
      #|4
      #|5
      #|
    ,
  )!
  inspect(
    iter.take(4).filter(fn(x) { x % 2 == 0 }).fold(fn(a, x) { a + x }, 0),
    content="6",
  )!
}

test "reserve and push" {
  // capacity > 0, len = 0
  let a = @deque.new(capacity=2)
  a.push_back(Option::Some(1))
  inspect(a.front(), content="Some(Some(1))")!
  inspect(a.back(), content="Some(Some(1))")!
  // capacity = 0, len = 0
  let b = @deque.new(capacity=0)
  b.push_back(Option::Some(1))
  inspect(b.front(), content="Some(Some(1))")!
  inspect(b.back(), content="Some(Some(1))")!
  // capacity > 0, len = 0
  let c = @deque.new(capacity=2)
  c.push_front(Option::Some(1))
  inspect(c.front(), content="Some(Some(1))")!
  inspect(c.back(), content="Some(Some(1))")!
  // capacity = 0, len = 0
  let d = @deque.new(capacity=0)
  d.push_front(Option::Some(1))
  inspect(d.front(), content="Some(Some(1))")!
  inspect(d.back(), content="Some(Some(1))")!
}

test "mapi" {
  let dv = @deque.of([3, 4, 5])
  let dvp = dv.mapi(fn(i, x) { x + i })
  inspect(dvp[0], content="3")!
  inspect(dvp[1], content="5")!
  inspect(dvp[2], content="7")!
}

test "iter_rev" {
  let mut i = 6
  let mut failed = false
  @deque.of([1, 2, 3, 4, 5]).each_rev(
    fn(elem) {
      if elem != i - 1 {
        failed = true
      }
      i = i - 1
    },
  )
  @test.is_false(failed)!
}

test "iter_revi" {
  let mut i = 6
  let mut j = 0
  let mut failed = false
  @deque.of([1, 2, 3, 4, 5]).eachi_rev(
    fn(index, elem) {
      if index != j || elem != i - 1 {
        failed = true
      }
      i = i - 1
      j = j + 1
    },
  )
  @test.is_false(failed)!
}

test "iteri" {
  let mut i = 0
  let mut failed = false
  @deque.of([1, 2, 3, 4, 5]).eachi(
    fn(index, elem) {
      if index != i || elem != i + 1 {
        failed = true
      }
      i = i + 1
    },
  )
  @test.is_false(failed)!
}

test "iter" {
  let mut i = 0
  let mut failed = false
  @deque.of([1, 2, 3, 4, 5]).each(
    fn(elem) {
      if elem != i + 1 {
        failed = true
      }
      i = i + 1
    },
  )
  @test.is_false(failed)!
}

test "iter2" {
  let v = @deque.of([1, 2, 3, 4, 5])
  v.pop_front_exn()
  v.pop_back_exn()
  let mut sum = 0
  v.each(fn { x => sum += x })
  inspect(sum, content="9")!
}

test "op_get" {
  let dv = @deque.of([1, 2, 3, 4, 5])
  inspect([dv[0], dv[1], dv[2], dv[3], dv[4]], content="[1, 2, 3, 4, 5]")!
  dv.pop_front() |> ignore
  dv.push_back(1)
  inspect(dv[4], content="1")!
  dv.push_front(2)
  inspect(dv[0], content="2")!
}
