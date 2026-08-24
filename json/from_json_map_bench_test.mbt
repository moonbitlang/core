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
fn from_json_map_bench_input(size : Int) -> Json {
  let object : Map[String, Json] = Map([], capacity=size)
  for i in 0..<size {
    object[i.to_string()] = Json::number(i.to_double())
  }
  Json::object(object)
}

///|
test "bench Map::from_json entries=10000" (it : @bench.T) {
  let input = from_json_map_bench_input(10000)
  it.bench(fn() {
    let decoded : Map[String, Int] = try! @json.from_json(input)
    it.keep(decoded.length())
  })
}

///|
test "bench Map::from_json entries=100000" (it : @bench.T) {
  let input = from_json_map_bench_input(100000)
  it.bench(fn() {
    let decoded : Map[String, Int] = try! @json.from_json(input)
    it.keep(decoded.length())
  })
}
