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
let stringbuilder_bench_repeats = 4096

///|
let stringbuilder_bench_piece = "abcdefghijklmnop"

///|
let stringbuilder_bench_source = "0123456789abcdefghijklmnopQRSTUVWXYZ"

///|
let stringbuilder_bench_view : StringView = stringbuilder_bench_source[10:26]

///|
test "bench StringBuilder::write_string chunks n=4096" (it : @bench.T) {
  let piece = stringbuilder_bench_piece
  let size_hint = piece.length() * stringbuilder_bench_repeats * 2
  it.bench(fn() {
    let builder = StringBuilder(size_hint~)
    for _ in 0..<stringbuilder_bench_repeats {
      builder.write_string(piece)
    }
    it.keep(builder.to_string().length())
  })
}

///|
test "bench StringBuilder::write_view chunks n=4096" (it : @bench.T) {
  let view = stringbuilder_bench_view
  let size_hint = view.length() * stringbuilder_bench_repeats * 2
  it.bench(fn() {
    let builder = StringBuilder(size_hint~)
    for _ in 0..<stringbuilder_bench_repeats {
      builder.write_view(view)
    }
    it.keep(builder.to_string().length())
  })
}

///|
test "bench StringBuilder::write_stringview chunks n=4096" (it : @bench.T) {
  let view = stringbuilder_bench_view
  let size_hint = view.length() * stringbuilder_bench_repeats * 2
  it.bench(fn() {
    let builder = StringBuilder(size_hint~)
    for _ in 0..<stringbuilder_bench_repeats {
      builder.write_stringview(view)
    }
    it.keep(builder.to_string().length())
  })
}

///|
test "bench StringBuilder::write_char ASCII n=4096" (it : @bench.T) {
  let size_hint = stringbuilder_bench_repeats * 2
  it.bench(fn() {
    let builder = StringBuilder(size_hint~)
    for _ in 0..<stringbuilder_bench_repeats {
      builder.write_char('x')
    }
    it.keep(builder.to_string().length())
  })
}

///|
test "bench StringBuilder::write_char non-BMP n=4096" (it : @bench.T) {
  let ch = (0x1F923).unsafe_to_char()
  let size_hint = stringbuilder_bench_repeats * 4
  it.bench(fn() {
    let builder = StringBuilder(size_hint~)
    for _ in 0..<stringbuilder_bench_repeats {
      builder.write_char(ch)
    }
    it.keep(builder.to_string().length())
  })
}

///|
test "bench StringBuilder::reset reuse spare capacity n=4096" (it : @bench.T) {
  let piece = stringbuilder_bench_piece
  let size_hint = piece.length() * 4
  it.bench(fn() {
    let builder = StringBuilder(size_hint~)
    let mut sum = 0
    for _ in 0..<stringbuilder_bench_repeats {
      builder.write_string(piece)
      sum += builder.to_string().length()
      builder.reset()
    }
    it.keep(sum)
  })
}
