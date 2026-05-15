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
let parse_bench_item =
  #|{
  #|  "id": 123456,
  #|  "name": "item-123456",
  #|  "price": 123456.125,
  #|  "ratio": 457e-3,
  #|  "active": true,
  #|  "tags": ["alpha", "beta", "gamma"],
  #|  "meta": {
  #|    "count": 370368,
  #|    "note": null
  #|  }
  #|}

///|
fn repeat_parse_bench_item(count : Int) -> String {
  let buf = StringBuilder(size_hint=count * parse_bench_item.length())
  buf.write_char('[')
  for i in 0..<count {
    if i > 0 {
      buf.write_char(',')
    }
    buf.write_string(parse_bench_item)
  }
  buf.write_char(']')
  buf.to_string()
}

///|
test "bench json parse mixed object array n=1000" (it : @bench.T) {
  let input = repeat_parse_bench_item(1000)
  it.bench(fn() { it.keep(try! @json.parse(input)) })
}
