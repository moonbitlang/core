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
let bytes_from_array_bench_size : Int = 256 * 1024

///|
let bytes_from_array_bench_source : FixedArray[Byte] = FixedArray::makei(
  bytes_from_array_bench_size + 1,
  fn(i) { (i & 0xff).to_byte() },
)

///|
fn bytes_from_array_bench_makei(arr : ArrayView[Byte]) -> Bytes {
  Bytes::makei(arr.length(), fn(i) { arr[i] })
}

///|
test "bench Bytes::from_array n=262144 full" (it : @bench.T) {
  it.bench(fn() {
    it.keep(
      Bytes::from_array(
        bytes_from_array_bench_source[:bytes_from_array_bench_size],
      ),
    )
  })
}

///|
test "bench Bytes::from_array n=262144 sliced" (it : @bench.T) {
  it.bench(fn() {
    it.keep(Bytes::from_array(bytes_from_array_bench_source[1:]))
  })
}

///|
test "bench Bytes::makei from ArrayView n=262144 full" (it : @bench.T) {
  it.bench(fn() {
    it.keep(
      bytes_from_array_bench_makei(
        bytes_from_array_bench_source[:bytes_from_array_bench_size],
      ),
    )
  })
}

///|
test "bench Bytes::makei from ArrayView n=262144 sliced" (it : @bench.T) {
  it.bench(fn() {
    it.keep(bytes_from_array_bench_makei(bytes_from_array_bench_source[1:]))
  })
}

///|
// Fresh inputs are created inside the timed closure and consumed at their last
// use. These measure allocation/fill plus conversion; shared inputs below keep
// the copying fallback in the measurement.
fn bench_bytes_from_array_ownership(it : @bench.T, size : Int) -> Unit {
  it.bench(name="fresh FixedArray", () => {
    let arr = FixedArray::make(size, b'a')
    it.keep(Bytes::from_array(arr))
  })
  it.bench(name="fresh Array", () => {
    let arr = Array::make(size, b'a')
    it.keep(Bytes::from_array(arr))
  })
  let shared = FixedArray::make(size, b'a')
  it.bench(name="shared full buffer", () => it.keep(Bytes::from_array(shared)))
}

///|
test "bench Bytes::from_array ownership n=32" (it : @bench.T) {
  bench_bytes_from_array_ownership(it, 32)
}

///|
test "bench Bytes::from_array ownership n=4096" (it : @bench.T) {
  bench_bytes_from_array_ownership(it, 4096)
}

///|
test "bench Bytes::from_array ownership n=262144" (it : @bench.T) {
  bench_bytes_from_array_ownership(it, 262144)
}
