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

/// Convert to an array of key-value pairs.
pub fn to_array[K, V](self : Map[K, V]) -> Array[(K, V)] {
  let arr = []
  self.each(fn(k, v) { arr.push((k, v)) })
  arr
}

pub fn op_equal[K : Eq, V : Eq](self : Map[K, V], other : Map[K, V]) -> Bool {
  self.to_array() == other.to_array()
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

test "from_array" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  inspect(
    m.debug_tree(),
    content="(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )!
}

test "insert" {
  let m = of([(3, "three"), (8, "eight"), (1, "one")])
  inspect!(m.debug_tree(), content="(3,three,(1,one,_,_),(8,eight,_,_))")
  let m = m.insert(5, "five").insert(2, "two").insert(0, "zero").insert(
    1, "one_updated",
  )
  inspect(
    m.debug_tree(),
    content="(3,three,(1,one_updated,(0,zero,_,_),(2,two,_,_)),(8,eight,(5,five,_,_),_))",
  )!
}

test "remove" {
  let m1 = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  inspect(
    m1.debug_tree(),
    content="(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )!
  let m2 = m1.remove(1).remove(3)
  inspect!(m2.debug_tree(), content="(2,two,(0,zero,_,_),(8,eight,_,_))")
  let m3 = m1.remove(8)
  inspect(
    m3.debug_tree(),
    content="(2,two,(1,one,(0,zero,_,_),_),(3,three,_,_))",
  )!
  let e : Map[Int, Int] = Empty
  inspect!(e.remove(1).debug_tree(), content="_")
}

test "contains" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  inspect(
    m.debug_tree(),
    content="(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )!
  @test.eq(m.contains(8), true)!
  @test.eq(m.contains(2), true)!
  @test.eq(m.contains(4), false)!
}

test "map" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let n = m.map(fn(v) { v + "X" })
  @test.eq(
    n.debug_tree(),
    "(3,threeX,(1,oneX,(0,zeroX,_,_),(2,twoX,_,_)),(8,eightX,_,_))",
  )!
}

test "map_with_key" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let n = m.map_with_key(fn(k, v) { "\(k)-\(v)" })
  @test.eq(
    n.debug_tree(),
    "(3,3-three,(1,1-one,(0,0-zero,_,_),(2,2-two,_,_)),(8,8-eight,_,_))",
  )!
}

test "filter" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let fm = m.filter(fn(v) { v.length() > 3 })
  @test.eq(fm.debug_tree(), "(3,three,(0,zero,_,_),(8,eight,_,_))")!
}

test "filter_with_key" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let fm = m.filter_with_key(fn(k, v) { k > 3 && v.length() > 3 })
  @test.eq(fm.debug_tree(), "(8,eight,_,_)")!
}

test "singleton" {
  let m = singleton(3, "three")
  @test.eq(m.debug_tree(), "(3,three,_,_)")!
}

test "insert" {
  let m = of([(3, "three"), (8, "eight"), (1, "one")])
  inspect!(m.debug_tree(), content="(3,three,(1,one,_,_),(8,eight,_,_))")
  let m = m.insert(5, "five").insert(2, "two").insert(0, "zero").insert(
    1, "one_updated",
  )
  inspect(
    m.debug_tree(),
    content="(3,three,(1,one_updated,(0,zero,_,_),(2,two,_,_)),(8,eight,(5,five,_,_),_))",
  )!
}

test "remove" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  inspect(
    m.debug_tree(),
    content="(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )!
  let m = m.remove(1).remove(3)
  @test.eq(m.debug_tree(), "(2,two,(0,zero,_,_),(8,eight,_,_))")!
}

test "filter" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let fm = m.filter(fn(v) { v.length() > 3 })
  @test.eq(fm.debug_tree(), "(3,three,(0,zero,_,_),(8,eight,_,_))")!
}

test "filter_with_key" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let fm = m.filter_with_key(fn(k, v) { k > 3 && v.length() > 3 })
  @test.eq(fm.debug_tree(), "(8,eight,_,_)")!
}

test "empty" {
  let m : Map[Int, Int] = empty()
  @test.eq(m.debug_tree(), "_")!
}

test "split_max" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  @test.eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )!
  let (k, v, r) = m.split_max()
  @test.eq(k, 8)!
  @test.eq(v, "eight")!
  @test.eq(r.debug_tree(), "(2,two,(1,one,(0,zero,_,_),_),(3,three,_,_))")!
}

test "split_min" {
  let m = of([(3, "three"), (8, "eight"), (2, "two"), (1, "one"), (0, "zero")])
  @test.eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )!
  let (k, v, r) = m.split_min()
  @test.eq(k, 0)!
  @test.eq(v, "zero")!
  @test.eq(r.debug_tree(), "(3,three,(1,one,_,(2,two,_,_)),(8,eight,_,_))")!
}

test "glue" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  @test.eq(
    m.debug_tree(),
    "(3,three,(1,one,(0,zero,_,_),(2,two,_,_)),(8,eight,_,_))",
  )!
  let (l, r) = match m {
    Tree(_, l, r, ..) => (l, r)
    _ => abort("unreachable")
  }
  let m = l.glue(r)
  @test.eq(m.debug_tree(), "(2,two,(1,one,(0,zero,_,_),_),(8,eight,_,_))")!
}

test "split_max with non-empty tree" {
  let m = of([(3, "three"), (8, "eight"), (1, "one"), (2, "two"), (0, "zero")])
  let (k, v, r) = m.split_max()
  inspect!(k, content="8")
  inspect!(v, content="eight")
  inspect(
    r.debug_tree(),
    content="(2,two,(1,one,(0,zero,_,_),_),(3,three,_,_))",
  )!
}

test "panic split_max with empty tree" {
  (Empty : Map[Int, Int]).split_max() |> ignore
}

test "panic split_min with empty tree" {
  (Empty : Map[Int, Int]).split_min() |> ignore
}
