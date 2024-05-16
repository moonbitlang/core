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

/// Create a new map with a key-value pair inserted.
/// O(log n).
pub fn insert[K : Compare, V](
  self : Map[K, V],
  key : K,
  value : V
) -> Map[K, V] {
  match self {
    Empty => singleton(key, value)
    Tree(k, value=v, l, r, ..) =>
      match key.compare(k) {
        -1 => balance(k, v, insert(l, key, value), r)
        1 => balance(k, v, l, insert(r, key, value))
        _ => new(k, value, l, r)
      }
  }
}

fn split_max[K : Compare, V](self : Map[K, V]) -> (K, V, Map[K, V]) {
  match self {
    Tree(k, value=v, l, Empty, ..) => (k, v, l)
    Tree(k, value=v, l, r, ..) => {
      let (k1, v1, r) = split_max(r)
      (k1, v1, balance(k, v, l, r))
    }
    Empty => abort("Map::split_max error")
  }
}

fn split_min[K : Compare, V](self : Map[K, V]) -> (K, V, Map[K, V]) {
  match self {
    Tree(k, value=v, Empty, r, ..) => (k, v, r)
    Tree(k, value=v, l, r, ..) => {
      let (k1, v1, l) = split_min(l)
      (k1, v1, balance(k, v, l, r))
    }
    Empty => abort("Map::split_min error")
  }
}

fn glue[K : Compare, V](self : Map[K, V], other : Map[K, V]) -> Map[K, V] {
  match (self, other) {
    (Empty, r) => r
    (l, Empty) => l
    (l, r) =>
      if l.size() > r.size() {
        let (k, v, l) = split_max(l)
        balance(k, v, l, r)
      } else {
        let (k, v, r) = split_min(r)
        balance(k, v, l, r)
      }
  }
}

/// Create a new map with a key-value pair removed. O(log n).
/// If the key is not a member or map, the original map is returned.
pub fn remove[K : Compare, V](self : Map[K, V], key : K) -> Map[K, V] {
  match self {
    Empty => Empty
    Tree(k, value=v, l, r, ..) => {
      let c = key.compare(k)
      if c == 0 {
        glue(l, r)
      } else if c < 0 {
        balance(k, v, remove(l, key), r)
      } else {
        balance(k, v, l, remove(r, key))
      }
    }
  }
}

/// Filter values that satisfy the predicate
pub fn filter[K : Compare, V](
  self : Map[K, V],
  pred : (V) -> Bool
) -> Map[K, V] {
  filter_with_key(self, fn(_k, v) { pred(v) })
}

/// Filter key-value pairs that satisfy the predicate
pub fn filter_with_key[K : Compare, V](
  self : Map[K, V],
  pred : (K, V) -> Bool
) -> Map[K, V] {
  match self {
    Empty => Empty
    Tree(k, value=v, l, r, ..) =>
      if pred(k, v) {
        balance(k, v, filter_with_key(l, pred), filter_with_key(r, pred))
      } else {
        glue(filter_with_key(l, pred), filter_with_key(r, pred))
      }
  }
}

/// Convert to a vector of key-value pairs.
pub fn to_vec[K, V](self : Map[K, V]) -> @vec.Vec[(K, V)] {
  let vec = @vec.new()
  self.iter(fn(k, v) { vec.push((k, v)) })
  vec
}

pub fn op_equal[K : Eq, V : Eq](self : Map[K, V], other : Map[K, V]) -> Bool {
  self.to_vec() == other.to_vec()
}

/// The ratio between the sizes of the left and right subtrees.
let ratio = 5

fn balance[K : Compare, V](
  key : K,
  value : V,
  l : Map[K, V],
  r : Map[K, V]
) -> Map[K, V] {
  //       1                   2
  //      / \                 / \
  //     x   2       --->    1   z
  //        / \             / \
  //       y   z           x   y
  fn single_l {
    k1, v1, x, Map::Tree(k2, value=v2, y, z, ..) =>
      new(k2, v2, new(k1, v1, x, y), z)
    _, _, _, _ => abort("single_l error")
  }

  fn single_r {
    k2, v2, Map::Tree(k1, value=v1, x, y, ..), z =>
      new(k1, v1, x, new(k2, v2, y, z))
    _, _, _, _ => abort("single_r error")
  }

  //      1                 2
  //     / \              /   \
  //    x   3            1     3
  //       / \    -->   / \   / \
  //      2   z        x  y1 y2  z
  //     / \
  //    y1 y2
  fn double_l {
    k1, v1, x, Map::Tree(k3, value=v3, Tree(k2, value=v2, y1, y2, ..), z, ..) =>
      new(k2, v2, new(k1, v1, x, y1), new(k3, v3, y2, z))
    _, _, _, _ => abort("double_l error")
  }

  //      3                 2
  //     / \              /   \
  //    1   z            1     3
  //   / \        -->   / \   / \
  //  x  2             x  y1 y2  z
  //    / \
  //   y1 y2
  fn double_r {
    k3, v3, Map::Tree(k1, value=v1, x, Tree(k2, value=v2, y1, y2, ..), ..), z =>
      new(k2, v2, new(k1, v1, x, y1), new(k3, v3, y2, z))
    _, _, _, _ => abort("double_r error")
  }

  let ln = size(l)
  let rn = size(r)
  if ln + rn < 2 {
    new(key, value, l, r)
  } else if rn > ratio * ln {
    // right is too big
    let (rl, rr) = match r {
      Tree(_, rl, rr, ..) => (rl, rr)
      Empty => abort("unreachable")
    }
    let rln = size(rl)
    let rrn = size(rr)
    if rln < rrn {
      single_l(key, value, l, r)
    } else {
      double_l(key, value, l, r)
    }
  } else if ln > ratio * rn {
    // left is too big
    let (ll, lr) = match l {
      Tree(_, ll, lr, ..) => (ll, lr)
      Empty => abort("unreachable")
    }
    let lln = size(ll)
    let lrn = size(lr)
    if lrn < lln {
      single_r(key, value, l, r)
    } else {
      double_r(key, value, l, r)
    }
  } else {
    new(key, value, l, r)
  }
}
