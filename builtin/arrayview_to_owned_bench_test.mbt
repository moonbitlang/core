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
fn[T] bench_view_conversion(it : @bench.T, size : Int32, value : T) -> Unit {
  it.bench(name="fresh view to Array", () => {
    let arr = Array::make(size, value)
    it.keep(arr[:].to_owned())
  })
  let shared = FixedArray::make(size, value)
  it.bench(name="shared view to Array", () => it.keep(shared[:].to_owned()))
  it.bench(name="fresh suffix to Array", () => {
    let arr = FixedArray::make(size + 1, value)
    it.keep(arr[1:].to_owned())
  })
}

///|
test "bench array conversions Int32 n=32" (it : @bench.T) {
  bench_view_conversion(it, 32, 42)
}

///|
test "bench array conversions Int32 n=262144" (it : @bench.T) {
  bench_view_conversion(it, 262144, 42)
}

///|
test "bench array conversions references n=32" (it : @bench.T) {
  bench_view_conversion(it, 32, [42])
}

///|
test "bench array conversions references n=262144" (it : @bench.T) {
  bench_view_conversion(it, 262144, [42])
}
