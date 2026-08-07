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
let bitstring_generic_aligned_bench_size = 8192

///|
fn make_bitstring_generic_aligned_bench_bytes() -> Bytes {
  Bytes::makei(bitstring_generic_aligned_bench_size, i => (i & 0xff).to_byte())
}

///|
fn make_bitstring_generic_aligned_bench_array() -> Array[Byte] {
  Array::makei(bitstring_generic_aligned_bench_size, i => (i & 0xff).to_byte())
}

///|
test "bench BytesView::unsafe_extract_uint_le aligned len=32 n=8192" (
  it : @bench.T,
) {
  let bytes = make_bitstring_generic_aligned_bench_bytes()
  let view = bytes[:]
  let last = bitstring_generic_aligned_bench_size - 4
  it.bench(fn() {
    let mut sum = 0U
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 4 {
      sum = sum ^ view.unsafe_extract_uint_le(byte_offset << 3, 32)
    }
    it.keep(sum)
  })
}

///|
test "bench ArrayView::unsafe_extract_uint_le aligned len=32 n=8192" (
  it : @bench.T,
) {
  let arr = make_bitstring_generic_aligned_bench_array()
  let view = arr[:]
  let last = bitstring_generic_aligned_bench_size - 4
  it.bench(fn() {
    let mut sum = 0U
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 4 {
      sum = sum ^ view.unsafe_extract_uint_le(byte_offset << 3, 32)
    }
    it.keep(sum)
  })
}

///|
test "bench BytesView::unsafe_extract_uint_be aligned len=32 n=8192" (
  it : @bench.T,
) {
  let bytes = make_bitstring_generic_aligned_bench_bytes()
  let view = bytes[:]
  let last = bitstring_generic_aligned_bench_size - 4
  it.bench(fn() {
    let mut sum = 0U
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 4 {
      sum = sum ^ view.unsafe_extract_uint_be(byte_offset << 3, 32)
    }
    it.keep(sum)
  })
}

///|
test "bench ArrayView::unsafe_extract_uint_be aligned len=32 n=8192" (
  it : @bench.T,
) {
  let arr = make_bitstring_generic_aligned_bench_array()
  let view = arr[:]
  let last = bitstring_generic_aligned_bench_size - 4
  it.bench(fn() {
    let mut sum = 0U
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 4 {
      sum = sum ^ view.unsafe_extract_uint_be(byte_offset << 3, 32)
    }
    it.keep(sum)
  })
}

///|
test "bench BytesView::unsafe_extract_uint64_le aligned len=64 n=8192" (
  it : @bench.T,
) {
  let bytes = make_bitstring_generic_aligned_bench_bytes()
  let view = bytes[:]
  let last = bitstring_generic_aligned_bench_size - 8
  it.bench(fn() {
    let mut sum = 0UL
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 8 {
      sum = sum ^ view.unsafe_extract_uint64_le(byte_offset << 3, 64)
    }
    it.keep(sum)
  })
}

///|
test "bench BytesView::unsafe_extract_uint64_be aligned len=64 n=8192" (
  it : @bench.T,
) {
  let bytes = make_bitstring_generic_aligned_bench_bytes()
  let view = bytes[:]
  let last = bitstring_generic_aligned_bench_size - 8
  it.bench(fn() {
    let mut sum = 0UL
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 8 {
      sum = sum ^ view.unsafe_extract_uint64_be(byte_offset << 3, 64)
    }
    it.keep(sum)
  })
}

///|
test "bench ArrayView::unsafe_extract_uint64_be aligned len=64 n=8192" (
  it : @bench.T,
) {
  let arr = make_bitstring_generic_aligned_bench_array()
  let view = arr[:]
  let last = bitstring_generic_aligned_bench_size - 8
  it.bench(fn() {
    let mut sum = 0UL
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 8 {
      sum = sum ^ view.unsafe_extract_uint64_be(byte_offset << 3, 64)
    }
    it.keep(sum)
  })
}

///|
test "bench ArrayView::unsafe_extract_uint64_le aligned len=64 n=8192" (
  it : @bench.T,
) {
  let arr = make_bitstring_generic_aligned_bench_array()
  let view = arr[:]
  let last = bitstring_generic_aligned_bench_size - 8
  it.bench(fn() {
    let mut sum = 0UL
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 8 {
      sum = sum ^ view.unsafe_extract_uint64_le(byte_offset << 3, 64)
    }
    it.keep(sum)
  })
}
