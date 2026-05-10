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
let contains_bench_size = 100_000

///|
fn make_contains_bench_vector() -> @vector.Vector[Int] {
  @vector.from_iter((0).until(contains_bench_size))
}

///|
test "bench Vector::contains missing n=100000" (it : @bench.T) {
  let data = make_contains_bench_vector()
  it.bench(fn() { it.keep(data.contains(-1)) })
}

///|
test "bench Vector::contains tree-end n=100000" (it : @bench.T) {
  let data = make_contains_bench_vector()
  it.bench(fn() { it.keep(data.contains(contains_bench_size - 33)) })
}

///|
test "bench Vector::contains tail-end n=100000" (it : @bench.T) {
  let data = make_contains_bench_vector()
  it.bench(fn() { it.keep(data.contains(contains_bench_size - 1)) })
}
