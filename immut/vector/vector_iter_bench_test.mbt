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
let vector_iter_bench_size = 100_000

///|
fn make_vector_iter_bench_vector() -> @vector.Vector[Int] {
  @vector.from_iter((0).until(vector_iter_bench_size))
}

///|
test "bench Vector::iter fold n=100000" (it : @bench.T) {
  let data = make_vector_iter_bench_vector()
  it.bench(fn() { it.keep(data.iter().fold(init=0, (sum, x) => sum + x)) })
}

///|
test "bench Vector::iter each n=100000" (it : @bench.T) {
  let data = make_vector_iter_bench_vector()
  it.bench(fn() {
    let mut sum = 0
    data.iter().each(x => sum += x)
    it.keep(sum)
  })
}

///|
test "bench Vector::iter to_array n=100000" (it : @bench.T) {
  let data = make_vector_iter_bench_vector()
  it.bench(fn() { it.keep(data.iter().to_array()) })
}

///|
test "bench Vector::for-in n=100000" (it : @bench.T) {
  let data = make_vector_iter_bench_vector()
  it.bench(fn() {
    let sum = for x in data; sum = 0 {
      continue sum + x
    } nobreak {
      sum
    }
    it.keep(sum)
  })
}
