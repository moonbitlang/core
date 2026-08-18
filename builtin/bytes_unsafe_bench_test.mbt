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

// Benchmarks for the `#intrinsic` fallback bodies in `bytes_unsafe.mbt`.
//
// These are lowered at the call site on native, so these numbers are expected
// to be flat there; on wasm-gc and js the fallback body is what actually runs.
// Only the little-endian variants are measured — the big-endian ones differ
// solely in the constant shift amounts and compile to the same shape.

///|
let bytes_unsafe_bench_len = 4096

///|
fn bytes_unsafe_bench_data() -> Bytes {
  Bytes::makei(bytes_unsafe_bench_len, i => ((i * 37 + 11) & 0xff).to_byte())
}

///|
test "bench Bytes::unsafe_read_uint16_le n=4096" (it : @bench.T) {
  let data = bytes_unsafe_bench_data()
  it.bench(fn() {
    let mut acc = (0 : UInt16)
    for i in 0..<(bytes_unsafe_bench_len - 1) {
      acc = acc + data.unsafe_read_uint16_le(i)
    }
    it.keep(acc)
  })
}

///|
test "bench Bytes::unsafe_read_uint32_le n=4096" (it : @bench.T) {
  let data = bytes_unsafe_bench_data()
  it.bench(fn() {
    let mut acc = 0U
    for i in 0..<(bytes_unsafe_bench_len - 3) {
      acc = acc + data.unsafe_read_uint32_le(i)
    }
    it.keep(acc)
  })
}

///|
test "bench Bytes::unsafe_read_uint64_le n=4096" (it : @bench.T) {
  let data = bytes_unsafe_bench_data()
  it.bench(fn() {
    let mut acc = 0UL
    for i in 0..<(bytes_unsafe_bench_len - 7) {
      acc = acc + data.unsafe_read_uint64_le(i)
    }
    it.keep(acc)
  })
}

///|
test "bench FixedArray::unsafe_write_uint16_le n=4096" (it : @bench.T) {
  let buf = FixedArray::make(bytes_unsafe_bench_len, b'\x00')
  it.bench(fn() {
    for i in 0..<(bytes_unsafe_bench_len - 1) {
      buf.unsafe_write_uint16_le(i, (i & 0xffff).to_uint16())
    }
    it.keep(buf[0])
  })
}

///|
test "bench FixedArray::unsafe_write_uint32_le n=4096" (it : @bench.T) {
  let buf = FixedArray::make(bytes_unsafe_bench_len, b'\x00')
  it.bench(fn() {
    for i in 0..<(bytes_unsafe_bench_len - 3) {
      buf.unsafe_write_uint32_le(i, i.reinterpret_as_uint())
    }
    it.keep(buf[0])
  })
}

///|
test "bench FixedArray::unsafe_write_uint64_le n=4096" (it : @bench.T) {
  let buf = FixedArray::make(bytes_unsafe_bench_len, b'\x00')
  it.bench(fn() {
    for i in 0..<(bytes_unsafe_bench_len - 7) {
      buf.unsafe_write_uint64_le(i, i.to_uint64())
    }
    it.keep(buf[0])
  })
}
