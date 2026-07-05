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
