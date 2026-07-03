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
let bytes_find_bench_size = 100_000

///|
fn make_bytes_find_bench_bytes(
  needle : Bytes,
  at~ : Int,
  fill? : Byte = b'\x61',
) -> Bytes {
  let arr = Array::make(bytes_find_bench_size, fill)
  for i in 0..<needle.length() {
    arr[at + i] = needle.unsafe_get(i)
  }
  Bytes::from_array(arr)
}

///|
test "bench Bytes::rev_find short needle at front n=100000" (it : @bench.T) {
  let needle = b"abc"
  let bytes = make_bytes_find_bench_bytes(needle, at=0)
  it.bench(fn() { it.keep(bytes.rev_find(needle)) })
}

///|
test "bench Bytes::rev_find long needle at front n=100000" (it : @bench.T) {
  let needle = b"abcdefghijklmnopqrstuvwxyz0123456789"
  let bytes = make_bytes_find_bench_bytes(needle, at=0)
  it.bench(fn() { it.keep(bytes.rev_find(needle)) })
}
