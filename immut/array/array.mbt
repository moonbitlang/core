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

pub fn T::empty[A]() -> T[A] {
  { tree: Tree::empty(), size: 0, shift: 0 }
}

test "is_empty" {
  let v = of([1, 2, 3, 4, 5])
  let ve : T[Int] = T::empty()
  inspect!(is_empty(v), content="false")
  inspect!(is_empty(ve), content="true")
}

pub impl[A : Show] Show for T[A] with output(self, logger) {
  logger.write_string("@immut/array.of([")
  self.eachi(
    fn(i, v) {
      if i > 0 {
        logger.write_string(", ")
      }
      v.output(logger)
    },
  )
  logger.write_string("])")
}

pub fn to_string[A : Show](self : T[A]) -> String {
  Show::to_string(self)
}

test "to_string" {
  let v = of([1, 2, 3, 4, 5])
  let ve : T[Int] = T::empty()
  inspect!(v, content="@immut/array.of([1, 2, 3, 4, 5])")
  inspect!(ve, content="@immut/array.of([])")
}

pub fn is_empty[A](v : T[A]) -> Bool {
  v.size == 0
}

pub fn to_array[A](self : T[A]) -> Array[A] {
  let arr = []
  self.each(fn(v) { arr.push(v) })
  arr
}

test "to_array" {
  let v = of([1, 2, 3, 4])
  inspect!(v.to_array().to_string(), content="[1, 2, 3, 4]")
  inspect!(v.push(5).to_array().to_string(), content="[1, 2, 3, 4, 5]")
}

pub fn iter[A](self : T[A]) -> Iter[A] {
  Iter::new(
    fn(yield) {
      let arr = self.to_array()
      for i = 0; i < self.size; i = i + 1 {
        if yield(arr[i]) == IterEnd {
          break IterEnd
        }
      } else {
        IterContinue
      }
    },
  )
}

test "iter" {
  let buf = Buffer::new(size_hint=20)
  let v = of([1, 2, 3])
  v.iter().each(fn(e) { buf.write_string("[\(e)]") })
  inspect!(buf, content="[1][2][3]")
  buf.reset()
  v.iter().take(2).each(fn(e) { buf.write_string("[\(e)]") })
  inspect!(buf, content="[1][2]")
}

pub fn length[A](v : T[A]) -> Int {
  v.size
}

test "length" {
  let v = of([1, 2, 3, 4, 5])
  let ve : T[Int] = T::empty()
  inspect!(length(v), content="5")
  inspect!(length(ve), content="0")
}

pub fn copy[A](self : T[A]) -> T[A] {
  fn copy(t : Tree[A]) -> Tree[A] {
    match t {
      Leaf(l) => Leaf(l.copy())
      Empty => Empty
      Node(node) =>
        Node(Array::new_with_index(node.length(), fn(i) { copy(node[i]) }))
    }
  }

  { tree: copy(self.tree), size: self.size, shift: self.shift }
}

test "copy" {
  let v = of([1, 2, 3, 4, 5])
  let vc = v.copy()
  inspect!(vc, content="@immut/array.of([1, 2, 3, 4, 5])")
  inspect!(v == vc, content="true")
  @test.is_false!(physical_equal(v, vc))
  let v = T::empty()
  let vc : T[Int] = v.copy()
  inspect!(vc, content="@immut/array.of([])")
  inspect!(v == vc, content="true")
  @test.is_false!(physical_equal(v, vc))
}

/// Get a value at the given index.
/// 
/// # Examples
/// ```
/// let v = @immut/array.of([1, 2, 3, 4, 5])
/// v[0]
/// ```
pub fn op_get[A](self : T[A], index : Int) -> A {
  if index == 0 {
    self.tree.get_first()
  } else if index == self.size - 1 {
    self.tree.get_last()
  } else {
    self.tree.get(index, self.shift)
  }
}

test "op_get" {
  let v = of([1, 2, 3, 4, 5])
  inspect!(v[0], content="1")
  inspect!(v[1], content="2")
  inspect!(v[2], content="3")
  inspect!(v[3], content="4")
  inspect!(v[4], content="5")
}

/// Set a value at the given index (immutable).
/// 
/// # Example
/// ```
/// let v = @immut/array.of([1, 2, 3, 4, 5])
/// v.set(1, 10)
/// ```
pub fn set[A](self : T[A], index : Int, value : A) -> T[A] {
  fn set(i : Int, e, s, t : Tree[A]) -> Tree[A] {
    match t {
      Leaf(l) => Leaf(immutable_set(l, i.land(bitmask), e))
      Node(node) => {
        let idx = i.lsr(s).land(bitmask)
        Node(immutable_set(node, idx, set(i, e, s - num_bits, node[idx])))
      }
      Empty => abort("Index out of bounds")
    }
  }

  {
    tree: set(index, value, self.shift, self.tree),
    size: self.size,
    shift: self.shift,
  }
}

test "set" {
  let v = of([1, 2, 3, 4, 5])
  let v1 = v.set(1, 10)
  let v2 = v.set(2, 10)
  inspect!(v1, content="@immut/array.of([1, 10, 3, 4, 5])")
  inspect!(v2, content="@immut/array.of([1, 2, 10, 4, 5])")
}

/// Push a value to the end of the array.
/// 
/// # Example
/// ```
/// let v = @immut/array.of([1, 2, 3])
/// v.push(4)
/// ```
pub fn push[A](self : T[A], value : A) -> T[A] {
  if self.size == branching_factor.lsl(self.shift) {
    {
      tree: Node([self.tree, new_branch([value], self.shift)]),
      size: self.size + 1,
      shift: self.shift + num_bits,
    }
  } else {
    {
      tree: self.tree.add(self.size, self.shift, value),
      size: self.size + 1,
      shift: self.shift,
    }
  }
}

test "push" {
  let v = T::empty().push(1).push(2).push(3)
  inspect!(v, content="@immut/array.of([1, 2, 3])")
  inspect!(v.push(1), content="@immut/array.of([1, 2, 3, 1])")
  inspect!(v.push(2), content="@immut/array.of([1, 2, 3, 2])")
  inspect!(v.push(3), content="@immut/array.of([1, 2, 3, 3])")
}

/// Create a persistent array from an array.
/// 
/// # Example
/// ```
/// let v = @immut/array.of([1, 2, 3])
/// ```
pub fn T::from_array[A](arr : Array[A]) -> T[A] {
  new_with_index(arr.length(), fn(i) { arr[i] })
}

test "from_array" {
  let v = of([1, 1, 4, 5, 1, 4])
  let vv = T::from_array(Array::make(30, 1))
  inspect!(v, content="@immut/array.of([1, 1, 4, 5, 1, 4])")
  inspect!(
    vv,
    content="@immut/array.of([1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1])",
  )
}

/// Iterate over the array.
/// 
/// # Example
/// ```
/// let v = @immut/array.of([1, 2, 3, 4, 5])
/// v.each(fn(e) { println(e) })
/// ```
pub fn each[A](self : T[A], f : (A) -> Unit) -> Unit {
  fn go(t : Tree[A]) -> Unit {
    match t {
      Empty => ()
      Leaf(l) => l.each(f)
      Node(n) => n.each(fn(t) { go(t) })
    }
  }

  go(self.tree)
}

test "iter" {
  let v = of([1, 2, 3, 4, 5])
  let mut s = 0
  v.each(fn(e) { s = s + e })
  inspect!(s, content="15")
  let v : T[Int] = T::empty()
  v.each(fn(_e) { abort("never reach") })
}

/// Iterate over the array with index.
/// 
/// # Example
/// ```
/// let v = @immut/array.of([1, 2, 3, 4, 5])
/// v.eachi(fn(i, e) { println(i * e) })
/// ```
pub fn eachi[A](self : T[A], f : (Int, A) -> Unit) -> Unit {
  fn go(t : Tree[A], shift : Int, start : Int) -> Unit {
    match t {
      Empty => ()
      Leaf(l) =>
        for i = 0; i < l.length(); i = i + 1 {
          f(start + i, l[i])
        }
      Node(n) => {
        let child_shift = shift - num_bits
        let mut start = start
        for i = 0; i < n.length(); i = i + 1 {
          go(n[i], child_shift, start)
          start += (1).lsl(shift)
        }
      }
    }
  }

  go(self.tree, self.shift, 0)
}

test "iteri" {
  let v : T[Int] = T::empty()
  v.eachi(fn(_i, _e) { abort("never reach") })
  let v = of([1, 2, 3, 4, 5])
  let mut s = 0
  v.eachi(fn(i, e) { s = s + i * e })
  inspect!(s, content="40")
  let vec = []
  v.eachi(fn(i, _e) { vec.push(i) })
  inspect!(vec, content="[0, 1, 2, 3, 4]")
}

pub fn op_equal[A : Eq](self : T[A], other : T[A]) -> Bool {
  self.size == other.size && self.tree == other.tree
}

test "op_equal" {
  let v0 : T[Int] = of([])
  let v1 = of([1, 2, 3, 4, 5])
  let v2 = of([1, 2, 3, 4, 5])
  let v3 = of([1, 2, 3, 4, 6])
  let v4 = of([1, 2, 3, 4])
  let v5 = T::new(5, 1)
  let v6 = of([1, 1, 1, 1, 1])
  inspect!(v0 == T::empty(), content="true")
  inspect!(v1 == v2, content="true")
  inspect!(v1 == v3, content="false")
  inspect!(v1 == v4, content="false")
  inspect!(v5 == v6, content="true")
}

/// Fold the array from left to right.
/// 
/// # Example
/// ```
/// let v = @immut/array.of([1, 2, 3, 4, 5])
/// v.fold_left(fn(a, b) { a + b }, init=0)
/// ```
pub fn fold_left[A](self : T[A], f : (A, A) -> A, ~init : A) -> A {
  fn go(t : Tree[A], acc : A) -> A {
    match t {
      Empty => acc
      Leaf(l) => l.fold_left(f, init=acc)
      Node(n) => n.fold_left(fn(t, acc) { go(acc, t) }, init=acc)
    }
  }

  go(self.tree, init)
}

test "fold_left" {
  let e = T::empty()
  let v = of([1, 2, 3, 4, 5])
  inspect!(e.fold_left(fn(a, b) { a + b }, init=0), content="0")
  inspect!(v.fold_left(fn(a, b) { a + b }, init=0), content="15")
}

/// Fold the array from right to left.
/// 
/// # Example
/// ```
/// let v = @immut/array.of([1, 2, 3, 4, 5])
/// v.fold_right(fn(a, b) { a + b }, init=0)
/// ```
pub fn fold_right[A](self : T[A], f : (A, A) -> A, ~init : A) -> A {
  fn go(t : Tree[A], acc : A) -> A {
    match t {
      Empty => acc
      Leaf(l) => l.fold_right(f, init=acc)
      Node(n) => n.fold_right(fn(t, acc) { go(acc, t) }, init=acc)
    }
  }

  go(self.tree, init)
}

test "fold_right" {
  let e = T::empty()
  inspect!(e.fold_right(fn(a, b) { a + b }, init=0), content="0")
  let v = of([1, 2, 3, 4, 5])
  inspect!(e.fold_left(fn(a, b) { a + b }, init=0), content="0")
  inspect!(v.fold_right(fn(a, b) { a + b }, init=0), content="15")
}

/// Map a function over the array.
/// 
/// # Example
/// ```
/// let v = @immut/array.of([1, 2, 3, 4, 5])
/// v.map(fn(e) { e * 2 })
/// ```
pub fn map[A, B](self : T[A], f : (A) -> B) -> T[B] {
  fn go(t : Tree[A]) -> Tree[B] {
    match t {
      Empty => Empty
      Leaf(l) => Leaf(l.map(f))
      Node(n) => Node(Array::new_with_index(n.length(), fn(i) { go(n[i]) }))
    }
  }

  { tree: go(self.tree), size: self.size, shift: self.shift }
}

test "map" {
  let v = of([1, 2, 3, 4, 5])
  inspect!(v.map(fn(e) { e * 2 }), content="@immut/array.of([2, 4, 6, 8, 10])")
  inspect!(
    v.map(fn(e) { e.to_string() }),
    content=
      #|@immut/array.of(["1", "2", "3", "4", "5"])
    ,
  )
  inspect!(
    v.map(fn(e) { e % 2 == 0 }),
    content="@immut/array.of([false, true, false, true, false])",
  )
  inspect!(T::empty().map(fn(e : Int) { e }), content="@immut/array.of([])")
}

fn new_by_leaves[A](len : Int, gen_leaf : (Int, Int) -> Array[A]) -> T[A] {
  fn tree(cap, len, s) -> Tree[A] {
    if cap == branching_factor {
      Leaf(gen_leaf(s, len))
    } else {
      let child_cap = cap / branching_factor
      let part = len / child_cap
      let (child_count, last_child_len) = match len % child_cap {
        0 => (part, child_cap)
        r => (part + 1, r)
      }
      fn child(k) {
        let i = s + k * child_cap
        let len = if k + 1 == child_count { last_child_len } else { child_cap }
        tree(cap / branching_factor, len, i)
      }

      Node(Array::new_with_index(child_count, child))
    }
  }

  if len == 0 {
    T::empty()
  } else {
    let (cap, shift) = loop len, branching_factor, 1 {
      len, m_pow, depth =>
        match len < m_pow {
          false => continue len, m_pow * branching_factor, depth + 1
          true => (m_pow, (depth - 1) * num_bits)
        }
    }
    { shift, tree: tree(cap, len, 0), size: len }
  }
}

test "new_by_leaves" {
  let e : T[Int] = new_by_leaves(0, fn(_s, _l) { abort("never reach") })
  let v = new_by_leaves(5, fn(_s, l) { Array::make(l, 1) })
  let v2 = new_by_leaves(33, fn(_s, l) { Array::make(l, 10) })
  inspect!(e, content="@immut/array.of([])")
  inspect!(v, content="@immut/array.of([1, 1, 1, 1, 1])")
  inspect!(
    v2,
    content="@immut/array.of([10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10])",
  )
  let v3 = new_by_leaves(32, fn(_s, l) { Array::make(l, 10) })
  inspect!(
    v3,
    content="@immut/array.of([10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10])",
  )
}

/// Create a persistent array with a given length and value.
pub fn T::new[A](len : Int, value : A) -> T[A] {
  new_by_leaves(len, fn(_s, l) { Array::make(l, value) })
}

test "new" {
  let v = T::new(5, 1)
  let v2 = T::new(33, 10)
  inspect!(v, content="@immut/array.of([1, 1, 1, 1, 1])")
  inspect!(
    v2,
    content="@immut/array.of([10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10])",
  )
}

/// Create a persistent array with a given length and a function to generate values.
pub fn T::new_with_index[A](len : Int, f : (Int) -> A) -> T[A] {
  new_by_leaves(len, fn(s, l) { Array::new_with_index(l, fn(i) { f(s + i) }) })
}

test "new_with" {
  let v = new_with_index(5, fn(i) { i })
  let v2 = new_with_index(33, fn(i) { i * 10 })
  inspect!(v, content="@immut/array.of([0, 1, 2, 3, 4])")
  inspect!(
    v2,
    content="@immut/array.of([0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200, 210, 220, 230, 240, 250, 260, 270, 280, 290, 300, 310, 320])",
  )
}

test "mix" {
  let mut v = T::empty()
  inspect!(v.tree.is_empty_tree(), content="true")
  for i = 0; i < 100; i = i + 1 {
    v = v.push(i)
  }
  inspect!(
    v,
    content="@immut/array.of([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99])",
  )
  let mut v2 = v.copy()
  for i = 0; i < 100; i = i + 1 {
    v2 = v2.set(i, i * 2)
  }
  let mut ct = 0
  v.each(fn(e) { ct = ct + e })
  inspect!(ct, content="4950")
  v2.each(fn(e) { ct = ct + e })
  inspect!(ct, content="14850")
  v2 = v2.map(fn(e) { e * 2 })
  let ct1 = fold_left(v2, fn(a, b) { a + b }, init=0)
  let ct2 = fold_right(v2, fn(a, b) { a + b }, init=0)
  inspect!(ct1, content="19800")
  inspect!(ct2, content="19800")
  inspect!(v.tree.is_empty_tree(), content="false")
  let large_const = branching_factor * branching_factor + 1
  let mut v = T::empty()
  for i = 0; i < large_const; i = i + 1 {
    v = v.push(i)
  }
  let vec = []
  v.eachi(fn(i, _e) { vec.push(i) })
  for i = 0; i < large_const; i = i + 1 {
    @test.eq!(vec[i], i)
  }
}

pub fn T::of[A](arr : FixedArray[A]) -> T[A] {
  new_with_index(arr.length(), fn(i) { arr[i] })
}
