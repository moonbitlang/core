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

// Benchmarks for the generic bitstring extractors (workload shape from
// PR #3777 by @mizchi): the aligned exact-width fast paths (32/64-bit and
// 16-bit), plus the outlined slow-path cases they must not pessimize —
// unaligned offsets and aligned widths without a fixed-width helper
// (e.g. 24-bit).

///|
let bitstring_extract_bench_size = 8192

///|
fn bitstring_extract_bench_bytes() -> Bytes {
  Bytes::makei(bitstring_extract_bench_size, i => (i & 0xff).to_byte())
}

///|
fn bitstring_extract_bench_array() -> Array[Byte] {
  Array::makei(bitstring_extract_bench_size, i => (i & 0xff).to_byte())
}

///|
test "bench BytesView uint_le aligned len=32" (it : @bench.T) {
  let view = bitstring_extract_bench_bytes()[:]
  let last = bitstring_extract_bench_size - 4
  it.bench(fn() {
    let mut acc : UInt = 0
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 4 {
      acc = acc ^ view.unsafe_extract_uint_le(byte_offset * 8, 32)
    }
    it.keep(acc)
  })
}

///|
test "bench BytesView uint_be aligned len=32" (it : @bench.T) {
  let view = bitstring_extract_bench_bytes()[:]
  let last = bitstring_extract_bench_size - 4
  it.bench(fn() {
    let mut acc : UInt = 0
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 4 {
      acc = acc ^ view.unsafe_extract_uint_be(byte_offset * 8, 32)
    }
    it.keep(acc)
  })
}

///|
test "bench ArrayView uint_le aligned len=32" (it : @bench.T) {
  let arr = bitstring_extract_bench_array()
  let view = arr[:]
  let last = bitstring_extract_bench_size - 4
  it.bench(fn() {
    let mut acc : UInt = 0
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 4 {
      acc = acc ^ view.unsafe_extract_uint_le(byte_offset * 8, 32)
    }
    it.keep(acc)
  })
}

///|
test "bench ArrayView uint_be aligned len=32" (it : @bench.T) {
  let arr = bitstring_extract_bench_array()
  let view = arr[:]
  let last = bitstring_extract_bench_size - 4
  it.bench(fn() {
    let mut acc : UInt = 0
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 4 {
      acc = acc ^ view.unsafe_extract_uint_be(byte_offset * 8, 32)
    }
    it.keep(acc)
  })
}

///|
test "bench BytesView uint64_le aligned len=64" (it : @bench.T) {
  let view = bitstring_extract_bench_bytes()[:]
  let last = bitstring_extract_bench_size - 8
  it.bench(fn() {
    let mut acc : UInt64 = 0
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 8 {
      acc = acc ^ view.unsafe_extract_uint64_le(byte_offset * 8, 64)
    }
    it.keep(acc)
  })
}

///|
test "bench BytesView uint64_be aligned len=64" (it : @bench.T) {
  let view = bitstring_extract_bench_bytes()[:]
  let last = bitstring_extract_bench_size - 8
  it.bench(fn() {
    let mut acc : UInt64 = 0
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 8 {
      acc = acc ^ view.unsafe_extract_uint64_be(byte_offset * 8, 64)
    }
    it.keep(acc)
  })
}

///|
test "bench ArrayView uint64_le aligned len=64" (it : @bench.T) {
  let arr = bitstring_extract_bench_array()
  let view = arr[:]
  let last = bitstring_extract_bench_size - 8
  it.bench(fn() {
    let mut acc : UInt64 = 0
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 8 {
      acc = acc ^ view.unsafe_extract_uint64_le(byte_offset * 8, 64)
    }
    it.keep(acc)
  })
}

///|
test "bench ArrayView uint64_be aligned len=64" (it : @bench.T) {
  let arr = bitstring_extract_bench_array()
  let view = arr[:]
  let last = bitstring_extract_bench_size - 8
  it.bench(fn() {
    let mut acc : UInt64 = 0
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 8 {
      acc = acc ^ view.unsafe_extract_uint64_be(byte_offset * 8, 64)
    }
    it.keep(acc)
  })
}

///|
test "bench BytesView uint_le unaligned len=32" (it : @bench.T) {
  let view = bitstring_extract_bench_bytes()[:]
  let last = bitstring_extract_bench_size - 5
  it.bench(fn() {
    let mut acc : UInt = 0
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 4 {
      acc = acc ^ view.unsafe_extract_uint_le(byte_offset * 8 + 4, 32)
    }
    it.keep(acc)
  })
}

///|
test "bench BytesView uint64_le unaligned len=64" (it : @bench.T) {
  let view = bitstring_extract_bench_bytes()[:]
  let last = bitstring_extract_bench_size - 9
  it.bench(fn() {
    let mut acc : UInt64 = 0
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 8 {
      acc = acc ^ view.unsafe_extract_uint64_le(byte_offset * 8 + 4, 64)
    }
    it.keep(acc)
  })
}

///|
test "bench BytesView uint_le aligned len=16" (it : @bench.T) {
  let view = bitstring_extract_bench_bytes()[:]
  let last = bitstring_extract_bench_size - 2
  it.bench(fn() {
    let mut acc : UInt = 0
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 2 {
      acc = acc ^ view.unsafe_extract_uint_le(byte_offset * 8, 16)
    }
    it.keep(acc)
  })
}

///|
test "bench BytesView uint_le aligned len=24" (it : @bench.T) {
  let view = bitstring_extract_bench_bytes()[:]
  let last = bitstring_extract_bench_size - 3
  it.bench(fn() {
    let mut acc : UInt = 0
    for byte_offset = 0; byte_offset <= last; byte_offset = byte_offset + 3 {
      acc = acc ^ view.unsafe_extract_uint_le(byte_offset * 8, 24)
    }
    it.keep(acc)
  })
}
