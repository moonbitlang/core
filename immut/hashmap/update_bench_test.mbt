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
let update_bench_map : @hashmap.HashMap[Int, Int] = @hashmap.from_iter(
  (0).until(100_000).map(i => (i, i)),
)

///|
test "bench HashMap::remove absent x1000 n=100000" (it : @bench.T) {
  it.bench(fn() {
    let mut m = update_bench_map
    for i in 0..<1000 {
      m = m.remove(-1 - i)
    }
    it.keep(m)
  })
}

///|
test "bench HashMap::remove present x1000 n=100000" (it : @bench.T) {
  it.bench(fn() {
    let mut m = update_bench_map
    for i in 0..<1000 {
      m = m.remove(i * 97)
    }
    it.keep(m)
  })
}

///|
test "bench HashMap::union with a derived version n=100000" (it : @bench.T) {
  let derived = update_bench_map.add(-1, -1)
  it.bench(fn() { it.keep(update_bench_map.union(derived)) })
}

///|
test "bench HashMap::intersection with a derived version n=100000" (
  it : @bench.T,
) {
  let derived = update_bench_map.remove(5)
  it.bench(fn() { it.keep(update_bench_map.intersection(derived)) })
}
