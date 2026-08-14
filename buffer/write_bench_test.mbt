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
/// Append-path benchmarks. Every buffer is created with an exact `size_hint` so
/// the measured loop stays on the fast path and does not pay for growth.
let buffer_bench_repeats = 4096

///|
let buffer_bench_piece = "abcdefghijklmnop"

///|
test "bench Buffer::write_byte n=4096" (it : @bench.T) {
  it.bench(fn() {
    let buf = Buffer(size_hint=buffer_bench_repeats)
    for i in 0..<buffer_bench_repeats {
      buf.write_byte(i.to_byte())
    }
    it.keep(buf.length())
  })
}

///|
test "bench Buffer::write_uint16_be n=4096" (it : @bench.T) {
  it.bench(fn() {
    let buf = Buffer(size_hint=buffer_bench_repeats * 2)
    for i in 0..<buffer_bench_repeats {
      buf.write_uint16_be(i.to_uint16())
    }
    it.keep(buf.length())
  })
}

///|
test "bench Buffer::write_uint_le n=4096" (it : @bench.T) {
  it.bench(fn() {
    let buf = Buffer(size_hint=buffer_bench_repeats * 4)
    for i in 0..<buffer_bench_repeats {
      buf.write_uint_le(i.reinterpret_as_uint())
    }
    it.keep(buf.length())
  })
}

///|
test "bench Buffer::write_uint64_be n=4096" (it : @bench.T) {
  it.bench(fn() {
    let buf = Buffer(size_hint=buffer_bench_repeats * 8)
    for i in 0..<buffer_bench_repeats {
      buf.write_uint64_be(i.to_uint64())
    }
    it.keep(buf.length())
  })
}

///|
test "bench Buffer::write_char_utf8 ASCII n=4096" (it : @bench.T) {
  it.bench(fn() {
    let buf = Buffer(size_hint=buffer_bench_repeats)
    for _ in 0..<buffer_bench_repeats {
      buf.write_char_utf8('x')
    }
    it.keep(buf.length())
  })
}

///|
test "bench Buffer::write_char_utf8 non-BMP n=4096" (it : @bench.T) {
  let ch = (0x1F923).unsafe_to_char()
  it.bench(fn() {
    let buf = Buffer(size_hint=buffer_bench_repeats * 4)
    for _ in 0..<buffer_bench_repeats {
      buf.write_char_utf8(ch)
    }
    it.keep(buf.length())
  })
}

///|
test "bench Buffer::write_char_utf16le BMP n=4096" (it : @bench.T) {
  it.bench(fn() {
    let buf = Buffer(size_hint=buffer_bench_repeats * 2)
    for _ in 0..<buffer_bench_repeats {
      buf.write_char_utf16le('x')
    }
    it.keep(buf.length())
  })
}

///|
test "bench Buffer::write_string_utf16le chunks n=4096" (it : @bench.T) {
  let piece = buffer_bench_piece
  let size_hint = piece.length() * buffer_bench_repeats * 2
  it.bench(fn() {
    let buf = Buffer(size_hint~)
    for _ in 0..<buffer_bench_repeats {
      buf.write_string_utf16le(piece)
    }
    it.keep(buf.length())
  })
}

///|
test "bench @buffer.from_array n=4096" (it : @bench.T) {
  let arr = Array::makei(buffer_bench_repeats, i => i.to_byte())
  it.bench(fn() {
    // Keep the buffer itself: keeping only `length()` lets the backend prove
    // the copied bytes are dead and drop the loop entirely.
    let buf = @buffer.from_array(arr)
    it.keep(buf)
  })
}
