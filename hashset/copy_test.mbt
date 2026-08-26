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
/// A key whose hash maps every value into one of only 8 buckets, so
/// insertions collide heavily and deterministically -- independent of the
/// runtime hash seed, which is randomized on some targets. Without this,
/// whether the test reaches `shift_back` at all would depend on how `Int`
/// hashing happens to mix, and the regression could go unnoticed.
priv struct Collide(Int) derive(Eq)

///|
impl Hash for Collide with fn hash(self) {
  let Collide(x) = self
  x % 8
}

///|
impl Hash for Collide with fn hash_combine(self, hasher) {
  let Collide(x) = self
  hasher.combine_int(x % 8)
}

///|
/// `copy` used to blit the entry references, leaving both sets sharing
/// `Entry` objects. Because `Entry::psl` is mutable and `shift_back`
/// decrements it, a removal on either set silently corrupted the other's
/// probe sequences.
test "HashSet::copy is independent of the original" {
  let original = @hashset.HashSet([])
  for i in 0..<32 {
    original.add(Collide(i))
  }
  let duplicate = original.copy()
  for i in 0..<32 {
    duplicate.remove(Collide(i))
  }
  inspect(duplicate.length(), content="0")
  inspect(original.length(), content="32")
  let mut still_present = 0
  for i in 0..<32 {
    if original.contains(Collide(i)) {
      still_present += 1
    }
  }
  inspect(still_present, content="32")
}

///|
/// The other direction, and through insertion rather than removal: adding to
/// a copy can displace a shared entry and move it in the original's table.
test "HashSet::copy leaves the original unaffected by later insertions" {
  let original = @hashset.HashSet([])
  for i in 0..<16 {
    original.add(Collide(i))
  }
  // Only a few insertions, deliberately: enough to displace shared entries
  // through `push_away`, but not enough to trigger a `grow` -- growth
  // reassigns every PSL and would mask the corruption.
  let duplicate = original.copy()
  for i in 16..<20 {
    duplicate.add(Collide(i))
  }
  let mut still_present = 0
  for i in 0..<16 {
    if original.contains(Collide(i)) {
      still_present += 1
    }
  }
  inspect(still_present, content="16")
  inspect(original.length(), content="16")
  inspect(original.contains(Collide(18)), content="false")
  inspect(duplicate.contains(Collide(18)), content="true")
}

///|
test "HashSet::copy on an empty set" {
  let empty : Array[Collide] = []
  let original = @hashset.HashSet(empty)
  let duplicate = original.copy()
  inspect(duplicate.length(), content="0")
  duplicate.add(Collide(1))
  inspect(original.length(), content="0")
  inspect(duplicate.length(), content="1")
}
