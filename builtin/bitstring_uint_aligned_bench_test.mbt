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
let bitstring_uint_aligned_bench_size = 8192

///|
fn make_bitstring_uint_aligned_bench_bytes() -> Bytes {
  Bytes::makei(bitstring_uint_aligned_bench_size, i => (i & 0xff).to_byte())
}

///|
test "bench Bytes::unsafe_extract_uint_le_aligned n=8192" (it : @bench.T) {
  let bytes = make_bitstring_uint_aligned_bench_bytes()
  let last = bitstring_uint_aligned_bench_size - 4
  it.bench(fn() {
    let mut sum = 0U
    for offset = 0; offset <= last; offset = offset + 4 {
      sum = sum ^ bytes.unsafe_extract_uint_le_aligned(offset)
    }
    it.keep(sum)
  })
}
