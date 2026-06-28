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
let hashset_bench_n = 50000

///|
test "bench HashSet::add n=50000" (it : @bench.T) {
  it.bench(fn() {
    let s : @hashset.HashSet[Int] = HashSet([])
    for i in 0..<hashset_bench_n {
      s.add(i * 1103515245)
    }
    it.keep(s.length())
  })
}

///|
test "bench HashSet::contains n=50000" (it : @bench.T) {
  let s : @hashset.HashSet[Int] = HashSet([])
  for i in 0..<hashset_bench_n {
    s.add(i * 1103515245)
  }
  it.bench(fn() {
    let mut hits = 0
    for i in 0..<hashset_bench_n {
      if s.contains(i * 1103515245) {
        hits += 1
      }
    }
    it.keep(hits)
  })
}
