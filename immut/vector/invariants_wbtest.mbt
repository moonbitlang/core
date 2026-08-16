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

/// Structural invariant checks for the RRB tree behind `Vector`.
///
/// The property tests in `quickcheck_test.mbt` compare a vector against an
/// `Array` model, which catches wrong *elements*. They cannot see a vector
/// whose contents are currently right but whose tree is malformed — a stale
/// `sizes` array, a leaf above shift 0, a radix (`None`) node that is not
/// actually radix-indexable. Those only surface later, from a *different*
/// operation, as a wrong answer or an `abort`. `check_invariants` closes that
/// gap by validating the representation itself after every step.

//-----------------------------------------------------------------------------
// The checker
//-----------------------------------------------------------------------------

///|
/// Recompute the number of elements under `t` from the leaves up, ignoring
/// every cached `sizes` array. This is the reference `Tree::size` is checked
/// against.
fn[A] true_size(t : Tree[A]) -> Int {
  match t {
    Empty => 0
    Leaf(l) => l.length()
    Node(children, _) => children.fold(init=0, (acc, c) => acc + true_size(c))
  }
}

///|
/// `Tree::get`/`Tree::set` descend a `Node(_, None)` with `get_radix`, which
/// aborts as soon as it meets a node carrying explicit sizes. So a radix node
/// is only usable if its *whole* subtree is radix.
fn[A] all_radix(t : Tree[A]) -> Bool {
  match t {
    Empty | Leaf(_) => true
    Node(_, Some(_)) => false
    Node(children, None) =>
      for c in children {
        guard all_radix(c) else { break false }
      } nobreak {
        true
      }
  }
}

///|
/// Is there a node that is exactly full yet still carries a sizes array?
///
/// Such a node is legal — `append_right_leaf` and `push_end` patch a relaxed
/// node's sizes as it grows and never re-derive them — but it is the shape
/// that used to make `compute_sizes` mark the parent radix. Kept so the
/// regression test below can assert it really built one.
fn[A] has_full_but_relaxed(t : Tree[A], shift : Int) -> Bool {
  match t {
    Empty | Leaf(_) => false
    Node(children, sizes) => {
      if sizes is Some(_) && true_size(t) == BRANCHING_FACTOR << shift {
        return true
      }
      for c in children {
        guard !has_full_but_relaxed(c, shift - NUM_BITS) else { break true }
      } nobreak {
        false
      }
    }
  }
}

///|
/// `@test.assert_true` takes no message and a bare `fail` inside a loop loses
/// the index, so thread the description through explicitly.
fn ensure(cond : Bool, msg : String) -> Unit raise {
  guard cond else { fail(msg) }
}

///|
/// Walk the tree, checking every structural invariant. `path` names the node
/// being checked so a failure points at it.
fn[A] check_tree(t : Tree[A], shift : Int, path : String) -> Unit raise {
  match t {
    Empty => fail("\{path}: Empty may only appear as the whole tree")
    Leaf(l) => {
      ensure(shift == 0, "\{path}: Leaf at shift \{shift}, expected 0")
      ensure(l.length() > 0, "\{path}: empty Leaf")
      ensure(
        l.length() <= BRANCHING_FACTOR,
        "\{path}: Leaf holds \{l.length()} > \{BRANCHING_FACTOR} elements",
      )
    }
    Node(children, sizes) => {
      let len = children.length()
      ensure(
        shift >= NUM_BITS,
        "\{path}: Node at shift \{shift}, expected >= \{NUM_BITS}",
      )
      ensure(len > 0, "\{path}: Node with no children")
      ensure(
        len <= BRANCHING_FACTOR,
        "\{path}: Node has \{len} > \{BRANCHING_FACTOR} children",
      )
      let child_shift = shift - NUM_BITS
      let full_child = BRANCHING_FACTOR << child_shift
      match sizes {
        Some(sz) => {
          ensure(
            sz.length() == len,
            "\{path}: sizes has \{sz.length()} entries for \{len} children",
          )
          let mut acc = 0
          for i in 0..<len {
            acc += true_size(children[i])
            ensure(
              sz[i] == acc,
              "\{path}: sizes[\{i}] = \{sz[i]}, recomputed \{acc}",
            )
          }
        }
        None => {
          // Radix indexing assumes every child but the last is exactly full...
          for i in 0..<len {
            let sz = true_size(children[i])
            if i < len - 1 {
              ensure(
                sz == full_child,
                "\{path}: radix child \{i} holds \{sz}, expected the full \{full_child}",
              )
            } else {
              ensure(
                sz > 0 && sz <= full_child,
                "\{path}: radix last child holds \{sz}, expected 1..=\{full_child}",
              )
            }
          }
          // ...and that no descendant needs a sizes array, because `get_radix`
          // aborts on the first one it meets.
          ensure(
            all_radix(t),
            "\{path}: radix (None) node has a descendant carrying sizes; `get_radix` aborts on it",
          )
        }
      }
      ensure(
        t.size(shift) == true_size(t),
        "\{path}: Tree::size = \{t.size(shift)}, recomputed \{true_size(t)}",
      )
      for i in 0..<len {
        check_tree(children[i], child_shift, "\{path}.\{i}")
      }
    }
  }
}

///|
/// Check every invariant documented on `Vector` and `Tree`.
fn[A] check_invariants(v : Vector[A], what : String) -> Unit raise {
  ensure(v.size >= 0, "\{what}: negative size \{v.size}")
  ensure(
    v.tail.length() <= BRANCHING_FACTOR,
    "\{what}: tail holds \{v.tail.length()} > \{BRANCHING_FACTOR} elements",
  )
  ensure(v.shift >= 0, "\{what}: negative shift \{v.shift}")
  ensure(
    v.shift % NUM_BITS == 0,
    "\{what}: shift \{v.shift} is not a multiple of \{NUM_BITS}",
  )
  match v.tree {
    Empty =>
      ensure(
        v.shift == 0,
        "\{what}: Empty tree with shift \{v.shift}, expected 0",
      )
    _ => check_tree(v.tree, v.shift, "\{what}.tree")
  }
  let tree_size = true_size(v.tree)
  ensure(
    v.size == tree_size + v.tail.length(),
    "\{what}: size \{v.size} != tree \{tree_size} + tail \{v.tail.length()}",
  )
}

///|
/// Read every index through the public path, which is what a malformed tree
/// eventually breaks.
fn check_contents(
  v : Vector[Int],
  model : Array[Int],
  what : String,
) -> Unit raise {
  ensure(
    v.length() == model.length(),
    "\{what}: length \{v.length()} != model \{model.length()}",
  )
  for i in 0..<model.length() {
    ensure(
      v[i] == model[i],
      "\{what}: at(\{i}) = \{v[i]}, expected \{model[i]}",
    )
  }
}

//-----------------------------------------------------------------------------
// Regression: a full node that still carries sizes
//-----------------------------------------------------------------------------

///|
/// Build a vector whose tree holds a node that is exactly full (1024
/// elements, 32 full leaves) but still carries a sizes array.
///
/// `slice` leaves a partial right-most leaf and an empty tail; a small concat
/// parks four elements in the tail without touching the tree; the next concat
/// overflows the tail, so `normalize_tree` calls `append_right_leaf` with
/// delta = 4, which tops the partial `L28` up to a full `L32` while patching
/// the node's existing sizes array instead of re-deriving it.
fn full_but_relaxed_vector() -> Vector[Int] {
  makei(1024, i => i)
  .slice(0, 1020)
  .concat(makei(4, i => 1020 + i))
  .concat(makei(30, i => 1024 + i))
}

///|
/// `compute_sizes` used to mark a node radix from its children's *sizes*
/// alone. Feeding it the full-but-relaxed node above (all children full) made
/// it drop the parent's sizes array, and the radix descent in `get_radix`
/// then hit a child that still had one and aborted with
/// "Node should not have sizes in get_radix".
test "radix classification survives a full-but-relaxed node" {
  let base = full_but_relaxed_vector()
  ensure(
    has_full_but_relaxed(base.tree, base.shift),
    "base: expected a full node that still carries sizes",
  )
  check_invariants(base, "base")

  // Grow until the root has three children: the full-but-relaxed node, a
  // second full node, and a third holding a single leaf.
  let mut v = base
  let model = Array::makei(base.size, i => i)
  for k in 0..<1027 {
    v = v.push(base.size + k)
    model.push(base.size + k)
  }
  check_invariants(v, "grown")

  // Popping the last element empties that third child, so the root is rebuilt
  // from two children that are both exactly full.
  let p = v.pop().unwrap()
  let _ = model.pop()
  ensure(
    has_full_but_relaxed(p.tree, p.shift),
    "popped: expected the full-but-relaxed node to survive the pop",
  )
  check_invariants(p, "popped")
  check_contents(p, model, "popped")

  // The reads that used to abort.
  @test.assert_eq(p[0], 0)
  @test.assert_eq(p[500], 500)
  @test.assert_eq(p[p.length() - 1], model[model.length() - 1])
  let updated = p.set(0, -1)
  check_invariants(updated, "set")
  @test.assert_eq(updated[0], -1)
  @test.assert_eq(p[0], 0)
  // `take` at the same boundary rebuilds the root the same way
  let t = v.take(2048)
  check_invariants(t, "take")
  @test.assert_eq(t[0], 0)
  @test.assert_eq(t.length(), 2048)
}

//-----------------------------------------------------------------------------
// Regression: a short remainder attached one level too high
//-----------------------------------------------------------------------------

///|
/// `makei`, `make` and `from_iter` all build their tree with `from_leaves`,
/// whose height is fixed by the capacity it is given. It used to take a
/// shortcut whenever at most `BRANCHING_FACTOR` leaves were left, building a
/// height-1 node no matter how tall the subtree should have been. From three
/// levels up (> 32768 elements) with a remainder of at most 1024 elements,
/// that attached a leaf above shift 0: radix descent then read the wrong
/// element and `Tree::size` reported garbage — `makei(32832, i => i)[32800]`
/// returned 32768.
test "bulk constructors put every leaf at the bottom" {
  let level3 = BRANCHING_FACTOR * BRANCHING_FACTOR * BRANCHING_FACTOR
  for
    n in [
      level3,
      level3 + BRANCHING_FACTOR,
      level3 + 2 * BRANCHING_FACTOR,
      level3 + 1024,
      level3 + 1032,
      level3 + 2048,
      2 * level3 + BRANCHING_FACTOR,
    ] {
    for mode in 0..<3 {
      let v = match mode {
        0 => makei(n, i => i)
        1 => from_iter(Array::makei(n, i => i).iter())
        _ => make(n, 7)
      }
      let label = "n=\{n} mode=\{mode}"
      check_invariants(v, label)
      ensure(v.length() == n, "\{label}: length \{v.length()}")
      if mode != 2 {
        check_contents(v, Array::makei(n, i => i), label)
      }
    }
  }
}

//-----------------------------------------------------------------------------
// Randomized structural sweep
//-----------------------------------------------------------------------------

///|
/// Build `offset ..< offset + len` through one of the construction paths, so
/// the sweep sees the different tree shapes each of them leaves behind.
fn build_by(mode : Int, len : Int, offset : Int) -> Vector[Int] {
  match mode % 5 {
    0 => makei(len, i => offset + i)
    1 => {
      let mut v : Vector[Int] = new()
      for i in 0..<len {
        v = v.push(offset + i)
      }
      v
    }
    2 => from_iter(Array::makei(len, i => offset + i).iter())
    3 => makei(len + 40, i => offset + i - 17).slice(17, 17 + len)
    // a take that ends inside the tree leaves a partial right-most leaf and an
    // empty tail: the shape that feeds `append_right_leaf`'s top-up path
    _ => makei(len + BRANCHING_FACTOR * 3, i => offset + i).take(len)
  }
}

///|
fn replace_model(model : Array[Int], next : Array[Int]) -> Unit {
  model.clear()
  for x in next {
    model.push(x)
  }
}

///|
test "tree invariants hold across mixed operation sequences" {
  let rng = Random(Ref(20260816UL))
  for trial in 0..<60 {
    let mut v : Vector[Int] = new()
    let model : Array[Int] = []
    let mut next = 0
    for step in 0..<20 {
      let op = rng.int(limit=7)
      match op {
        0 => {
          // a run of pushes, so the right spine actually grows
          let n = 1 + rng.int(limit=70)
          for _ in 0..<n {
            v = v.push(next)
            model.push(next)
            next += 1
          }
        }
        1 => {
          let len = rng.int(limit=1200)
          v = v.concat(build_by(rng.int(limit=5), len, next))
          for i in 0..<len {
            model.push(next + i)
          }
          next += len
        }
        2 => {
          // tail-only concat: routes through `normalize_tree`
          let len = 1 + rng.int(limit=BRANCHING_FACTOR)
          v = v.concat(makei(len, i => next + i))
          for i in 0..<len {
            model.push(next + i)
          }
          next += len
        }
        3 =>
          if model.length() > 0 {
            let i = rng.int(limit=model.length())
            v = v.set(i, next)
            model[i] = next
            next += 1
          }
        4 =>
          for _ in 0..<(1 + rng.int(limit=40)) {
            if model.length() > 0 {
              v = v.pop().unwrap()
              let _ = model.pop()
            }
          }
        5 => {
          let n = model.length()
          let s = if n == 0 { 0 } else { rng.int(limit=n + 1) }
          let e = if n == 0 { 0 } else { s + rng.int(limit=n - s + 1) }
          v = v.slice(s, e)
          replace_model(model, model[s:e].to_owned())
        }
        _ => {
          // cut at a chunk boundary: `slice_right` can then return a child
          // untouched and hand `compute_sizes` an all-full children array
          let n = model.length()
          let k = if n == 0 {
            0
          } else {
            min(n, rng.int(limit=n / BRANCHING_FACTOR + 2) * BRANCHING_FACTOR)
          }
          v = v.take(k)
          replace_model(model, model[0:k].to_owned())
        }
      }
      check_invariants(v, "trial \{trial} step \{step} op \{op}")
      check_contents(v, model, "trial \{trial} step \{step} op \{op}")
    }
  }
}

///|
/// `normalize_tree` reaches `Tree::push_end` only when the left vector's tail
/// holds a single element, which forces the right vector to be exactly one
/// full chunk. Nothing used to construct that pair, so the whole of
/// `push_end` was dead in the test suite.
test "single-element tail routes through push_end" {
  let mut exercised = 0
  for base in [33, 65, 97, 1025, 1057, 2049] {
    for mode in 0..<5 {
      let v = build_by(mode, base, 0)
      if v.tail.length() != 1 {
        continue
      }
      exercised += 1
      let c = v.concat(makei(BRANCHING_FACTOR, i => 1000000 + i))
      check_invariants(c, "push_end base=\{base} mode=\{mode}")
      check_contents(
        c,
        Array::makei(base + BRANCHING_FACTOR, i => {
          if i < base {
            i
          } else {
            1000000 + i - base
          }
        }),
        "push_end base=\{base} mode=\{mode}",
      )
      // the result must keep behaving
      check_invariants(c.push(-1), "push_end then push")
      check_invariants(c.pop().unwrap(), "push_end then pop")
      check_invariants(
        c.concat(makei(1000, i => 5000000 + i)),
        "push_end then concat",
      )
    }
  }
  ensure(exercised > 0, "no single-element-tail vector was built")
}
