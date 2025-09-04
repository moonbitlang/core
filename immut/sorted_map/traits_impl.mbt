// Copyright 2025 International Digital Economy Academy
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
pub impl[K, V] Default for SortedMap[K, V] with default() {
  new()
}

///|
pub impl[K : Eq, V : Eq] Eq for SortedMap[K, V] with equal(self, other) -> Bool {
  let iter = InorderIterator::new(self)
  let iter1 = InorderIterator::new(other)
  loop (iter.next(), iter1.next()) {
    (None, None) => true
    (Some(a), Some(b)) => {
      guard a == b else { break false }
      continue (iter.next(), iter1.next())
    }
    (_, _) => false
  }
}

///|
pub impl[K : Compare, V : Compare] Compare for SortedMap[K, V] with compare(
  self,
  other,
) -> Int {
  let iter = InorderIterator::new(self)
  let iter1 = InorderIterator::new(other)
  loop (iter.next(), iter1.next()) {
    (None, None) => 0
    (Some(a), Some(b)) => {
      let cmp = a.compare(b)
      guard cmp == 0 else { break cmp }
      continue (iter.next(), iter1.next())
    }
    (Some(_), None) => 1
    (None, Some(_)) => -1
  }
}

///|
pub impl[K : @quickcheck.Arbitrary + Compare, V : @quickcheck.Arbitrary] @quickcheck.Arbitrary for SortedMap[
  K,
  V,
] with arbitrary(size, rs) {
  @quickcheck.Arbitrary::arbitrary(size, rs) |> from_array
}

///|
pub impl[K : Hash, V : Hash] Hash for SortedMap[K, V] with hash_combine(
  self,
  hasher,
) {
  for e in self {
    hasher..combine(e.0)..combine(e.1)
  }
}

///|
pub impl[K : Show, V : Show] Show for SortedMap[K, V] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@immut/sorted_map.of([", suffix="])")
}

///|
pub impl[K : Show, V : ToJson] ToJson for SortedMap[K, V] with to_json(self) {
  let capacity = self.size()
  guard capacity != 0 else { return Json::object(Map::new()) }
  let jsons = Map::new(capacity~)
  self.each((k, v) => jsons[k.to_string()] = v.to_json())
  Json::object(jsons)
}

///|
pub impl[V : @json.FromJson] @json.FromJson for SortedMap[String, V] with from_json(
  json,
  path,
) {
  guard json is Object(obj) else {
    raise @json.JsonDecodeError(
      (path, "@immut/sorted_map.from_json: expected object"),
    )
  }
  let mut map = new()
  for k, v in obj {
    map = map.add(k, V::from_json(v, path.add_key(k)))
  }
  map
}

///|
#as_free_fn
pub fn[V : @json.FromJson] SortedMap::from_json(
  json : Json,
) -> SortedMap[String, V] raise @json.JsonDecodeError {
  @json.from_json(json)
}
