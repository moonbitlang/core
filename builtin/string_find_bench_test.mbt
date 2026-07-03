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
let string_find_bench_len : Int = 4096

///|
fn make_string_find_single_miss() -> String {
  String::make(string_find_bench_len, 'a')
}

///|
fn make_string_find_single_hit_end() -> String {
  String::make(string_find_bench_len - 1, 'a') + "Z"
}

///|
fn make_string_find_single_hit_start() -> String {
  "Z" + String::make(string_find_bench_len - 1, 'a')
}

///|
fn make_string_find_substring_hit_end() -> String {
  String::make(string_find_bench_len - 4, 'a') + "Zabc"
}

///|
fn make_string_find_substring_hit_start() -> String {
  "Zabc" + String::make(string_find_bench_len - 4, 'a')
}

///|
fn make_string_find_view_substring_hit_end() -> String {
  "prefix-" + String::make(string_find_bench_len - 4, 'a') + "Zabc" + "-suffix"
}

///|
fn make_string_find_view_substring_hit_start() -> String {
  "prefix-" + "Zabc" + String::make(string_find_bench_len - 4, 'a') + "-suffix"
}

///|
test "bench StringView::find single code unit hit end n=4096" (it : @bench.T) {
  let data = make_string_find_single_hit_end()
  let view = data[:]
  it.bench(fn() { it.keep(view.find("Z")) })
}

///|
test "bench StringView::find single code unit miss n=4096" (it : @bench.T) {
  let data = make_string_find_single_miss()
  let view = data[:]
  it.bench(fn() { it.keep(view.find("Z")) })
}

///|
test "bench StringView::find substring rare hit end n=4096" (it : @bench.T) {
  let data = make_string_find_substring_hit_end()
  let view = data[:]
  it.bench(fn() { it.keep(view.find("Zabc")) })
}

///|
test "bench StringView::find substring dense miss n=4096" (it : @bench.T) {
  let data = make_string_find_single_miss()
  let view = data[:]
  it.bench(fn() { it.keep(view.find("aaaaZ")) })
}

///|
test "bench StringView::find offset view rare hit end n=4096" (it : @bench.T) {
  let data = make_string_find_view_substring_hit_end()
  let view = data[7:string_find_bench_len + 7]
  it.bench(fn() { it.keep(view.find("Zabc")) })
}

///|
test "bench StringView::rev_find single code unit hit start n=4096" (
  it : @bench.T,
) {
  let data = make_string_find_single_hit_start()
  let view = data[:]
  it.bench(fn() { it.keep(view.rev_find("Z")) })
}

///|
test "bench StringView::rev_find single code unit miss n=4096" (it : @bench.T) {
  let data = make_string_find_single_miss()
  let view = data[:]
  it.bench(fn() { it.keep(view.rev_find("Z")) })
}

///|
test "bench StringView::rev_find substring rare hit start n=4096" (
  it : @bench.T,
) {
  let data = make_string_find_substring_hit_start()
  let view = data[:]
  it.bench(fn() { it.keep(view.rev_find("Zabc")) })
}

///|
test "bench StringView::rev_find substring dense miss n=4096" (it : @bench.T) {
  let data = make_string_find_single_miss()
  let view = data[:]
  it.bench(fn() { it.keep(view.rev_find("aaaaZ")) })
}

///|
test "bench StringView::rev_find offset view rare hit start n=4096" (
  it : @bench.T,
) {
  let data = make_string_find_view_substring_hit_start()
  let view = data[7:string_find_bench_len + 7]
  it.bench(fn() { it.keep(view.rev_find("Zabc")) })
}
