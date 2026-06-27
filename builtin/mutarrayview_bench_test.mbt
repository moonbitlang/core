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
let mutarrayview_bench_size = 100_000

///|
fn make_mutarrayview_bench_array() -> Array[Int] {
  Array::makei(mutarrayview_bench_size + 2, i => i % 1024)
}

///|
test "bench MutArrayView::at Int n=100000" (it : @bench.T) {
  let data = make_mutarrayview_bench_array()
  let view = data.mut_view(start=1, end=mutarrayview_bench_size + 1)
  it.bench(fn() {
    let mut sum = 0
    for i = 0; i < mutarrayview_bench_size; i = i + 1 {
      sum = sum + view[i]
    }
    it.keep(sum)
  })
}

///|
test "bench MutArrayView::unsafe_get Int n=100000" (it : @bench.T) {
  let data = make_mutarrayview_bench_array()
  let view = data.mut_view(start=1, end=mutarrayview_bench_size + 1)
  it.bench(fn() {
    let mut sum = 0
    for i = 0; i < mutarrayview_bench_size; i = i + 1 {
      sum = sum + view.unsafe_get(i)
    }
    it.keep(sum)
  })
}

///|
test "bench MutArrayView::set Int n=100000" (it : @bench.T) {
  let data = make_mutarrayview_bench_array()
  let view = data.mut_view(start=1, end=mutarrayview_bench_size + 1)
  it.bench(fn() {
    for i = 0; i < mutarrayview_bench_size; i = i + 1 {
      view[i] = i % 1024
    }
    it.keep(view[0] + view[mutarrayview_bench_size - 1])
  })
}

///|
test "bench MutArrayView::unsafe_set Int n=100000" (it : @bench.T) {
  let data = make_mutarrayview_bench_array()
  let view = data.mut_view(start=1, end=mutarrayview_bench_size + 1)
  it.bench(fn() {
    for i = 0; i < mutarrayview_bench_size; i = i + 1 {
      view.unsafe_set(i, i % 1024)
    }
    it.keep(view.unsafe_get(0) + view.unsafe_get(mutarrayview_bench_size - 1))
  })
}
