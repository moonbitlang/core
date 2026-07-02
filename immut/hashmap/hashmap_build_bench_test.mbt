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
let hashmap_build_bench_size = 10_000

///|
fn hashmap_build_random_key(i : Int) -> Int {
  (i * 1103515245 + 12345) & 0x7fffffff
}

///|
fn make_hashmap_ordered_build_data() -> Array[(Int, Int)] {
  Array::makei(hashmap_build_bench_size, i => (i, i))
}

///|
fn make_hashmap_random_build_data() -> Array[(Int, Int)] {
  Array::makei(hashmap_build_bench_size, i => {
    let key = hashmap_build_random_key(i)
    (key, i)
  })
}

///|
test "bench HashMap constructor ordered n=10000" (it : @bench.T) {
  let data = make_hashmap_ordered_build_data()
  it.bench(fn() { it.keep(@hashmap.HashMap(data)) })
}

///|
test "bench HashMap constructor random n=10000" (it : @bench.T) {
  let data = make_hashmap_random_build_data()
  it.bench(fn() { it.keep(@hashmap.HashMap(data)) })
}

///|
test "bench HashMap::from_iter random n=10000" (it : @bench.T) {
  let data = make_hashmap_random_build_data()
  it.bench(fn() { it.keep(@hashmap.from_iter(data.iter())) })
}
