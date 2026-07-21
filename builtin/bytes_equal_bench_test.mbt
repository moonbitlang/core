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
let bytes_equal_bench_size = 100_000

///|
fn make_bytes_equal_bench_bytes(diff_at? : Int = -1) -> Bytes {
  let arr = Array::make(bytes_equal_bench_size, b'\x61')
  if diff_at >= 0 {
    arr[diff_at] = b'\x62'
  }
  Bytes::from_array(arr)
}

///|
fn make_bytes_equal_bench_aliases() -> Array[Bytes] {
  let bytes = make_bytes_equal_bench_bytes()
  let aliases = Array::make(2, b"")
  aliases[0] = bytes
  aliases[1] = bytes
  aliases
}

///|
test "bench Bytes::equal n=100000 equal" (it : @bench.T) {
  let left = make_bytes_equal_bench_bytes()
  let right = make_bytes_equal_bench_bytes()
  it.bench(fn() { it.keep(left == right) })
}

///|
test "bench Bytes::equal n=100000 aliased object" (it : @bench.T) {
  let aliases = make_bytes_equal_bench_aliases()
  let mut index = 0
  it.bench(fn() {
    index = 1 - index
    it.keep(aliases[index] == aliases[1 - index])
  })
}

///|
test "bench Bytes::equal n=100000 mismatch at end" (it : @bench.T) {
  let left = make_bytes_equal_bench_bytes()
  let right = make_bytes_equal_bench_bytes(diff_at=bytes_equal_bench_size - 1)
  it.bench(fn() { it.keep(left == right) })
}
