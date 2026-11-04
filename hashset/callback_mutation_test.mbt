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

// A callback that modifies the set it is traversing gets unspecified results,
// but the results must stay memory-safe and well-formed.

///|
/// Every element hashes alike, so the elements share one probe cluster and a
/// removal shifts the entries after it.
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
test "filter: callback re-adds the current element" {
  let s = @hashset.from_array([SameHash(1), SameHash(2)])
  let r = s.filter(x => {
    if x == SameHash(1) {
      s.remove(x)
      s.add(x)
    }
    true
  })
  inspect(r.length(), content="2")
  inspect(r.contains(SameHash(1)), content="true")
  inspect(r.contains(SameHash(2)), content="true")
  inspect(r.iter().count(), content="2")
}
