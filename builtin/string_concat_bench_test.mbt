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
let string_concat_bench_short : String = "42"

///|
let string_concat_bench_text : String = "The quick brown fox jumps over the lazy dog, twice!"

///|
test "bench String::pad_start short" (it : @bench.T) {
  it.bench(fn() { it.keep(string_concat_bench_short.pad_start(8, '0')) })
}

///|
test "bench String::pad_start 50 chars to 64" (it : @bench.T) {
  it.bench(fn() { it.keep(string_concat_bench_text.pad_start(64, ' ')) })
}

///|
test "bench String::pad_end 50 chars to 64" (it : @bench.T) {
  it.bench(fn() { it.keep(string_concat_bench_text.pad_end(64, ' ')) })
}

///|
test "bench StringView::pad_start 20 chars to 64" (it : @bench.T) {
  let view = string_concat_bench_text[5:25]
  it.bench(fn() { it.keep(view.pad_start(64, ' ')) })
}

///|
test "bench String::replace 50 chars" (it : @bench.T) {
  it.bench(fn() {
    it.keep(string_concat_bench_text.replace(old="lazy", new="sleepy"))
  })
}

///|
test "bench StringView + StringView 50 chars" (it : @bench.T) {
  let a = string_concat_bench_text[0:20]
  let b = string_concat_bench_text[20:]
  it.bench(fn() { it.keep(a + b) })
}
