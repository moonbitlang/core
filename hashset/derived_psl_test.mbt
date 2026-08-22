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

// The probe-sequence length is derived from a slot's position rather than
// stored, so these exercise every path that used to write a PSL: displacement,
// shift-back cascades, growth, copying, and the remapped sentinel.

///|
priv struct Coll(Int) derive(Eq)

///|
impl Hash for Coll with fn hash(self) {
  let Coll(x) = self
  x % 4
}

///|
impl Hash for Coll with fn hash_combine(self, hasher) {
  let Coll(x) = self
  hasher.combine_int(x % 4)
}

///|
/// Heavy collisions: long probe runs, push_away displacement, shift_back
/// cascades, growth, and copy -- every path the derived PSL has to get right.
test "two-array stress" {
  let s = @hashset.HashSet([])
  for round in 0..<6 {
    for i in 0..<200 {
      s.add(Coll(i + round * 200))
    }
    for i in 0..<200 {
      if i % 3 == 0 {
        s.remove(Coll(i + round * 200))
      }
    }
    for i in 0..<200 {
      if i % 3 == 0 {
        s.add(Coll(i + round * 200))
      }
    }
  }
  inspect(s.length(), content="1200")
  let mut found = 0
  for i in 0..<1200 {
    if s.contains(Coll(i)) {
      found += 1
    }
  }
  inspect(found, content="1200")
  // absent keys must stay absent
  let mut absent = 0
  for i in 1200..<1400 {
    if !s.contains(Coll(i)) {
      absent += 1
    }
  }
  inspect(absent, content="200")
  let dup = s.copy()
  for i in 0..<600 {
    dup.remove(Coll(i))
  }
  inspect(dup.length(), content="600")
  inspect(s.length(), content="1200")
}

///|
/// The sentinel path: keys whose hash is exactly `empty_hash` must round-trip,
/// since their stored hash is remapped.
test "keys hashing to the empty sentinel" {
  let s = @hashset.HashSet([])
  for i in 0..<400 {
    s.add(Coll(i))
  }
  // Coll(0), Coll(4), ... hash to 0, which is the sentinel value.
  inspect(s.contains(Coll(0)), content="true")
  inspect(s.contains(Coll(4)), content="true")
  inspect(s.length(), content="400")
  s.remove(Coll(0))
  inspect(s.contains(Coll(0)), content="false")
  inspect(s.contains(Coll(4)), content="true")
  inspect(s.length(), content="399")
  let arr = s.to_array()
  inspect(arr.length(), content="399")
}

///|
/// Differential check against a reference model over randomized operations.
test "differential against a model" {
  let s = @hashset.HashSet([])
  let present = FixedArray::make(1000, false)
  let mut state = 0x2545F491
  let mut model_size = 0
  for step in 0..<20000 {
    state = state * 1103515245 + 12345
    let k = (state >> 8) % 500
    let slot = k + 500
    if step % 3 == 0 {
      s.remove(k)
      if present[slot] {
        present[slot] = false
        model_size -= 1
      }
    } else {
      s.add(k)
      if !present[slot] {
        present[slot] = true
        model_size += 1
      }
    }
  }
  inspect(s.length() == model_size, content="true")
  let mut agree = 0
  for k in -500..<500 {
    if s.contains(k) == present[k + 500] {
      agree += 1
    }
  }
  inspect(agree, content="1000")
}
