// Copyright 2024 International Digital Economy Academy
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

fn new_node[K, V](key : K, value : V) -> Node[K, V] {
  { key, value, left: None, right: None, height: 1 }
}

fn op_equal[K : Eq, V](self : Node[K, V], other : Node[K, V]) -> Bool {
  self.key == other.key
}

fn max(x : Int, y : Int) -> Int {
  if x > y {
    x
  } else {
    y
  }
}

fn height[K, V](node : Node[K, V]?) -> Int {
  match node {
    None => 0
    Some(n) => n.height
  }
}

fn debug_node[K : Show, V : Show](self : Node[K, V]) -> String {
  let l = match self.left {
    Some(left) => left.debug_node()
    None => "_"
  }
  let r = match self.right {
    Some(right) => right.debug_node()
    None => "_"
  }
  let key = self.key
  let value = self.value
  let height = self.height
  "([\(height)]\(key),\(value),\(l),\(r))"
}

fn debug_tree[K : Show, V : Show](self : T[K, V]) -> String {
  match self.root {
    Some(root) => root.debug_node()
    None => "_"
  }
}

pub impl[K : Show, V : Show] Show for T[K, V] with output(self, logger) {
  logger.write_string("@sorted_map.of([")
  self.eachi(
    fn(i, k, v) {
      if i > 0 {
        logger.write_string(", ")
      }
      logger.write_string("(")
      Show::output(k, logger)
      logger.write_string(", ")
      Show::output(v, logger)
      logger.write_string(")")
    },
  )
  logger.write_string("])")
}

pub fn to_string[K : Show, V : Show](self : T[K, V]) -> String {
  Show::to_string(self)
}
