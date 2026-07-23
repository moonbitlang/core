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
let stringify_escape_bench_count = 2048

///|
fn make_stringify_escape_bench_array(value : String) -> Json {
  Array::makei(stringify_escape_bench_count, i => value + i.to_string()).to_json()
}

///|
test "bench Json::stringify strings no escape n=2048" (it : @bench.T) {
  let json = make_stringify_escape_bench_array("moonbit-core-json-value-")
  it.bench(fn() { it.keep(json.stringify().length()) })
}

///|
test "bench Json::stringify strings slash no escape n=2048" (it : @bench.T) {
  let json = make_stringify_escape_bench_array("moonbit/core/json/value/")
  it.bench(fn() { it.keep(json.stringify().length()) })
}

///|
test "bench Json::stringify strings slash escaped n=2048" (it : @bench.T) {
  let json = make_stringify_escape_bench_array("moonbit/core/json/value/")
  it.bench(fn() { it.keep(json.stringify(escape_slash=true).length()) })
}

///|
test "bench Json::stringify strings quotes controls n=2048" (it : @bench.T) {
  let json = make_stringify_escape_bench_array("moonbit\"core\\json\nvalue")
  it.bench(fn() { it.keep(json.stringify().length()) })
}
