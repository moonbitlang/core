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
let view_bench_size = 100_000

///|
fn make_view_bench_array() -> Array[Int] {
  Array::makei(view_bench_size + 2, i => i % 1024)
}

///|
fn make_view_bench_fixedarray() -> FixedArray[Int] {
  FixedArray::makei(view_bench_size + 2, i => i % 1024)
}

///|
fn make_view_bench_bytes() -> Bytes {
  Bytes::make(view_bench_size + 2, b'\x01')
}

///|
test "bench ArrayView::at Int n=100000" (it : @bench.T) {
  let data = make_view_bench_fixedarray()
  let view = data[1:view_bench_size + 1]
  it.bench(fn() {
    let mut sum = 0
    for i = 0; i < view_bench_size; i = i + 1 {
      sum = sum + view[i]
    }
    it.keep(sum)
  })
}

///|
test "bench ArrayView::get Int n=100000" (it : @bench.T) {
  let data = make_view_bench_fixedarray()
  let view = data[1:view_bench_size + 1]
  it.bench(fn() {
    let mut sum = 0
    for i = 0; i < view_bench_size; i = i + 1 {
      if view.get(i) is Some(x) {
        sum = sum + x
      }
    }
    it.keep(sum)
  })
}

///|
test "bench ArrayView::unsafe_get Int n=100000" (it : @bench.T) {
  let data = make_view_bench_fixedarray()
  let view = data[1:view_bench_size + 1]
  it.bench(fn() {
    let mut sum = 0
    for i = 0; i < view_bench_size; i = i + 1 {
      sum = sum + view.unsafe_get(i)
    }
    it.keep(sum)
  })
}

///|
test "bench ArrayView::rev_fold Int n=100000" (it : @bench.T) {
  let data = make_view_bench_fixedarray()
  let view = data[1:view_bench_size + 1]
  it.bench(fn() { it.keep(view.rev_fold(init=0, (sum, elem) => sum + elem)) })
}

///|
test "bench ArrayView::rev_foldi Int n=100000" (it : @bench.T) {
  let data = make_view_bench_fixedarray()
  let view = data[1:view_bench_size + 1]
  it.bench(fn() {
    it.keep(view.rev_foldi(init=0, (_index, sum, elem) => sum + elem))
  })
}

///|
test "bench ArrayView::equal Int n=100000" (it : @bench.T) {
  let data = make_view_bench_fixedarray()
  let left = data[1:view_bench_size + 1]
  let right = data[1:view_bench_size + 1]
  it.bench(fn() { it.keep(left == right) })
}

///|
test "bench ArrayView::compare Int n=100000" (it : @bench.T) {
  let data = make_view_bench_fixedarray()
  let left = data[1:view_bench_size + 1]
  let right = data[1:view_bench_size + 1]
  it.bench(fn() { it.keep(left.compare(right)) })
}

///|
test "bench MutArrayView::at Int n=100000" (it : @bench.T) {
  let data = make_view_bench_array()
  let view = data.mut_view(start=1, end=view_bench_size + 1)
  it.bench(fn() {
    let mut sum = 0
    for i = 0; i < view_bench_size; i = i + 1 {
      sum = sum + view[i]
    }
    it.keep(sum)
  })
}

///|
test "bench MutArrayView::unsafe_get Int n=100000" (it : @bench.T) {
  let data = make_view_bench_array()
  let view = data.mut_view(start=1, end=view_bench_size + 1)
  it.bench(fn() {
    let mut sum = 0
    for i = 0; i < view_bench_size; i = i + 1 {
      sum = sum + view.unsafe_get(i)
    }
    it.keep(sum)
  })
}

///|
test "bench MutArrayView::set Int n=100000" (it : @bench.T) {
  let data = make_view_bench_array()
  let view = data.mut_view(start=1, end=view_bench_size + 1)
  it.bench(fn() {
    for i = 0; i < view_bench_size; i = i + 1 {
      view[i] = i % 1024
    }
    it.keep(view[0] + view[view_bench_size - 1])
  })
}

///|
test "bench MutArrayView::unsafe_set Int n=100000" (it : @bench.T) {
  let data = make_view_bench_array()
  let view = data.mut_view(start=1, end=view_bench_size + 1)
  it.bench(fn() {
    for i = 0; i < view_bench_size; i = i + 1 {
      view.unsafe_set(i, i % 1024)
    }
    it.keep(view.unsafe_get(0) + view.unsafe_get(view_bench_size - 1))
  })
}

///|
test "bench BytesView::at n=100000" (it : @bench.T) {
  let data = make_view_bench_bytes()
  let view = data[1:view_bench_size + 1]
  it.bench(fn() {
    let mut value = b'\x00'
    for i = 0; i < view_bench_size; i = i + 1 {
      value = view[i]
    }
    it.keep(value)
  })
}

///|
test "bench BytesView::unsafe_get n=100000" (it : @bench.T) {
  let data = make_view_bench_bytes()
  let view = data[1:view_bench_size + 1]
  it.bench(fn() {
    let mut value = b'\x00'
    for i = 0; i < view_bench_size; i = i + 1 {
      value = view.unsafe_get(i)
    }
    it.keep(value)
  })
}
