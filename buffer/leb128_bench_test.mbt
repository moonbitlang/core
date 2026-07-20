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
let leb128_bench_size = 100_000

///|
let leb128_bench_large_size = 1_000_000

///|
test "bench LEB128 UInt max-width n=1" (it : @bench.T) {
  it.bench(fn() {
    let buffer = Buffer()
    buffer.write_leb128(0xffffffffU)
    it.keep(buffer.length())
  })
}

///|
test "bench LEB128 UInt64 max-width n=1" (it : @bench.T) {
  it.bench(fn() {
    let buffer = Buffer()
    buffer.write_leb128(0xffffffffffffffffUL)
    it.keep(buffer.length())
  })
}

///|
test "bench LEB128 Int min n=1" (it : @bench.T) {
  it.bench(fn() {
    let buffer = Buffer()
    buffer.write_leb128(@int.MIN_VALUE)
    it.keep(buffer.length())
  })
}

///|
test "bench LEB128 Int64 min n=1" (it : @bench.T) {
  it.bench(fn() {
    let buffer = Buffer()
    buffer.write_leb128(@int64.MIN_VALUE)
    it.keep(buffer.length())
  })
}

///|
test "bench LEB128 UInt mixed-width n=100000" (it : @bench.T) {
  it.bench(fn() {
    let buffer = Buffer()
    for i in 0..<leb128_bench_size {
      let value = (i * 0x10001).reinterpret_as_uint()
      buffer.write_leb128(value)
    }
    it.keep(buffer.length())
  })
}

///|
test "bench LEB128 UInt64 mixed-width n=100000" (it : @bench.T) {
  it.bench(fn() {
    let buffer = Buffer()
    for i in 0..<leb128_bench_size {
      let value = (i.to_uint64() * 0x100000001UL) | 0x80UL
      buffer.write_leb128(value)
    }
    it.keep(buffer.length())
  })
}

///|
test "bench LEB128 UInt64 mixed-width n=1000000" (it : @bench.T) {
  it.bench(fn() {
    let buffer = Buffer()
    for i in 0..<leb128_bench_large_size {
      let value = (i.to_uint64() * 0x100000001UL) | 0x80UL
      buffer.write_leb128(value)
    }
    it.keep(buffer.length())
  })
}

///|
test "bench LEB128 Int64 mixed-width n=1000000" (it : @bench.T) {
  it.bench(fn() {
    let buffer = Buffer()
    for i in 0..<leb128_bench_large_size {
      let magnitude = i.to_int64() * 0x100000001L
      let value = if i % 2 == 0 { magnitude } else { -magnitude }
      buffer.write_leb128(value)
    }
    it.keep(buffer.length())
  })
}
