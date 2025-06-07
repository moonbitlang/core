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
fn[A : Eq] Node::contain(self : Node[A], key : A, path : Path) -> Bool {
  match (self, path) {
    (Flat(k, path_k), path) => path == path_k && key == k
    (Branch(sa), path) => {
      let idx = path.idx()
      sa.has(idx) && sa[idx].contain(key, path.next())
    }
    (Leaf(k1, r), _) => key == k1 || r.any(key.op_equal(_))
  }
}

///|
/// require: k1 != k2, p1 and p2 has the same length
fn[A] join_2(k1 : A, p1 : Path, k2 : A, p2 : Path) -> SpArr[Node[A]] {
  let idx1 = p1.idx()
  let idx2 = p2.idx()
  if idx1 == idx2 {
    let n = if p1.is_last() {
      Leaf(k2, @list.singleton(k1))
    } else {
      Branch(join_2(k1, p1.next(), k2, p2.next()))
    }
    @sparse_array.singleton(idx1, n)
  } else {
    let (n1, n2) = if p1.is_last() {
      (Leaf(k1, @list.empty()), Leaf(k2, @list.empty()))
    } else {
      (Flat(k1, p1.next()), Flat(k2, p2.next()))
    }
    @sparse_array.doubleton(idx1, n1, idx2, n2)
  }
}

///|
fn[A : Eq] Node::add(self : Node[A], key : A, path : Path) -> Node[A] {
  let node = self
  loop node, path, fn { x => x } {
    Flat(k, path_k), path, on_replaced =>
      if path == path_k && key == k {
        self
      } else {
        on_replaced(Branch(join_2(k, path_k, key, path)))
      }
    Branch(sa), path, on_replaced => {
      let idx = path.idx()
      if sa.has(idx) {
        continue sa[idx],
          path.next(),
          fn(r) { on_replaced(Branch(sa.replace(idx, r))) }
      } else {
        on_replaced(Branch(sa.add(idx, Flat(key, path.next()))))
      }
    }
    Leaf(k, r), _, on_replaced =>
      if key == k || r.any(key.op_equal(_)) {
        self
      } else {
        on_replaced(Leaf(key, r.add(k)))
      }
  }
}

///|
fn[A : Eq] Node::add_inplace(self : Node[A], key : A, path : Path) -> Node[A] {
  let node = self
  loop node, path, fn { x => x } {
    Flat(k, path_k), path, on_replaced =>
      if path == path_k && key == k {
        self
      } else {
        on_replaced(Branch(join_2(k, path_k, key, path)))
      }
    Branch(sa), path, on_replaced => {
      let idx = path.idx()
      if sa.has(idx) {
        continue sa[idx],
          path.next(),
          fn(r) {
            sa.replace_inplace(idx, r)
            self
          }
      } else {
        on_replaced(Branch(sa.add(idx, Flat(key, path.next()))))
      }
    }
    Leaf(k, r), _, on_replaced =>
      if key == k || r.any(key.op_equal(_)) {
        self
      } else {
        on_replaced(Leaf(key, r.add(k)))
      }
  }
}

///|
fn[A : Eq] Node::remove(self : Node[A], key : A, path : Path) -> Node[A]? {
  let node = self
  loop node, path, fn { x => x } {
    Flat(k, path_k), path, on_remove =>
      if path == path_k && key == k {
        on_remove(None)
      } else {
        Some(self)
      }
    Branch(sa), path, on_remove => {
      let idx = path.idx()
      guard sa.has(idx) else { return Some(self) }
      continue sa[idx],
        path.next(),
        fn(result) {
          let new_sa = match (result, sa.data) {
            (None, [_]) => return on_remove(None)
            (None, _) => sa.remove(idx)
            (Some(child), _) => sa.replace(idx, child)
          }
          match new_sa.data {
            [Flat(k, next)] =>
              on_remove(Some(Flat(k, next.push(new_sa.first_index()))))
            _ => on_remove(Some(Branch(new_sa)))
          }
        }
    }
    Leaf(k, r), _, on_remove =>
      if k == key {
        match r {
          Empty => on_remove(None)
          More(k2, tail~) => on_remove(Some(Leaf(k2, tail)))
        }
      } else if r.find_index(key.op_equal(_)) is Some(index) {
        on_remove(Some(Leaf(k, r.remove_at(index))))
      } else {
        Some(self)
      }
  }
}

///|
fn[A] Node::each(self : Node[A], f : (A) -> Unit) -> Unit {
  match self {
    Flat(k, _) => f(k)
    Leaf(k, r) => {
      f(k)
      r.each(f)
    }
    Branch(sa) => sa.each(_.each(f))
  }
}

///|
fn[A] Node::iter(self : Node[A]) -> Iter[A] {
  Iter::new(fn(yield_) {
    fn go {
      Flat(k, _) => yield_(k)
      Leaf(k, r) =>
        loop k, r {
          k, Empty => yield_(k)
          k, More(k2, tail~) => {
            guard yield_(k) is IterContinue else { return IterEnd }
            continue k2, tail
          }
        }
      Branch(sa) => {
        let data = sa.data
        let len_1 = sa.data.length() - 1
        for i in 0..<len_1 {
          guard go(sa.data[i]) is IterContinue else { return IterEnd }
        } else {
          go(data[len_1])
        }
      }
    }

    go(self)
  })
}

///|
impl[A : Eq] Eq for Node[A] with op_equal(self, other) {
  match (self, other) {
    (Flat(ka, pa), Flat(kb, pb)) => pa == pb && ka == kb
    (Branch(asa), Branch(bsa)) => asa == bsa
    (Leaf(ka, ra), Leaf(kb, rb)) => {
      guard ra.length() == rb.length() else { return false }
      let ia = Iter::singleton(ka) + ra.iter()
      let ib = Iter::singleton(kb) + rb.iter()
      ia.all(ib.contains(_))
    }
    _ => false
  }
}

///|
impl[A : Hash] Hash for Node[A] with hash_combine(self, hasher) {
  fn go {
    Flat(k, _) => A::hash_combine(k, hasher)
    Leaf(k, r) =>
      // To ensure that the hash is order-independent for Leaf nodes,
      // we should use a commutative operation like XOR over all hashes, 
      // rather than folding with order.
      // However, all elements in the same `Leaf` have almost identical hashes
      // which requires further discussion.
      hasher.combine_int(r.fold(init=k.hash(), fn(acc, x) { acc ^ x.hash() }))
    Branch(sa) => sa.data.each(go)
  }

  go(self)
}
