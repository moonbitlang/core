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
fn bench_retained_chunks(
  it : @bench.T,
  chunk : String,
  chunk_count : Int,
) -> Unit {
  let total = chunk.length() * chunk_count
  it.bench(fn() {
    let mut remaining = chunk_count
    let lexbuf = @lexbuf.Lexbuf::from_fn(() => {
      if remaining == 0 {
        None
      } else {
        remaining -= 1
        Some(chunk)
      }
    })
    lexbuf.__refill()
    lexbuf.__retain_from_cursor()
    while lexbuf.__get_cursor() < total {
      let cursor = lexbuf.__get_cursor()
      lexbuf.__unsafe_code_unit_at(cursor) |> ignore
      lexbuf.__advance(1)
      if lexbuf.__get_cursor() == lexbuf.__buffer_end() {
        lexbuf.__refill()
      }
    }
    it.keep(lexbuf.__get_stringview(0, total).length())
  })
}

///|
test "bench Lexbuf retained token chunks=10000 size=1" (it : @bench.T) {
  bench_retained_chunks(it, "x", 10000)
}

///|
test "bench Lexbuf retained token chunks=1250 size=8" (it : @bench.T) {
  bench_retained_chunks(it, "x".repeat(8), 1250)
}

///|
test "bench Lexbuf retained token chunks=157 size=64" (it : @bench.T) {
  bench_retained_chunks(it, "x".repeat(64), 157)
}

///|
test "bench Lexbuf retained token chunks=20 size=512" (it : @bench.T) {
  bench_retained_chunks(it, "x".repeat(512), 20)
}
