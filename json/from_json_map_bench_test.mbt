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
fn from_json_map_bench_input(size : Int32) -> Json {
  // Building from an array gives the fixture the same bucket count with
  // either interpretation of the optional capacity hint.
  Json::object(
    Map([ for i in 0..<size => (i.to_string(), Json::number(i.to_double())) ]),
  )
}

///|
test "bench Map::from_json entries=10000" (it : @bench.T) {
  let input = from_json_map_bench_input(10000)
  it.bench(fn() {
    let decoded : Map[String, Int32] = try! @json.from_json(input)
    it.keep(decoded.length())
  })
}

///|
test "bench Map::from_json entries=100000" (it : @bench.T) {
  let input = from_json_map_bench_input(100000)
  it.bench(fn() {
    let decoded : Map[String, Int32] = try! @json.from_json(input)
    it.keep(decoded.length())
  })
}

///|
// These sizes cross the 13/16 load threshold of the next power-of-two
// bucket count, so a hint interpreted as a bucket count still rehashes.
test "bench Map::from_json entries=15000" (it : @bench.T) {
  let input = from_json_map_bench_input(15000)
  it.bench(fn() {
    let decoded : Map[String, Int32] = try! @json.from_json(input)
    it.keep(decoded.length())
  })
}

///|
test "bench Map::from_json entries=120000" (it : @bench.T) {
  let input = from_json_map_bench_input(120000)
  it.bench(fn() {
    let decoded : Map[String, Int32] = try! @json.from_json(input)
    it.keep(decoded.length())
  })
}

///|
// Clearing preserves the 131072 buckets of the 65536-entry source. Construct
// it without a capacity hint to keep the baseline and candidate identical.
test "bench Map::from_json entries=100 source_capacity=131072" (it : @bench.T) {
  let object : Map[String, Json] = Map(
    [
      for i in 0..<65536 => (i.to_string(), Json::number(i.to_double()))
    ],
  )
  object.clear()
  for i in 0..<100 {
    object[i.to_string()] = Json::number(i.to_double())
  }
  assert_eq(object.capacity(), 131072)
  let input = Json::object(object)
  it.bench(fn() {
    let decoded : Map[String, Int32] = try! @json.from_json(input)
    it.keep(decoded.length())
  })
}
