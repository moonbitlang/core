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
// Fresh inputs are allocated and filled inside the timed closure. These measure
// construction plus conversion; the shared inputs exercise the copying path.
fn[T] bench_fixed_conversion(it : @bench.T, size : Int32, value : T) -> Unit {
  it.bench(name="fresh Array to FixedArray", () => {
    let arr = Array::make(size, value)
    it.keep(FixedArray::from_array(arr))
  })
  it.bench(name="fresh Array to ReadOnlyArray", () => {
    let arr = Array::make(size, value)
    it.keep(ReadOnlyArray::from_array(arr))
  })
  let shared = FixedArray::make(size, value)
  it.bench(name="shared view to FixedArray", () => {
    it.keep(FixedArray::from_array(shared))
  })
}

///|
test "bench array conversions Int32 n=32" (it : @bench.T) {
  bench_fixed_conversion(it, 32, 42)
}

///|
test "bench array conversions Int32 n=262144" (it : @bench.T) {
  bench_fixed_conversion(it, 262144, 42)
}

///|
test "bench array conversions references n=32" (it : @bench.T) {
  bench_fixed_conversion(it, 32, [42])
}

///|
test "bench array conversions references n=262144" (it : @bench.T) {
  bench_fixed_conversion(it, 262144, [42])
}
