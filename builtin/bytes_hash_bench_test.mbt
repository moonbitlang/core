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
fn make_bytes_hash_bench_bytes(length : Int) -> Bytes {
  Bytes::makei(length, i => ((i * 37 + 11) & 0xff).to_byte())
}

///|
let bytes_hash_bench_map_size = 1024

///|
fn make_bytes_hash_bench_map_keys() -> Array[Bytes] {
  Array::makei(bytes_hash_bench_map_size, i => {
    Bytes::makei(32, j => {
      if j == 0 {
        (i & 0xff).to_byte()
      } else if j == 1 {
        (i >> 8).to_byte()
      } else {
        ((i * 17 + j * 37 + 11) & 0xff).to_byte()
      }
    })
  })
}

///|
fn make_bytes_hash_bench_map(keys : Array[Bytes]) -> Map[Bytes, Int] {
  let map : Map[Bytes, Int] = Map([], capacity=bytes_hash_bench_map_size * 2)
  for i in 0..<keys.length() {
    map.set(keys[i], i)
  }
  map
}

///|
test "bytes hash bench map keys are distinct" {
  let keys = make_bytes_hash_bench_map_keys()
  assert_eq(make_bytes_hash_bench_map(keys).length(), bytes_hash_bench_map_size)
}

///|
test "bench Hash::hash(Bytes) n=32" (it : @bench.T) {
  let bytes = make_bytes_hash_bench_bytes(32)
  it.bench(fn() { it.keep(Hash::hash(bytes)) })
}

///|
test "bench Hash::hash(Bytes) n=8192" (it : @bench.T) {
  let bytes = make_bytes_hash_bench_bytes(8192)
  it.bench(fn() { it.keep(Hash::hash(bytes)) })
}

///|
test "bench Map::at Bytes n=1024 key_bytes=32" (it : @bench.T) {
  let keys = make_bytes_hash_bench_map_keys()
  let map = make_bytes_hash_bench_map(keys)
  it.bench(fn() {
    let mut sum = 0
    for key in keys {
      sum += map.at(key)
    }
    it.keep(sum)
  })
}
