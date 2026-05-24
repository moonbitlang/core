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
let make_blit_ref_bench_size = 1_000_000

///|
let make_blit_ref_bench_half_size = 500_000

///|
fn make_blit_ref_array(len : Int) -> Array[String] {
  Array::make(len, "value")
}

///|
fn make_blit_ref_fixedarray(len : Int) -> FixedArray[String] {
  FixedArray::make(len, "value")
}

///|
test "bench FixedArray::copy Ref n=1000000" (it : @bench.T) {
  let data = make_blit_ref_fixedarray(make_blit_ref_bench_size)
  it.bench(fn() { it.keep(data.copy()) })
}

///|
test "bench Array::from_fixed_array Ref n=1000000" (it : @bench.T) {
  let data = make_blit_ref_fixedarray(make_blit_ref_bench_size)
  it.bench(fn() { it.keep(Array::from_fixed_array(data)) })
}

///|
test "bench Array::add Ref n=500000+500000" (it : @bench.T) {
  let left = make_blit_ref_array(make_blit_ref_bench_half_size)
  let right = make_blit_ref_array(make_blit_ref_bench_half_size)
  it.bench(fn() { it.keep(left + right) })
}

///|
test "bench ArrayView::add Ref n=500000+500000" (it : @bench.T) {
  let left = make_blit_ref_array(make_blit_ref_bench_half_size)
  let right = make_blit_ref_array(make_blit_ref_bench_half_size)
  let left_view = left[:]
  let right_view = right[:]
  it.bench(fn() { it.keep(left_view + right_view) })
}

///|
test "bench Array::push Ref n=1000000 resize" (it : @bench.T) {
  it.bench(fn() {
    let data : Array[String] = []
    for _ in 0..<make_blit_ref_bench_size {
      data.push("value")
    }
    it.keep(data)
  })
}
