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
fn descending_sorted(xs : Array[Int]) -> Array[Int] {
  let sorted = xs.copy()
  sorted.sort()
  sorted.rev_in_place()
  sorted
}

///|
/// Fully drains a persistent queue via peek + pop, without touching the
/// original: every step reads the maximum and continues with the queue that
/// `pop` returns.
fn drain(queue : @priority_queue.PriorityQueue[Int]) -> Array[Int] {
  let out : Array[Int] = []
  let mut q = queue
  while q.pop() is Some(rest) {
    match q.peek() {
      Some(x) => out.push(x)
      None => abort("peek is None on a queue that pop considers non-empty")
    }
    q = rest
  }
  out
}

///|
fn model_peek(model : Array[Int]) -> Int? {
  guard !model.is_empty() else { return None }
  let mut best = model[0]
  for x in model {
    if x > best {
      best = x
    }
  }
  Some(best)
}

///|
fn model_pop(model : Array[Int]) -> Int? {
  guard !model.is_empty() else { return None }
  let mut idx = 0
  for i, x in model {
    if x > model[idx] {
      idx = i
    }
  }
  Some(model.remove(idx))
}

///|
/// The core heap specification: building from an arbitrary array and popping
/// until empty yields exactly the input in descending order (this is a
/// max-heap), ending with an empty queue.
test "quickcheck: draining from_array yields descending sorted order" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let queue = @priority_queue.from_array(xs)
      drain(queue) == descending_sorted(xs) &&
      queue.length() == xs.length() && // the original queue is untouched
      queue.pop().map(q => q.length()) ==
      (if xs.is_empty() { None } else { Some(xs.length() - 1) })
    },
    count=300,
  )
}

///|
/// Same drain property but with a tiny value space, so the heap is packed
/// with equal keys. Duplicates stress tie-handling in `change_and_down` and
/// `push`'s high/low routing.
test "quickcheck: draining with heavy duplication stays sorted" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let dups = xs.map(x => x % 8)
      drain(@priority_queue.from_array(dups)) == descending_sorted(dups)
    },
    count=300,
  )
}

///|
/// PERSISTENCE, the point of this package: during a random interleaved
/// push/pop sequence, snapshot the queue together with its model contents
/// every few operations. After the whole sequence has run, every snapshot
/// must still drain to exactly the contents it had when it was taken. Any
/// in-place mutation of shared nodes by a later push/pop would corrupt an
/// earlier snapshot and be caught here.
test "quickcheck: old versions survive later operations" {
  @quickcheck.check(
    (ops : Array[(Int, Int)]) => {
      let mut queue : @priority_queue.PriorityQueue[Int] = PriorityQueue([])
      let model : Array[Int] = []
      let snapshots : Array[(@priority_queue.PriorityQueue[Int], Array[Int])] = [
        (queue, []),
      ]
      for i, op in ops {
        // A small value space deliberately creates shared equal keys.
        let value = op.0 % 8
        if op.1 % 3 == 0 {
          match queue.pop() {
            Some(rest) => {
              queue = rest
              model_pop(model) |> ignore
            }
            None => if !model.is_empty() { return false }
          }
        } else {
          queue = queue.push(value)
          model.push(value)
        }
        if i % 4 == 0 {
          snapshots.push((queue, model.copy()))
        }
      }
      snapshots.push((queue, model.copy()))
      for snap in snapshots {
        if drain(snap.0) != descending_sorted(snap.1) {
          return false
        }
      }
      true
    },
    count=200,
  )
}

///|
/// Model-based test: an interleaved random sequence of push/pop hits heap
/// shapes that build-then-drain never produces. After every operation, peek,
/// pop results, length and emptiness must agree with a plain-array model.
test "quickcheck: interleaved push/pop agrees with an array model" {
  @quickcheck.check(
    (ops : Array[(Int, Int)]) => {
      let mut queue : @priority_queue.PriorityQueue[Int] = PriorityQueue([])
      let model : Array[Int] = []
      for op in ops {
        let value = op.0 % 8
        if op.1 % 3 == 0 {
          let expected = model_pop(model)
          let popped = queue.peek()
          match queue.pop() {
            Some(rest) => {
              if popped != expected {
                return false
              }
              queue = rest
            }
            None => if expected is Some(_) { return false }
          }
        } else {
          queue = queue.push(value)
          model.push(value)
        }
        if queue.peek() != model_peek(model) ||
          queue.length() != model.length() ||
          queue.is_empty() != model.is_empty() {
          return false
        }
      }
      true
    },
    count=300,
  )
}

///|
/// to_array and iter report the queue contents in descending priority order
/// without consuming the queue, and peek is exactly the head of that view.
test "quickcheck: to_array/iter are descending views and peek is their head" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let queue = @priority_queue.from_iter(xs.iter())
      let expected = descending_sorted(xs)
      let head = if expected.is_empty() { None } else { Some(expected[0]) }
      queue.to_array() == expected &&
      queue.iter().to_array() == expected &&
      queue.peek() == head &&
      queue.length() == xs.length()
    },
    count=200,
  )
}

///|
/// Eq/Compare are documented as content-based (sorted contents, shortlex), so
/// any two queues holding the same multiset must be equal no matter how they
/// were built: bulk heapify, pushes in ascending order, or pushes in
/// descending order. Equal queues must also hash identically.
test "quickcheck: equal multisets built in different orders are equal" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let dups = xs.map(x => x % 8)
      let built = @priority_queue.from_array(dups)
      let ascending = dups.copy()
      ascending.sort()
      let mut fwd : @priority_queue.PriorityQueue[Int] = PriorityQueue([])
      for x in ascending {
        fwd = fwd.push(x)
      }
      let mut rev : @priority_queue.PriorityQueue[Int] = PriorityQueue([])
      for x in descending_sorted(dups) {
        rev = rev.push(x)
      }
      built == fwd &&
      fwd == rev &&
      built.compare(rev) == 0 &&
      built == @priority_queue.from_iter(dups.iter()) &&
      built.hash() == fwd.hash()
    },
    count=200,
  )
}
