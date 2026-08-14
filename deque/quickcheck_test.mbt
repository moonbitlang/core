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
/// Full observational agreement between a deque and its array model: length,
/// emptiness, both ends, every index (checked and unchecked), and `to_array`.
fn agrees_with_model(dq : @deque.Deque[Int], model : Array[Int]) -> Bool {
  guard dq.length() == model.length() && dq.is_empty() == model.is_empty() else {
    return false
  }
  guard dq.front() == model.get(0) && dq.back() == model.get(model.length() - 1) else {
    return false
  }
  for i in 0..<model.length() {
    if dq.get(i) != Some(model[i]) || dq[i] != model[i] {
      return false
    }
  }
  dq.to_array() == model
}

///|
/// Builds a deque holding exactly the elements of `xs` inside a backing buffer
/// of the given capacity, with the internal head rotated `rot` slots forward
/// (`rot <= capacity`, `xs.length() <= capacity`). Whenever
/// `rot + xs.length() > capacity` (and `rot < capacity`) the contents wrap
/// around the end of the ring buffer, exercising the circular index
/// arithmetic that a freshly built deque never touches.
fn wrapped_deque(
  xs : Array[Int],
  capacity~ : Int,
  rot~ : Int,
) -> @deque.Deque[Int] {
  let dq : @deque.Deque[Int] = Deque([], capacity~)
  for i in 0..<rot {
    dq.push_back(i)
  }
  for _ in 0..<rot {
    dq.pop_front() |> ignore
  }
  for x in xs {
    dq.push_back(x)
  }
  dq
}

///|
test "quickcheck: mutation sequences agree with an array model" {
  @quickcheck.check((ops : Array[(Int, Int)]) => {
    let dq : @deque.Deque[Int] = Deque([])
    let model : Array[Int] = []
    for op in ops {
      let v = op.1
      match op.0 & 7 {
        // The op mix is deliberately biased towards push_back/pop_front so
        // that `head` marches through the buffer and the contents wrap.
        0 | 1 => {
          dq.push_back(v)
          model.push(v)
        }
        2 => {
          dq.push_front(v)
          model.insert(0, v)
        }
        3 | 4 => {
          let expected = if model.is_empty() {
            None
          } else {
            Some(model.remove(0))
          }
          if dq.pop_front() != expected {
            return false
          }
        }
        5 => if dq.pop_back() != model.pop() { return false }
        6 =>
          if model.is_empty() {
            dq.push_back(v)
            model.push(v)
          } else {
            let i = (v & 0x3fffffff) % model.length()
            dq[i] = v
            model[i] = v
          }
        _ =>
          match v & 3 {
            0 => {
              let keep = if model.is_empty() {
                0
              } else {
                ((v >> 2) & 0x3fffffff) % (model.length() + 1)
              }
              dq.truncate(keep)
              while model.length() > keep {
                model.pop() |> ignore
              }
            }
            1 => {
              let i = ((v >> 2) & 0x3fffffff) % (model.length() + 1)
              dq.insert(i, v)
              model.insert(i, v)
            }
            2 =>
              if !model.is_empty() {
                let i = ((v >> 2) & 0x3fffffff) % model.length()
                if dq.remove(i) != model.remove(i) {
                  return false
                }
              }
            _ => {
              dq.clear()
              model.clear()
            }
          }
      }
      if !agrees_with_model(dq, model) {
        return false
      }
    }
    true
  })
}

///|
test "quickcheck: reads and iteration survive ring-buffer wraparound" {
  @quickcheck.check(
    (input : (Array[Int], Int)) => {
      let (xs, r) = input
      guard !xs.is_empty() else { return true }
      let len = xs.length()
      // rot in 1..<len makes the contents wrap; rot == len lands head back
      // on slot 0, which must behave identically.
      let rot = 1 + (r & 0x3fffffff) % len
      let dq = wrapped_deque(xs, capacity=len, rot~)
      guard agrees_with_model(dq, xs) else { return false }
      guard dq.iter().to_array() == xs &&
        dq.rev_iter().to_array() == xs.rev() &&
        dq.rev().to_array() == xs.rev() &&
        @deque.from_iter(xs.iter()).to_array() == xs else {
        return false
      }
      guard dq.get(-1) == None && dq.get(len) == None else { return false }
      let mut ok = true
      dq.eachi((i, x) => if xs[i] != x { ok = false })
      dq.rev_eachi((i, x) => if xs[len - 1 - i] != x { ok = false })
      guard ok else { return false }
      let (front, back) = dq.as_views()
      front.to_owned() + back.to_owned() == xs
    },
    count=200,
  )
}

///|
test "quickcheck: capacity changes preserve wrapped contents" {
  @quickcheck.check(
    (input : (Array[Int], Int)) => {
      let (xs, r) = input
      guard !xs.is_empty() else { return true }
      let len = xs.length()
      let rot = 1 + (r & 0x3fffffff) % len
      // reserve_capacity must linearize a wrapped deque without corruption.
      let grown = wrapped_deque(xs, capacity=len, rot~)
      grown.reserve_capacity(2 * len + 3)
      guard grown.capacity() >= 2 * len + 3 && grown.to_array() == xs else {
        return false
      }
      // shrink_to_fit on a deque that wraps inside spare capacity.
      let spare = wrapped_deque(
        xs,
        capacity=2 * len,
        rot=len + 1 + (r & 0x3fffffff) % len,
      )
      guard spare.to_array() == xs else { return false }
      spare.shrink_to_fit()
      guard spare.capacity() == len && spare.to_array() == xs else {
        return false
      }
      // Organic growth: pushing past capacity while wrapped must relocate
      // both views in order.
      let dq = wrapped_deque(xs, capacity=len, rot~)
      for x in xs {
        dq.push_back(x)
      }
      dq.to_array() == xs + xs && dq.copy().to_array() == xs + xs
    },
    count=200,
  )
}

///|
test "quickcheck: bulk operations on a wrapped deque match array semantics" {
  @quickcheck.check(
    (input : (Array[Int], Int)) => {
      let (xs, r) = input
      guard !xs.is_empty() else { return true }
      let len = xs.length()
      let rot = 1 + (r & 0x3fffffff) % len
      let dq = wrapped_deque(xs, capacity=len, rot~)
      guard dq.map(x => x * 2 + 1).to_array() == xs.map(x => x * 2 + 1) &&
        dq.mapi((i, x) => i + x).to_array() == xs.mapi((i, x) => i + x) &&
        dq.filter(x => x % 3 == 0).to_array() == xs.filter(x => x % 3 == 0) else {
        return false
      }
      for x in xs {
        if dq.search(x) != xs.search(x) || !dq.contains(x) {
          return false
        }
      }
      // A probe value that is usually absent.
      guard dq.search(r) == xs.search(r) && dq.contains(r) == xs.contains(r) else {
        return false
      }
      let retained = wrapped_deque(xs, capacity=len, rot~)
      retained.retain(x => x % 3 != 0)
      guard retained.to_array() == xs.filter(x => x % 3 != 0) else {
        return false
      }
      let reversed = wrapped_deque(xs, capacity=len, rot~)
      reversed.rev_in_place()
      guard reversed.to_array() == xs.rev() else { return false }
      // append reads a wrapped source and writes into a wrapped target,
      // leaving the source untouched.
      let a = wrapped_deque(xs, capacity=len, rot~)
      let b = wrapped_deque(xs.rev(), capacity=len, rot~)
      a.append(b)
      a.to_array() == xs + xs.rev() && b.to_array() == xs.rev()
    },
    count=200,
  )
}

///|
test "quickcheck: binary_search on a sorted wrapped deque" {
  @quickcheck.check(
    (input : (Array[Int], Int)) => {
      let (xs, r) = input
      guard !xs.is_empty() else { return true }
      let sorted = xs.copy()
      sorted.sort()
      let len = sorted.length()
      let rot = 1 + (r & 0x3fffffff) % len
      let dq = wrapped_deque(sorted, capacity=len, rot~)
      for x in xs {
        match dq.binary_search(x) {
          Ok(i) => if i < 0 || i >= len || dq[i] != x { return false }
          Err(_) => return false
        }
      }
      // A probe that may be absent must report a correct insertion point.
      match dq.binary_search(r) {
        Ok(i) => i >= 0 && i < len && dq[i] == r
        Err(i) =>
          i >= 0 &&
          i <= len &&
          (i == 0 || dq[i - 1] < r) &&
          (i == len || dq[i] > r)
      }
    },
    count=200,
  )
}
