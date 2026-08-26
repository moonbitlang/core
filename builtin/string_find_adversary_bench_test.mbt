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

// Worst-case benchmarks for substring search: needles whose anchors and
// long prefixes recur at every haystack position, which degrade the
// two-anchor filter to its fallback — plus fast-path guards that must not
// move when the fallback changes.

///|
fn string_find_adversary_needle(half : Int) -> String {
  String::make(half, 'a') + "Z" + String::make(half - 1, 'a')
}

///|
test "bench find adversary m=64 n=4096" (it : @bench.T) {
  let haystack = String::make(4096, 'a')
  let needle = string_find_adversary_needle(32)
  it.bench(fn() { it.keep(haystack.find(needle)) })
}

///|
test "bench rev_find adversary m=64 n=4096" (it : @bench.T) {
  let haystack = String::make(4096, 'a')
  let needle = string_find_adversary_needle(32)
  it.bench(fn() { it.keep(haystack.rev_find(needle)) })
}

///|
test "bench find adversary m=512 n=65536" (it : @bench.T) {
  let haystack = String::make(65536, 'a')
  let needle = string_find_adversary_needle(256)
  it.bench(fn() { it.keep(haystack.find(needle)) })
}

///|
test "bench find dense miss fast path n=4096" (it : @bench.T) {
  let haystack = String::make(4096, 'a')
  it.bench(fn() { it.keep(haystack.find("aaaaZ")) })
}

///|
test "bench find rare hit end fast path n=4096" (it : @bench.T) {
  let haystack = String::make(4092, 'a') + "Zabc"
  it.bench(fn() { it.keep(haystack.find("Zabc")) })
}
