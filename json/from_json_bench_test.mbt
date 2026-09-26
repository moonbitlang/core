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
let from_json_bench_nested : Json = Json(
  Array::makei(500, i => Array::makei(50, j => i * 50 + j)),
)

///|
let from_json_bench_doubles : Json = Json(
  Array::makei(10000, i => i.to_double() * 0.5),
)

///|
let from_json_bench_object : Json = Json(
  Map::from_array(Array::makei(1000, i => ("key\{i}", i))),
)

///|
test "bench from_json Array[Array[Int]] 500x50" (it : @bench.T) {
  it.bench(fn() {
    let v : Array[Array[Int]] = @json.from_json(from_json_bench_nested) catch {
      _ => []
    }
    it.keep(v)
  })
}

///|
test "bench from_json Array[Double] n=10000" (it : @bench.T) {
  it.bench(fn() {
    let v : Array[Double] = @json.from_json(from_json_bench_doubles) catch {
      _ => []
    }
    it.keep(v)
  })
}

///|
test "bench from_json Map[String, Int] n=1000" (it : @bench.T) {
  it.bench(fn() {
    let v : Map[String, Int] = @json.from_json(from_json_bench_object) catch {
      _ => {}
    }
    it.keep(v)
  })
}
