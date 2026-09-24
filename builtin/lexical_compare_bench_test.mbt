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
let lc_equal_a : Bytes = Bytes::makei(256, i => (i % 251).to_byte())

///|
let lc_equal_b : Bytes = Bytes::makei(256, i => (i % 251).to_byte())

///|
// Identical except the last byte: full common-prefix scan.
let lc_prefix_a : Bytes = Bytes::makei(256, i => (i % 251).to_byte())

///|
let lc_prefix_b : Bytes = Bytes::makei(256, i => {
  if i == 255 {
    b'\xff'
  } else {
    (i % 251).to_byte()
  }
})

///|
// Differ at byte 1: early-exit regression guard.
let lc_early_a : Bytes = Bytes::makei(256, _ => b'a')

///|
let lc_early_b : Bytes = Bytes::makei(256, i => if i == 1 { b'b' } else { b'a' })

///|
test "bench lexical_compare equal n=256" (it : @bench.T) {
  it.bench(fn() { it.keep(lc_equal_a.lexical_compare(lc_equal_b)) })
}

///|
test "bench lexical_compare common-prefix n=256" (it : @bench.T) {
  it.bench(fn() { it.keep(lc_prefix_a.lexical_compare(lc_prefix_b)) })
}

///|
test "bench lexical_compare early-diff n=256" (it : @bench.T) {
  it.bench(fn() { it.keep(lc_early_a.lexical_compare(lc_early_b)) })
}

///|
fn lc_string_make(len : Int, diff_at? : Int = -1) -> String {
  let sb = StringBuilder(size_hint=len)
  for i in 0..<len {
    sb.write_char(
      // 'a' + (i % 26), with the diff position bumped to 'z' + 1
      Int::unsafe_to_char(if i == diff_at { '{' } else { 'a' + i % 26 }),
    )
  }
  sb.to_string()
}

///|
let lc_str_equal_a : String = lc_string_make(256)

///|
let lc_str_equal_b : String = lc_string_make(256)

///|
// Identical except the last code unit: full common-prefix scan.
let lc_str_prefix_a : String = lc_string_make(256)

///|
let lc_str_prefix_b : String = lc_string_make(256, diff_at=255)

///|
// Differ at code unit 1: early-exit regression guard.
let lc_str_early_a : String = lc_string_make(256)

///|
let lc_str_early_b : String = lc_string_make(256, diff_at=1)

///|
test "bench String::lexical_compare equal n=256" (it : @bench.T) {
  it.bench(fn() { it.keep(lc_str_equal_a.lexical_compare(lc_str_equal_b)) })
}

///|
test "bench String::lexical_compare common-prefix n=256" (it : @bench.T) {
  it.bench(fn() { it.keep(lc_str_prefix_a.lexical_compare(lc_str_prefix_b)) })
}

///|
test "bench String::lexical_compare early-diff n=256" (it : @bench.T) {
  it.bench(fn() { it.keep(lc_str_early_a.lexical_compare(lc_str_early_b)) })
}

///|
test "bench StringView::lexical_compare equal n=256" (it : @bench.T) {
  it.bench(fn() { it.keep(lc_str_equal_a[:].lexical_compare(lc_str_equal_b)) })
}

///|
test "bench StringView::lexical_compare common-prefix n=256" (it : @bench.T) {
  it.bench(fn() { it.keep(lc_str_prefix_a[:].lexical_compare(lc_str_prefix_b)) })
}

///|
test "bench StringView::lexical_compare early-diff n=256" (it : @bench.T) {
  it.bench(fn() { it.keep(lc_str_early_a[:].lexical_compare(lc_str_early_b)) })
}

///|
// Compare for String is shortlex (length first), so the interesting case is
// equal-length strings where the inner loop runs to the first difference.
test "bench String::compare equal-length common-prefix n=256" (it : @bench.T) {
  it.bench(fn() { it.keep(lc_str_prefix_a.compare(lc_str_prefix_b)) })
}
