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

test "new" {
  let queue : PriorityQueue[Int] = new()
  @test.eq(queue.len, 0)!
}

test "from_array" {
  let pq = of([1, 2, 3, 4, 5])
  @test.eq(pq.peek(), Some(5))!
}

test "copy" {
  let v = of([1, 2, 3, 4])
  let ve = v.copy()
  inspect(v.peek().to_string(), content="Some(4)")!
  inspect(ve.peek().to_string(), content="Some(4)")!
  v.pop() |> ignore
  inspect(v.peek().to_string(), content="Some(3)")!
  inspect(ve.peek().to_string(), content="Some(4)")!
}

test "to_array" {
  let v = of([1, 2, 3, 4])
  inspect(v.to_array().to_string(), content="[4, 3, 2, 1]")!
  inspect(v.to_array().to_string(), content="[4, 3, 2, 1]")!
}

test "iter" {
  let buf = Buffer::new(size_hint=20)
  let v = of([1, 2, 3])
  v.iter().each(fn(e) { buf.write_string("[\(e)]") })
  inspect(buf, content="[3][2][1]")!
  buf.reset()
  v.iter().take(2).each(fn(e) { buf.write_string("[\(e)]") })
  inspect(buf, content="[3][2]")!
}

test "length" {
  let pq : PriorityQueue[Int] = PriorityQueue::new()
  @test.eq(pq.length(), 0)!
  pq.push(1)
  @test.eq(pq.length(), 1)!
  pq.push(2)
  @test.eq(pq.length(), 2)!
  pq.pop_exn()
  @test.eq(pq.length(), 1)!
}

test "pop_exn" {
  let pq = of([5, 5, 4, 3, 2, 1])
  @test.eq(pq.peek(), Some(5))!
  pq.pop_exn()
  @test.eq(pq.peek(), Some(5))!
  pq.pop_exn()
  @test.eq(pq.peek(), Some(4))!
}

test "pop" {
  let pq = of([1, 2, 3, 4, 5, 5])
  @test.eq(pq.pop(), Some(5))!
  @test.eq(pq.pop(), Some(5))!
  @test.eq(pq.pop(), Some(4))!
}

test "push" {
  let pq = of([5, 4, 3, 2, 1])
  pq.push(-1)
  pq.push(6)
  @test.eq(pq.length(), 7)!
  @test.eq(pq.peek(), Some(6))!
}

test "peek" {
  let pq = of([1, 2, 3, 4, 5])
  @test.eq(pq.peek(), Some(5))!
  pq.clear()
  @test.eq(pq.peek(), None)!
}

test "clear" {
  let pq = of([5, 4, 3, 2, 1])
  pq.clear()
  @test.eq(pq.length(), 0)!
}

test "is_empty" {
  let pq = of([5, 4, 3, 2, 1])
  @test.eq(pq.is_empty(), false)!
  pq.clear()
  @test.eq(pq.is_empty(), true)!
}
