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
fn make_deep_wide_json() -> Json {
  let mut value = Array::makei(10000, i => Json::number(i.to_double())).to_json()
  for _ in 0..<6 {
    value = Json::array([value])
  }
  value
}

///|
/// A document shaped like ordinary API/config output: a few hundred small
/// objects nested four deep. Unlike `make_deep_wide_json`, this does not park
/// every separator past the old 8-space lookup cutoff, so it reflects what
/// pretty-printing actually costs on realistic input.
fn make_shallow_wide_json() -> Json {
  let rows = Array::makei(500, i => {
    let row : Json = {
      "id": Json::number(i.to_double()),
      "name": Json::string("item-\{i}"),
      "meta": {
        "active": Json::boolean(i % 2 == 0),
        "score": Json::number(1.5),
      },
    }
    row
  })
  { "items": rows.to_json(), "total": Json::number(500.0) }
}

///|
test "bench Json::stringify deep wide indent=2 n=10000" (it : @bench.T) {
  let json = make_deep_wide_json()
  it.bench(fn() { it.keep(json.stringify(indent=2).length()) })
}

///|
/// The default, and by far the most common, path. The indentation cache is
/// never consulted here, so this guards the compact path against regressions
/// from indentation work.
test "bench Json::stringify compact n=10000" (it : @bench.T) {
  let json = make_deep_wide_json()
  it.bench(fn() { it.keep(json.stringify().length()) })
}

///|
test "bench Json::stringify shallow wide indent=2 n=500" (it : @bench.T) {
  let json = make_shallow_wide_json()
  it.bench(fn() { it.keep(json.stringify(indent=2).length()) })
}

///|
test "bench Json::stringify shallow wide compact n=500" (it : @bench.T) {
  let json = make_shallow_wide_json()
  it.bench(fn() { it.keep(json.stringify().length()) })
}
