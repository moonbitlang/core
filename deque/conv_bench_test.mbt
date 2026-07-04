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
let conv_bench_size = 10000

///|
fn make_contiguous_deque(len : Int) -> @deque.Deque[Int] {
  let dq = @deque.Deque([], capacity=len)
  for i in 0..<len {
    dq.push_back(i)
  }
  dq
}

///|
/// A deque holding the same elements as `make_contiguous_deque`, but whose
/// elements wrap around the internal ring buffer boundary.
fn make_wrapped_deque(len : Int) -> @deque.Deque[Int] {
  let dq = @deque.Deque([], capacity=len)
  for _ in 0..<(len / 2) {
    dq.push_back(-1)
  }
  for _ in 0..<(len / 2) {
    dq.pop_front() |> ignore
  }
  for i in 0..<len {
    dq.push_back(i)
  }
  dq
}

///|
test "bench Deque::to_array contiguous n=10000" (it : @bench.T) {
  let dq = make_contiguous_deque(conv_bench_size)
  it.bench(fn() { it.keep(dq.to_array()) })
}

///|
test "bench Deque::to_array wrapped n=10000" (it : @bench.T) {
  let dq = make_wrapped_deque(conv_bench_size)
  it.bench(fn() { it.keep(dq.to_array()) })
}

///|
test "bench Deque::op_equal contiguous n=10000" (it : @bench.T) {
  let dq1 = make_contiguous_deque(conv_bench_size)
  let dq2 = make_contiguous_deque(conv_bench_size)
  it.bench(fn() { it.keep(dq1 == dq2) })
}

///|
test "bench Deque::op_equal wrapped n=10000" (it : @bench.T) {
  let dq1 = make_wrapped_deque(conv_bench_size)
  let dq2 = make_contiguous_deque(conv_bench_size)
  it.bench(fn() { it.keep(dq1 == dq2) })
}

///|
test "bench Deque::compare wrapped n=10000" (it : @bench.T) {
  let dq1 = make_wrapped_deque(conv_bench_size)
  let dq2 = make_contiguous_deque(conv_bench_size)
  it.bench(fn() { it.keep(dq1.compare(dq2)) })
}
