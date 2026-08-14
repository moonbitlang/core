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
/// until empty yields exactly the input in descending order. This exercises
/// the meld/merges (sift) machinery completely.
test "quickcheck: draining from_array yields descending sorted order" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let queue = @priority_queue.from_array(xs)
      let drained : Array[Int] = []
      while queue.pop() is Some(x) {
        drained.push(x)
      }
      drained == descending_sorted(xs) &&
      queue.length() == 0 &&
      queue.is_empty() &&
      queue.peek() is None
    },
    count=300,
  )
}

///|
/// Same drain property but with a tiny value space, so the heap is packed
/// with equal keys. Duplicates stress tie-handling in meld ordering.
test "quickcheck: draining with heavy duplication stays sorted" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let dups = xs.map(x => x % 8)
      let queue = @priority_queue.from_array(dups)
      let drained : Array[Int] = []
      while queue.pop() is Some(x) {
        drained.push(x)
      }
      drained == descending_sorted(dups)
    },
    count=300,
  )
}

///|
/// Model-based test: an interleaved random sequence of push/pop hits heap
/// shapes that build-then-drain never produces. After every operation, peek,
/// pop results, length and emptiness must agree with a plain-array model.
test "quickcheck: interleaved push/pop agrees with an array model" {
  @quickcheck.check(
    (ops : Array[(Int, Int)]) => {
      let queue : @priority_queue.PriorityQueue[Int] = PriorityQueue([])
      let model : Array[Int] = []
      for op in ops {
        // A small value space deliberately generates many equal keys.
        let value = op.0 % 8
        if op.1 % 3 == 0 {
          if queue.pop() != model_pop(model) {
            return false
          }
        } else {
          queue.push(value)
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
/// copy produces a deep, independent queue: draining and refilling the copy
/// must leave the original untouched, and mutating the original afterwards
/// must not resurrect anything in the drained copy.
test "quickcheck: copy is independent of the original" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let original = @priority_queue.from_array(xs)
      let snapshot = original.to_array()
      let copied = original.copy()
      while !copied.is_empty() {
        copied.pop() |> ignore
      }
      copied.push(42)
      if original.to_array() != snapshot || original.length() != xs.length() {
        return false
      }
      original.push(7)
      copied.length() == 1 && copied.peek() == Some(42)
    },
    count=200,
  )
}
