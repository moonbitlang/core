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
fn[K, V] new_node(key : K, value : V) -> Node[K, V] {
  { key, value, left: None, right: None, height: 1 }
}

///|
impl[K : Eq, V] Eq for Node[K, V] with equal(self, other) {
  self.key == other.key
}

///|
fn max(x : Int, y : Int) -> Int {
  if x > y {
    x
  } else {
    y
  }
}

///|
fn[K, V] height(node : Node[K, V]?) -> Int {
  match node {
    None => 0
    Some(n) => n.height
  }
}

///|
fn[K : Show, V : Show] Node::debug_node(self : Node[K, V]) -> String {
  let l = match self.left {
    Some(left) => left.debug_node()
    None => "_"
  }
  let r = match self.right {
    Some(right) => right.debug_node()
    None => "_"
  }
  "([\{self.height}]\{self.key},\{self.value},\{l},\{r})"
}

///|
fn[K : Show, V : Show] SortedMap::debug_tree(self : SortedMap[K, V]) -> String {
  match self.root {
    Some(root) => root.debug_node()
    None => "_"
  }
}

///|
pub impl[K : Show, V : Show] Show for SortedMap[K, V] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@sorted_map.from_array([", suffix="])")
}

///|
pub impl[K : Show, V : ToJson] ToJson for SortedMap[K, V] with to_json(self) {
  let capacity = self.length()
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
      (path, "@sorted_map.from_json: expected object"),
    )
  }
  let map = new()
  for k, v in obj {
    map.set(k, V::from_json(v, path.add_key(k)))
  }
  map
}
