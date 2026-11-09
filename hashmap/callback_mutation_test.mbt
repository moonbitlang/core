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

// A callback that modifies the map it is traversing gets unspecified results,
// but the results must stay memory-safe and well-formed.

///|
/// Every key hashes alike, so the keys share one probe cluster and a removal
/// shifts the entries after it.
#derive(Eq)
priv struct SameHash(Int32)

///|
impl Hash for SameHash with fn hash(_) {
  0
}

///|
impl Hash for SameHash with fn hash_combine(_, hasher) {
  hasher.combine_int(0)
}

///|
test "map: callback clears the source" {
  // The result is unspecified, but its length must match its contents.
  let m = @hashmap.HashMap([(1, "a"), (2, "b")])
  let r = m.map((_, v) => {
    m.clear()
    v + "!"
  })
  inspect(r.iter().count() == r.length(), content="true")
  inspect(r.to_array().length() == r.length(), content="true")
  inspect(m.length(), content="0")
}

///|
test "map: callback grows the source" {
  let m = @hashmap.HashMap([(1, 1), (2, 2), (3, 3), (4, 4)])
  let r = m.map((k, v) => {
    if k == 1 {
      for i in 100..<200 {
        m.set(i, i)
      }
    }
    v * 10
  })
  inspect(r.length(), content="4")
  inspect(r.iter().count(), content="4")
  for k in 1..<=4 {
    debug_inspect(r.get(k), content="Some(\{k * 10})")
  }
  inspect(m.length(), content="104")
}

///|
test "map: callback re-adds the current key" {
  // The result is unspecified, but its length must match its contents.
  let m = @hashmap.HashMap([(SameHash(1), 1), (SameHash(2), 2)])
  let r = m.map((k, v) => {
    if k == SameHash(1) {
      m.remove(k)
      m.set(k, v)
    }
    v * 10
  })
  inspect(r.iter().count() == r.length(), content="true")
  inspect(r.to_array().length() == r.length(), content="true")
}

///|
test "map: callback grows the source, then the result is used" {
  let m = @hashmap.HashMap([(1, 1), (2, 2), (3, 3), (4, 4)])
  let r = m.map((k, v) => {
    if k == 1 {
      for i in 100..<200 {
        m.set(i, i)
      }
    }
    v
  })
  for i in 10..<60 {
    r.set(i, i)
  }
  r.remove(2)
  inspect(r.length(), content="53")
  inspect(r.iter().count(), content="53")
  debug_inspect(r.get(2), content="None")
  debug_inspect(r.get(3), content="Some(3)")
}

///|
test "each: callback inserts and removes keys" {
  // Which entries `each` visits is unspecified, but the map stays consistent.
  let m = @hashmap.HashMap([(1, 1), (2, 2), (3, 3), (4, 4)])
  let mut done = false
  m.each((k, _) => {
    if k == 2 && !done {
      done = true
      m.remove(2)
      m.remove(3)
      for i in 100..<164 {
        m.set(i, i)
      }
    }
  })
  inspect(m.length(), content="66")
  inspect(m.iter().count(), content="66")
  debug_inspect(m.get(3), content="None")
}

///|
test "iter: map cleared mid-iteration" {
  let m = @hashmap.HashMap([(1, 1), (2, 2), (3, 3)])
  let mut n = 0
  for _ in m.iter() {
    n += 1
    m.clear()
  }
  inspect(n >= 1, content="true")
  inspect(m.length(), content="0")
  inspect(m.iter().count(), content="0")
}

///|
test "retain: callback removes another key" {
  let m = @hashmap.HashMap([(1, 1), (2, 2), (3, 3), (4, 4)])
  m.retain((k, _) => {
    if k == 1 {
      m.remove(3)
    }
    k != 2
  })
  inspect(m.iter().count() == m.length(), content="true")
  debug_inspect(m.get(1), content="Some(1)")
  debug_inspect(m.get(3), content="None")
  debug_inspect(m.get(4), content="Some(4)")
  // Removing key 3 can shift key 2 back into a slot `retain` has already
  // scanned, so `f` never sees key 2 and it stays. Slot layout depends on the
  // per-process hash seed, so either outcome is allowed.
  inspect(m.get(2) is (None | Some(2)), content="true")
  inspect(m.length() == (if m.contains(2) { 3 } else { 2 }), content="true")
}
