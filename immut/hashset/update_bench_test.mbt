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
let update_bench_set : @hashset.HashSet[Int] = @hashset.from_iter(
  (0).until(100_000),
)

///|
test "bench HashSet::add existing x1000 n=100000" (it : @bench.T) {
  it.bench(fn() {
    let mut s = update_bench_set
    for i in 0..<1000 {
      s = s.add(i * 97)
    }
    it.keep(s)
  })
}

///|
test "bench HashSet::remove absent x1000 n=100000" (it : @bench.T) {
  it.bench(fn() {
    let mut s = update_bench_set
    for i in 0..<1000 {
      s = s.remove(-1 - i)
    }
    it.keep(s)
  })
}

///|
test "bench HashSet::add new x1000 n=100000" (it : @bench.T) {
  it.bench(fn() {
    let mut s = update_bench_set
    for i in 0..<1000 {
      s = s.add(100_000 + i)
    }
    it.keep(s)
  })
}

///|
test "bench HashSet::union with a derived version n=100000" (it : @bench.T) {
  let derived = update_bench_set.add(-1)
  it.bench(fn() { it.keep(update_bench_set.union(derived)) })
}
