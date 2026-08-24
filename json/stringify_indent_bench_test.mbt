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
test "bench Json::stringify deep wide indent=2 n=10000" (it : @bench.T) {
  let json = make_deep_wide_json()
  it.bench(fn() { it.keep(json.stringify(indent=2).length()) })
}
