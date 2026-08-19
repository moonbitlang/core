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
/// A document whose strings all need escaping, so that `stringify` spends its
/// time in the escaping path rather than in `Map` iteration.
fn escape_heavy_doc(count : Int) -> Json {
  let items = []
  for i in 0..<count {
    items.push(
      (
        {
          "name": "item \{i} with \"quotes\" and \\ backslashes",
          "path": "/usr/local/share/item/\{i}",
          "note": "line\nbreak\ttab",
          "n": Json::number(i.to_double()),
        } : Json),
    )
  }
  { "items": Json::array(items) }
}

///|
test "bench json stringify escape-heavy n=200" (it : @bench.T) {
  let doc = escape_heavy_doc(200)
  it.bench(() => it.keep(doc.stringify()))
}

///|
test "bench json stringify escape-heavy indent=2 n=200" (it : @bench.T) {
  let doc = escape_heavy_doc(200)
  it.bench(() => it.keep(doc.stringify(indent=2)))
}
