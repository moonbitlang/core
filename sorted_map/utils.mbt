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
fn[K : Show, V : Show] debug_node(self : Node[K, V]) -> String {
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
fn[K : Show, V : Show] debug_tree(self : SortedMap[K, V]) -> String {
  match self.root {
    Some(root) => root.debug_node()
    None => "_"
  }
}

///|
pub impl[K : Show, V : Show] Show for SortedMap[K, V] with output(self, logger) {
  logger.write_iter(self.iter(), prefix="@sorted_map.of([", suffix="])")
}
