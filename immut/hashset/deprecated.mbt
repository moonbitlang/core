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
/// Converted to internal Iter.
#warnings("-deprecated")
#deprecated("Use `HashSet::iterator()` to get an external iterator.")
pub fn[A] HashSet::iter(self : HashSet[A]) -> Iter[A] {
  fn go(node) -> Iter[A] {
    match node {
      Leaf(k, bucket) => Iter::singleton(k) + bucket.iter()
      Flat(k, _) => Iter::singleton(k)
      Branch(children) => children.data.iter().flat_map(go)
    }
  }

  match self.0 {
    None => Iter::empty()
    Some(node) => go(node)
  }
}

///|
#warnings("-deprecated")
#deprecated("Use `HashSet::from_iterator()` with an external iterator.")
#as_free_fn
pub fn[A : Eq + Hash] HashSet::from_iter(iter : Iter[A]) -> HashSet[A] {
  iter.fold(init=new(), (s, e) => s.add(e))
}
