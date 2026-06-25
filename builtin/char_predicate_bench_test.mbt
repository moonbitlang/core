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
let char_predicate_bench_rounds = 1000

///|
fn char_predicate_ascii_text() -> Array[Char] {
  [
    'l', 'e', 't', ' ', 'n', 'a', 'm', 'e', ' ', '=', ' ', '"', 'M', 'o', 'o', 'n',
    'B', 'i', 't', '"', '\n', 'i', 'f', ' ', 'n', 'a', 'm', 'e', '.', 'l', 'e', 'n',
    'g', 't', 'h', '(', ')', ' ', '>', ' ', '0', ' ', '{', '\n', ' ', ' ', 'p', 'r',
    'i', 'n', 't', 'l', 'n', '(', 'n', 'a', 'm', 'e', ')', '\n', '}', '\n',
  ]
}

///|
fn char_predicate_unicode_text() -> Array[Char] {
  [
    '月', ' ', 'B', 'i', 't', '\n', '語', '\u{00A0}', '٣', '۶', '¾', '①',
    '中', '\u{2003}', 'A', '9', '藏', '\u{2029}', '😀', '\u{3000}', 'z', '0',
  ]
}

///|
fn count_ascii_whitespace(data : Array[Char]) -> Int {
  let mut count = 0
  for _ in 0..<char_predicate_bench_rounds {
    for ch in data {
      if ch.is_ascii_whitespace() {
        count += 1
      }
    }
  }
  count
}

///|
fn count_whitespace(data : Array[Char]) -> Int {
  let mut count = 0
  for _ in 0..<char_predicate_bench_rounds {
    for ch in data {
      if ch.is_whitespace() {
        count += 1
      }
    }
  }
  count
}

///|
fn count_numeric(data : Array[Char]) -> Int {
  let mut count = 0
  for _ in 0..<char_predicate_bench_rounds {
    for ch in data {
      if ch.is_numeric() {
        count += 1
      }
    }
  }
  count
}

///|
test "bench Char::is_ascii_whitespace ascii n=62000" (it : @bench.T) {
  let data = char_predicate_ascii_text()
  it.bench(fn() { it.keep(count_ascii_whitespace(data)) })
}

///|
test "bench Char::is_whitespace ascii n=62000" (it : @bench.T) {
  let data = char_predicate_ascii_text()
  it.bench(fn() { it.keep(count_whitespace(data)) })
}

///|
test "bench Char::is_whitespace unicode n=22000" (it : @bench.T) {
  let data = char_predicate_unicode_text()
  it.bench(fn() { it.keep(count_whitespace(data)) })
}

///|
test "bench Char::is_numeric ascii n=62000" (it : @bench.T) {
  let data = char_predicate_ascii_text()
  it.bench(fn() { it.keep(count_numeric(data)) })
}

///|
test "bench Char::is_numeric unicode n=22000" (it : @bench.T) {
  let data = char_predicate_unicode_text()
  it.bench(fn() { it.keep(count_numeric(data)) })
}
