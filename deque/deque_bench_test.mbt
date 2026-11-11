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
let deque_bench_n = 50000

///|
/// `to_array` copies every element out in index order. The Int and Ref
/// variants are both kept because the element type decides whether the
/// per-element store carries reference-counting traffic.
test "bench Deque::to_array Int n=50000" (it : @bench.T) {
  let d = @deque.from_array(Array::makei(deque_bench_n, i => i))
  it.bench(fn() { it.keep(d.to_array()) })
}

///|
test "bench Deque::to_array Ref n=50000" (it : @bench.T) {
  let d = @deque.from_array(Array::makei(deque_bench_n, i => "value\{i}"))
  it.bench(fn() { it.keep(d.to_array()) })
}

///|
test "bench Deque steady-state pop_front/push_back x100000 len=1000" (
  it : @bench.T,
) {
  // `Deque(xs)` sizes the buffer to exactly 1000 slots, not a power of two.
  let dq = @deque.Deque(Array::makei(1000, i => i))
  it.bench(fn() {
    let mut acc = 0
    for i in 0..<100000 {
      guard dq.pop_front() is Some(x) else { break }
      acc += x
      dq.push_back(x + i)
    }
    it.keep(acc)
  })
}

///|
test "bench Deque steady-state push_front/pop_back x100000 len=1000" (
  it : @bench.T,
) {
  let dq = @deque.Deque(Array::makei(1000, i => i))
  it.bench(fn() {
    let mut acc = 0
    for i in 0..<100000 {
      guard dq.pop_back() is Some(x) else { break }
      acc += x
      dq.push_front(x + i)
    }
    it.keep(acc)
  })
}

///|
test "bench Deque::get x100000 len=1000" (it : @bench.T) {
  let dq = @deque.Deque(Array::makei(1000, i => i))
  dq.push_front(-1) // make the buffer wrap
  ignore(dq.pop_back())
  it.bench(fn() {
    let mut acc = 0
    for i in 0..<100000 {
      if dq.get((i * 7 + acc) % 1000) is Some(x) {
        acc = (acc + x) & 0xffff
      }
    }
    it.keep(acc)
  })
}

///|
/// A deque of `n` Ints whose elements wrap around the end of its buffer, so
/// the traversals below take both sides of `wrap_index`.
fn wrapped_bench_deque(n : Int32) -> @deque.Deque[Int32] {
  let dq = @deque.Deque(Array::makei(n, i => i))
  for _ in 0..<(n / 2) {
    guard dq.pop_front() is Some(x) else { break }
    dq.push_back(x)
  }
  dq
}

///|
test "bench Deque iter wrapped n=50000" (it : @bench.T) {
  let dq = wrapped_bench_deque(deque_bench_n)
  it.bench(fn() {
    let mut acc = 0
    for x in dq {
      acc += x
    }
    it.keep(acc)
  })
}

///|
test "bench Deque rev_iter2 wrapped n=50000" (it : @bench.T) {
  let dq = wrapped_bench_deque(deque_bench_n)
  it.bench(fn() {
    let mut acc = 0
    for i, x in dq.rev_iter2() {
      acc += i ^ x
    }
    it.keep(acc)
  })
}

///|
test "bench Deque::map wrapped n=50000" (it : @bench.T) {
  let dq = wrapped_bench_deque(deque_bench_n)
  it.bench(fn() { it.keep(dq.map(x => x + 1)) })
}

///|
test "bench Deque::search miss wrapped n=50000" (it : @bench.T) {
  let dq = wrapped_bench_deque(deque_bench_n)
  it.bench(fn() { it.keep(dq.search(-1)) })
}

///|
test "bench Deque::extract_if none wrapped n=50000" (it : @bench.T) {
  let dq = wrapped_bench_deque(deque_bench_n)
  it.bench(fn() { it.keep(dq.extract_if(x => x < 0)) })
}

///|
test "bench Deque::shuffle_in_place wrapped n=50000" (it : @bench.T) {
  let dq = wrapped_bench_deque(deque_bench_n)
  it.bench(fn() {
    dq.shuffle_in_place(rand=n => n / 2)
    it.keep(dq)
  })
}
