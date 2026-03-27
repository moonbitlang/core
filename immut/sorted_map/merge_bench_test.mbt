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
fn make_map(
  start : Int,
  end : Int,
  step? : Int = 1,
) -> @sorted_map.SortedMap[Int, Int] {
  let mut m : @sorted_map.SortedMap[Int, Int] = @sorted_map.new()
  for i = start; i < end; i = i + step {
    m = m.add(i, i)
  }
  m
}

///|
test "bench merge disjoint n=1000" (it : @bench.T) {
  let m1 = make_map(0, 1000)
  let m2 = make_map(1000, 2000)
  it.bench(fn() { it.keep(m1.merge(m2)) })
}

///|
test "bench merge disjoint n=5000" (it : @bench.T) {
  let m1 = make_map(0, 5000)
  let m2 = make_map(5000, 10000)
  it.bench(fn() { it.keep(m1.merge(m2)) })
}

///|
test "bench merge disjoint n=10000" (it : @bench.T) {
  let m1 = make_map(0, 10000)
  let m2 = make_map(10000, 20000)
  it.bench(fn() { it.keep(m1.merge(m2)) })
}

///|
test "bench merge overlapping 50% n=1000" (it : @bench.T) {
  let m1 = make_map(0, 1000)
  let m2 = make_map(500, 1500)
  it.bench(fn() { it.keep(m1.merge(m2)) })
}

///|
test "bench merge overlapping 50% n=5000" (it : @bench.T) {
  let m1 = make_map(0, 5000)
  let m2 = make_map(2500, 7500)
  it.bench(fn() { it.keep(m1.merge(m2)) })
}

///|
test "bench merge overlapping 50% n=10000" (it : @bench.T) {
  let m1 = make_map(0, 10000)
  let m2 = make_map(5000, 15000)
  it.bench(fn() { it.keep(m1.merge(m2)) })
}

///|
test "bench merge identical n=1000" (it : @bench.T) {
  let m1 = make_map(0, 1000)
  let m2 = make_map(0, 1000)
  it.bench(fn() { it.keep(m1.merge(m2)) })
}

///|
test "bench merge identical n=5000" (it : @bench.T) {
  let m1 = make_map(0, 5000)
  let m2 = make_map(0, 5000)
  it.bench(fn() { it.keep(m1.merge(m2)) })
}

///|
test "bench merge interleaved n=1000" (it : @bench.T) {
  let m1 = make_map(0, 2000, step=2)
  let m2 = make_map(1, 2000, step=2)
  it.bench(fn() { it.keep(m1.merge(m2)) })
}

///|
test "bench merge interleaved n=5000" (it : @bench.T) {
  let m1 = make_map(0, 10000, step=2)
  let m2 = make_map(1, 10000, step=2)
  it.bench(fn() { it.keep(m1.merge(m2)) })
}

///|
test "bench merge small into large n=100+10000" (it : @bench.T) {
  let m1 = make_map(0, 10000)
  let m2 = make_map(5000, 5100)
  it.bench(fn() { it.keep(m1.merge(m2)) })
}
