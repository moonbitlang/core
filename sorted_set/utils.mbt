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

fn op_equal[V : Eq](self : Node[V], other : Node[V]) -> Bool {
  self.value == other.value
}

fn max(x : Int, y : Int) -> Int {
  if x > y {
    x
  } else {
    y
  }
}

fn height[V](node : Node[V]?) -> Int {
  match node {
    None => 0
    Some(n) => n.height
  }
}

fn debug_node[V : Show](self : Node[V]) -> String {
  let l = match self.left {
    Some(left) => left.debug_node()
    None => "_"
  }
  let r = match self.right {
    Some(right) => right.debug_node()
    None => "_"
  }
  let value = self.value
  let height = self.height
  "([\(height)]\(value),\(l),\(r))"
}

fn debug_tree[V : Show](self : T[V]) -> String {
  match self.root {
    Some(root) => root.debug_node()
    None => "_"
  }
}
