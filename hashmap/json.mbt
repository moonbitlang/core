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
pub impl[K : Show, V : ToJson] ToJson for HashMap[K, V] with fn to_json(self) {
  Json::object(
    Map(
      capacity=self.capacity,
      [
        for k, v in self => (k.to_string(), v.to_json())
      ],
    ),
  )
}

///|
/// Decodes a `HashMap[String, V]` from a JSON object.
///
/// Each key in the JSON object becomes a `String` key in the map, and each
/// value is decoded using `V`'s `FromJson` implementation.
///
/// Example:
///
/// ```mbt check
/// test {
///   let m : @hashmap.HashMap[String, Int] = @json.from_json(
///     { "a": 1, "b": 2 }.to_json(),
///   )
///   debug_inspect(m.get("a"), content="Some(1)")
///   debug_inspect(m.get("b"), content="Some(2)")
/// }
/// ```
pub impl[V : @json.FromJson] @json.FromJson for HashMap[String, V] with from_json(
  json,
  path,
) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError((path, "HashMap::from_json: expected object"))
  }
  let res : HashMap[String, V] = HashMap([])
  for k, v in obj {
    res[k] = @json.FromJson::from_json(v, path.add_key(k))
  }
  res
}
