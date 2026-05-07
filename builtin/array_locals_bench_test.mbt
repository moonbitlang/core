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
let array_locals_bench_size = 100_000

///|
fn make_array_locals_bench_array() -> Array[Int] {
  Array::makei(array_locals_bench_size, i => i)
}

///|
fn make_array_locals_bench_fixedarray() -> FixedArray[Int] {
  FixedArray::makei(array_locals_bench_size, i => i)
}

///|
test "bench Array::retain_map n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_array()
  it.bench(fn() {
    data.retain_map(x => Some(x))
    it.keep(data.length())
  })
}

///|
test "bench Array::shuffle_in_place n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_array()
  fn rand(upper : Int) -> Int {
    upper - 1
  }
  it.bench(fn() {
    data.shuffle_in_place(rand~)
    it.keep(data[0])
  })
}

///|
test "bench Array::filter_map n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_array()
  it.bench(fn() {
    it.keep(data.filter_map(x => if x % 2 == 0 { Some(x + 1) } else { None }))
  })
}

///|
test "bench FixedArray::each n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  it.bench(fn() {
    let mut sum = 0
    data.each(x => sum = sum + x)
    it.keep(sum)
  })
}

///|
test "bench FixedArray::eachi n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  it.bench(fn() {
    let mut sum = 0
    data.eachi((i, x) => sum = sum + i + x)
    it.keep(sum)
  })
}

///|
test "bench FixedArray::rev_each n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  it.bench(fn() {
    let mut sum = 0
    data.rev_each(x => sum = sum + x)
    it.keep(sum)
  })
}

///|
test "bench FixedArray::rev_eachi n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  it.bench(fn() {
    let mut sum = 0
    data.rev_eachi((i, x) => sum = sum + i + x)
    it.keep(sum)
  })
}

///|
test "bench FixedArray::map n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  it.bench(fn() { it.keep(data.map(x => x + 1)) })
}

///|
test "bench FixedArray::mapi n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  it.bench(fn() { it.keep(data.mapi((i, x) => i + x)) })
}

///|
test "bench FixedArray::makei n=100000" (it : @bench.T) {
  it.bench(fn() { it.keep(FixedArray::makei(array_locals_bench_size, i => i)) })
}

///|
test "bench FixedArray::fold n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  it.bench(fn() { it.keep(data.fold(init=0, (sum, x) => sum + x)) })
}

///|
test "bench FixedArray::rev_fold n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  it.bench(fn() { it.keep(data.rev_fold(init=0, (sum, x) => sum + x)) })
}

///|
test "bench FixedArray::foldi n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  it.bench(fn() { it.keep(data.foldi(init=0, (i, sum, x) => sum + i + x)) })
}

///|
test "bench FixedArray::rev_foldi n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  it.bench(fn() { it.keep(data.rev_foldi(init=0, (i, sum, x) => sum + i + x)) })
}

///|
test "bench ArrayView::chunk_by n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() { it.keep(view.chunk_by((a, b) => a + 1 == b)) })
}

///|
test "bench ArrayView::each n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() {
    let mut sum = 0
    view.each(x => sum = sum + x)
    it.keep(sum)
  })
}

///|
test "bench ArrayView::eachi n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() {
    let mut sum = 0
    view.eachi((i, x) => sum = sum + i + x)
    it.keep(sum)
  })
}

///|
test "bench ArrayView::rev_each n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() {
    let mut sum = 0
    view.rev_each(x => sum = sum + x)
    it.keep(sum)
  })
}

///|
test "bench ArrayView::rev_eachi n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() {
    let mut sum = 0
    view.rev_eachi((i, x) => sum = sum + i + x)
    it.keep(sum)
  })
}

///|
test "bench ArrayView::all n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() { it.keep(view.all(x => x < array_locals_bench_size)) })
}

///|
test "bench ArrayView::any n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() { it.keep(view.any(x => x == array_locals_bench_size - 1)) })
}

///|
test "bench ArrayView::search_by n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() {
    it.keep(view.search_by(x => x == array_locals_bench_size - 1))
  })
}

///|
test "bench ArrayView::fold n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() { it.keep(view.fold(init=0, (sum, x) => sum + x)) })
}

///|
test "bench ArrayView::rev_fold n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() { it.keep(view.rev_fold(init=0, (sum, x) => sum + x)) })
}

///|
test "bench ArrayView::foldi n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() { it.keep(view.foldi(init=0, (i, sum, x) => sum + i + x)) })
}

///|
test "bench ArrayView::rev_foldi n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() { it.keep(view.rev_foldi(init=0, (i, sum, x) => sum + i + x)) })
}

///|
test "bench ArrayView::map n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() { it.keep(view.map(x => x + 1)) })
}

///|
test "bench ArrayView::mapi n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() { it.keep(view.mapi((i, x) => i + x)) })
}

///|
test "bench ArrayView::filter n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() { it.keep(view.filter(x => x % 2 == 0)) })
}

///|
test "bench ArrayView::filter_map n=100000" (it : @bench.T) {
  let data = make_array_locals_bench_fixedarray()
  let view = data[:]
  it.bench(fn() {
    it.keep(view.filter_map(x => if x % 2 == 0 { Some(x + 1) } else { None }))
  })
}
