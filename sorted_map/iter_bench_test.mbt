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
fn iter_bench_map() -> @sorted_map.SortedMap[Int, Int] {
  @sorted_map.from_array(Array::makei(16384, i => (i, i)))
}

///|
test "bench sorted_map iter n=16384" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(fn() { it.keep(map.iter().fold(init=0, (sum, p) => sum + p.1)) })
}

///|
test "bench sorted_map keys n=16384" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(fn() { it.keep(map.keys().fold(init=0, (sum, k) => sum + k)) })
}

///|
test "bench sorted_map values n=16384" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(fn() { it.keep(map.values().fold(init=0, (sum, v) => sum + v)) })
}

///|
test "bench sorted_map iter take n=8" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(fn() {
    it.keep(map.iter().take(8).fold(init=0, (sum, p) => sum + p.1))
  })
}

///|
test "bench sorted_map empty iter" (it : @bench.T) {
  let map : @sorted_map.SortedMap[Int, Int] = @sorted_map.from_array([])
  it.bench(fn() { it.keep(map.iter().next()) })
}

///|
test "bench sorted_map iter string keys and values n=16384" (it : @bench.T) {
  let entries = Array::makei(16384, i => ("key/\{1000000 + i}", "value/\{i}"))
  let map = @sorted_map.from_array(entries)
  it.bench(fn() {
    it.keep(
      map.iter().fold(init=0, (sum, p) => sum + p.0.length() + p.1.length()),
    )
  })
}

///|
test "bench sorted_map rev_iter n=16384 control" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(fn() { it.keep(map.rev_iter().fold(init=0, (sum, p) => sum + p.1)) })
}
