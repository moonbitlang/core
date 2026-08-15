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
/// Full observational agreement between a queue and its array model (front of
/// the queue is index 0 of the model): length, emptiness, peek, iteration in
/// all its forms, and structural equality with a freshly built queue.
fn agrees_with_model(q : @queue.Queue[Int], model : Array[Int]) -> Bool {
  guard q.length() == model.length() &&
    q.is_empty() == model.is_empty() &&
    q.peek() == model.get(0) else {
    return false
  }
  guard q.iter().to_array() == model else { return false }
  let collected : Array[Int] = []
  q.each(x => collected.push(x))
  guard collected == model else { return false }
  let mut indices_ok = true
  q.eachi((i, x) => if model[i] != x { indices_ok = false })
  guard indices_ok else { return false }
  q.fold(init=[], (acc : Array[Int], x) => {
    acc.push(x)
    acc
  }) ==
  model
}

///|
test "quickcheck: mutation sequences agree with an array model" {
  @quickcheck.check(
    (ops : Array[(Int, Int)]) => {
      let q : @queue.Queue[Int] = @queue.from_array([])
      let model : Array[Int] = []
      let mut step = 0
      for op in ops {
        let v = op.1
        match op.0 & 7 {
          0 | 1 | 2 => {
            q.push(v)
            model.push(v)
          }
          // pop is as frequent as push, and the drain/clear ops below pull the
          // queue back to empty over and over: the empty<->nonempty
          // transitions are where head/tail bookkeeping bugs live.
          3 | 4 | 5 => {
            let expected = if model.is_empty() {
              None
            } else {
              Some(model.remove(0))
            }
            if q.pop() != expected {
              return false
            }
          }
          6 => {
            // Drain to empty one pop at a time, then rebuild from a
            // just-emptied queue.
            while !model.is_empty() {
              if q.pop() != Some(model.remove(0)) {
                return false
              }
            }
            if q.pop() != None || q.peek() != None || !q.is_empty() {
              return false
            }
            q.push(v)
            model.push(v)
          }
          _ => {
            q.clear()
            model.clear()
          }
        }
        // Cheap invariants after every op, full agreement periodically.
        guard q.length() == model.length() &&
          q.is_empty() == model.is_empty() &&
          q.peek() == model.get(0) else {
          return false
        }
        step = step + 1
        if step % 4 == 0 && !agrees_with_model(q, model) {
          return false
        }
      }
      agrees_with_model(q, model)
    },
    count=200,
  )
}

///|
test "quickcheck: FIFO law - pushing xs then popping yields xs in order" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let q : @queue.Queue[Int] = @queue.from_array([])
      for x in xs {
        q.push(x)
      }
      guard q.length() == xs.length() && q.peek() == xs.get(0) else {
        return false
      }
      let out : Array[Int] = []
      while q.pop() is Some(x) {
        out.push(x)
      }
      out == xs && q.is_empty() && q.pop() == None && q.peek() == None
    },
    count=300,
  )
}

///|
test "quickcheck: interleaved pushes and pops match the model prediction" {
  @quickcheck.check(
    (input : (Array[Int], Array[Int], Int)) => {
      let (a_elems, b_elems, r) = input
      // Split point: pop k elements between the two push phases.
      let k = (r & 0x3fffffff) % (a_elems.length() + 1)
      let q : @queue.Queue[Int] = @queue.from_array([])
      let out : Array[Int] = []
      for x in a_elems {
        q.push(x)
      }
      for _ in 0..<k {
        match q.pop() {
          Some(x) => out.push(x)
          None => return false
        }
      }
      for x in b_elems {
        q.push(x)
      }
      guard q.length() == a_elems.length() - k + b_elems.length() else {
        return false
      }
      while q.pop() is Some(x) {
        out.push(x)
      }
      // Whatever the split point, FIFO order means the concatenated output is
      // exactly all pushes in push order.
      out == a_elems + b_elems && q.is_empty()
    },
    count=300,
  )
}

///|
test "quickcheck: construction roundtrips and non-consuming iteration" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let q = @queue.from_array(xs)
      guard agrees_with_model(q, xs) else { return false }
      guard agrees_with_model(@queue.from_iter(xs.iter()), xs) else {
        return false
      }
      guard agrees_with_model(@queue.from_iter(q.iter()), xs) else {
        return false
      }
      // iter must not consume: two traversals agree and the queue is intact.
      let first = q.iter().to_array()
      let second = q.iter().to_array()
      first == second && agrees_with_model(q, xs)
    },
    count=300,
  )
}

///|
test "quickcheck: copy is deep - either side can mutate independently" {
  @quickcheck.check(
    (input : (Array[Int], Int)) => {
      let (xs, v) = input
      let original = @queue.from_array(xs)
      let copied = original.copy()
      guard agrees_with_model(copied, xs) else { return false }
      // Mutating the copy must not touch the original.
      copied.push(v)
      copied.pop() |> ignore
      guard agrees_with_model(original, xs) else { return false }
      // And mutating the original must not touch a fresh copy.
      let copied2 = original.copy()
      original.push(v)
      original.pop() |> ignore
      guard agrees_with_model(copied2, xs) else { return false }
      // Clearing one side leaves the other intact.
      copied2.clear()
      original.length() == xs.length()
    },
    count=200,
  )
}

///|
test "quickcheck: transfer appends source to destination and empties source" {
  @quickcheck.check(
    (input : (Array[Int], Array[Int])) => {
      let (src_elems, dst_elems) = input
      let src = @queue.from_array(src_elems)
      let dst = @queue.from_array(dst_elems)
      src.transfer(dst)
      guard agrees_with_model(src, []) && src.pop() == None else {
        return false
      }
      guard agrees_with_model(dst, dst_elems + src_elems) else { return false }
      // Self-transfer is documented as a no-op.
      dst.transfer(dst)
      guard agrees_with_model(dst, dst_elems + src_elems) else { return false }
      // An emptied source is a working queue: it can be rebuilt and drained.
      for x in src_elems {
        src.push(x)
      }
      agrees_with_model(src, src_elems)
    },
    count=200,
  )
}

///|
test "quickcheck: after clear the queue is indistinguishable from new" {
  @quickcheck.check(
    (xs : Array[Int]) => {
      let q = @queue.from_array(xs)
      q.clear()
      guard agrees_with_model(q, []) && q.pop() == None && q.peek() == None else {
        return false
      }
      // A cleared queue must accept pushes like a fresh one.
      for x in xs {
        q.push(x)
      }
      agrees_with_model(q, xs)
    },
    count=200,
  )
}
