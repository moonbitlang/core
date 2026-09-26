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
/// A JSON array of `count` strings, each `body(i)` wrapped in quotes.
fn lex_string_bench_array(count : Int, body : (Int) -> String) -> String {
  let buf = StringBuilder()
  buf.write_char('[')
  for i in 0..<count {
    if i > 0 {
      buf.write_char(',')
    }
    buf.write_char('"')
    buf.write_string(body(i))
    buf.write_char('"')
  }
  buf.write_char(']')
  buf.to_string()
}

///|
/// `len` code units of varied ASCII text with no escapes.
fn lex_string_bench_text(len : Int, seed : Int) -> String {
  let buf = StringBuilder(size_hint=len)
  for i in 0..<len {
    buf.write_char((('a' : Int) + (i * 7 + seed) % 26).unsafe_to_char())
  }
  buf.to_string()
}

///|
test "bench json parse object with short keys n=1000" (it : @bench.T) {
  // Regression guard: every key and value stays in the scalar prefix.
  let buf = StringBuilder()
  buf.write_char('{')
  for i in 0..<1000 {
    if i > 0 {
      buf.write_char(',')
    }
    buf.write_string("\"key\{i}\":\"value-\{i}\"")
  }
  buf.write_char('}')
  let input = buf.to_string()
  it.bench(fn() { it.keep(try! @json.parse(input)) })
}

///|
test "bench json parse strings len=20 n=1000" (it : @bench.T) {
  // Unfavourable: on native and wasm each string outlasts the 16-unit scalar
  // prefix, and all but the final string end in the first vector block after
  // it; the final string, followed only by `]`, ends in the scalar tail.
  let input = lex_string_bench_array(1000, i => lex_string_bench_text(20, i))
  it.bench(fn() { it.keep(try! @json.parse(input)) })
}

///|
test "bench json parse strings len=64 n=1000" (it : @bench.T) {
  let input = lex_string_bench_array(1000, i => lex_string_bench_text(64, i))
  it.bench(fn() { it.keep(try! @json.parse(input)) })
}

///|
test "bench json parse strings len=1024 n=64" (it : @bench.T) {
  let input = lex_string_bench_array(64, i => lex_string_bench_text(1024, i))
  it.bench(fn() { it.keep(try! @json.parse(input)) })
}

///|
test "bench json parse single string len=65536" (it : @bench.T) {
  let input = "\"" + lex_string_bench_text(65536, 0) + "\""
  it.bench(fn() { it.keep(try! @json.parse(input)) })
}

///|
test "bench json parse strings len=1040 escape every 100 n=64" (it : @bench.T) {
  // Ten runs of 100 units, each followed by a 2- or 6-unit escape: the fast
  // path stops at the first escape and the slow path lexes the rest.
  let input = lex_string_bench_array(64, i => {
    let buf = StringBuilder()
    for j in 0..<10 {
      buf.write_string(lex_string_bench_text(100, i + j))
      buf.write_string(if j % 2 == 0 { "\\n" } else { "\\u00e9" })
    }
    buf.to_string()
  })
  it.bench(fn() { it.keep(try! @json.parse(input)) })
}

///|
test "bench json parse strings dense escapes n=1000" (it : @bench.T) {
  // Unfavourable: a 2-unit escape after every 3 literal units, so every run
  // is short.
  let input = lex_string_bench_array(1000, i => {
    let buf = StringBuilder()
    for j in 0..<16 {
      buf.write_string(lex_string_bench_text(3, i + j))
      buf.write_string("\\t")
    }
    buf.to_string()
  })
  it.bench(fn() { it.keep(try! @json.parse(input)) })
}
