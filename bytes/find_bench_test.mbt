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
let find_bench_len : Int = 4096

///|
fn make_find_single_hit_end() -> Bytes {
  Bytes::makei(find_bench_len, i => {
    if i == find_bench_len - 1 {
      b'Z'
    } else {
      b'a'
    }
  })
}

///|
fn make_find_single_miss() -> Bytes {
  Bytes::makei(find_bench_len, _ => b'a')
}

///|
fn make_find_substring_hit_end() -> Bytes {
  Bytes::makei(find_bench_len, i => {
    match i - (find_bench_len - 4) {
      0 => b'Z'
      1 => b'a'
      2 => b'b'
      3 => b'c'
      _ => b'a'
    }
  })
}

///|
fn make_find_view_substring_hit_end() -> Bytes {
  Bytes::makei(find_bench_len + 17, i => {
    match i - (find_bench_len + 7 - 4) {
      0 => b'Z'
      1 => b'a'
      2 => b'b'
      3 => b'c'
      _ => b'a'
    }
  })
}

///|
fn make_find_single_hit_start() -> Bytes {
  Bytes::makei(find_bench_len, i => if i == 0 { b'Z' } else { b'a' })
}

///|
fn make_find_substring_hit_start() -> Bytes {
  Bytes::makei(find_bench_len, i => {
    match i {
      0 => b'Z'
      1 => b'a'
      2 => b'b'
      3 => b'c'
      _ => b'a'
    }
  })
}

///|
fn make_find_view_substring_hit_start() -> Bytes {
  Bytes::makei(find_bench_len + 17, i => {
    match i - 7 {
      0 => b'Z'
      1 => b'a'
      2 => b'b'
      3 => b'c'
      _ => b'a'
    }
  })
}

///|
test "bench BytesView::find single byte hit end n=4096" (it : @bench.T) {
  let data = make_find_single_hit_end()
  let view = data[:]
  it.bench(fn() { it.keep(view.find(b"Z")) })
}

///|
test "bench BytesView::find single byte miss n=4096" (it : @bench.T) {
  let data = make_find_single_miss()
  let view = data[:]
  it.bench(fn() { it.keep(view.find(b"Z")) })
}

///|
test "bench BytesView::find substring rare hit end n=4096" (it : @bench.T) {
  let data = make_find_substring_hit_end()
  let view = data[:]
  it.bench(fn() { it.keep(view.find(b"Zabc")) })
}

///|
test "bench BytesView::find substring dense miss n=4096" (it : @bench.T) {
  let data = make_find_single_miss()
  let view = data[:]
  it.bench(fn() { it.keep(view.find(b"aaaaZ")) })
}

///|
test "bench BytesView::find offset view rare hit end n=4096" (it : @bench.T) {
  let data = make_find_view_substring_hit_end()
  let view = data[7:find_bench_len + 7]
  it.bench(fn() { it.keep(view.find(b"Zabc")) })
}

///|
test "bench BytesView::find long dense miss n=4096" (it : @bench.T) {
  let data = make_find_single_miss()
  let pattern = Bytes::makei(40, i => if i == 39 { b'Z' } else { b'a' })
  it.bench(fn() { it.keep(data.find(pattern)) })
}

///|
test "bench BytesView::find single byte miss n=32" (it : @bench.T) {
  let data = Bytes::makei(32, _ => b'a')
  let view = data[:]
  it.bench(fn() { it.keep(view.find(b"Z")) })
}

///|
test "bench BytesView::find substring miss n=32" (it : @bench.T) {
  let data = Bytes::makei(32, _ => b'a')
  let view = data[:]
  it.bench(fn() { it.keep(view.find(b"aaaaZ")) })
}

///|
test "bench BytesView::rev_find single byte hit start n=4096" (it : @bench.T) {
  let data = make_find_single_hit_start()
  let view = data[:]
  it.bench(fn() { it.keep(view.rev_find(b"Z")) })
}

///|
test "bench BytesView::rev_find single byte miss n=4096" (it : @bench.T) {
  let data = make_find_single_miss()
  let view = data[:]
  it.bench(fn() { it.keep(view.rev_find(b"Z")) })
}

///|
test "bench BytesView::rev_find substring rare hit start n=4096" (it : @bench.T) {
  let data = make_find_substring_hit_start()
  let view = data[:]
  it.bench(fn() { it.keep(view.rev_find(b"Zabc")) })
}

///|
test "bench BytesView::rev_find substring dense miss n=4096" (it : @bench.T) {
  let data = make_find_single_miss()
  let view = data[:]
  it.bench(fn() { it.keep(view.rev_find(b"aaaaZ")) })
}

///|
test "bench BytesView::rev_find offset view rare hit start n=4096" (
  it : @bench.T,
) {
  let data = make_find_view_substring_hit_start()
  let view = data[7:find_bench_len + 7]
  it.bench(fn() { it.keep(view.rev_find(b"Zabc")) })
}

///|
test "bench BytesView::rev_find long dense miss n=4096" (it : @bench.T) {
  let data = make_find_single_miss()
  let pattern = Bytes::makei(40, i => if i == 39 { b'Z' } else { b'a' })
  it.bench(fn() { it.keep(data.rev_find(pattern)) })
}
