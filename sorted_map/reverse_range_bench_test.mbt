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
test "reverse iter n=16384" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(() => it.keep(map.rev_iter().fold(init=0, (sum, p) => sum + p.1)))
}

///|
test "reverse keys n=16384" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(() => it.keep(map.rev_keys().fold(init=0, (sum, k) => sum + k)))
}

///|
test "reverse values n=16384" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(() => it.keep(map.rev_values().fold(init=0, (sum, v) => sum + v)))
}

///|
test "range bounds middle n=8192" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(() => {
    it.keep(
      map
      .range_bounds(Included(4096), Excluded(12288))
      .iter()
      .fold(init=0, (sum, p) => sum + p.1),
    )
  })
}

///|
test "reverse range bounds middle n=8192" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(() => {
    it.keep(
      map
      .rev_range_bounds(Included(4096), Excluded(12288))
      .iter()
      .fold(init=0, (sum, p) => sum + p.1),
    )
  })
}

///|
test "range bounds unbounded n=16384" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(() => {
    it.keep(
      map
      .range_bounds(Unbounded, Unbounded)
      .iter()
      .fold(init=0, (sum, p) => sum + p.1),
    )
  })
}

///|
test "reverse range bounds unbounded n=16384" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(() => {
    it.keep(
      map
      .rev_range_bounds(Unbounded, Unbounded)
      .iter()
      .fold(init=0, (sum, p) => sum + p.1),
    )
  })
}

///|
test "reverse iter take n=8" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(() => {
    it.keep(map.rev_iter().take(8).fold(init=0, (sum, p) => sum + p.1))
  })
}

///|
test "range bounds take n=8" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(() => {
    it.keep(
      map
      .range_bounds(Included(4096), Excluded(12288))
      .iter()
      .take(8)
      .fold(init=0, (sum, p) => sum + p.1),
    )
  })
}

///|
test "reverse range bounds take n=8" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(() => {
    it.keep(
      map
      .rev_range_bounds(Included(4096), Excluded(12288))
      .iter()
      .take(8)
      .fold(init=0, (sum, p) => sum + p.1),
    )
  })
}

///|
test "forward iter n=16384 control" (it : @bench.T) {
  let map = iter_bench_map()
  it.bench(() => it.keep(map.iter().fold(init=0, (sum, p) => sum + p.1)))
}
