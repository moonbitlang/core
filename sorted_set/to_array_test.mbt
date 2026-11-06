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
priv struct ReentrantCompare {
  value : Int32
  before_compare : () -> Unit
}

///|
impl Eq for ReentrantCompare with fn equal(a, b) {
  a.value == b.value
}

///|
impl Compare for ReentrantCompare with fn compare(a, b) {
  (a.before_compare)()
  a.value.compare(b.value)
}

///|
test "to_array stays safe after a comparison mutates the set" {
  let set : @sorted_set.SortedSet[ReentrantCompare] = SortedSet([])
  set.add({ value: 1, before_compare: () => (), })
  set.add({ value: 2, before_compare: () => set.clear(), })
  // Mutation during comparison has unspecified results, but array
  // construction must initialize every element without writing out of bounds.
  let actual = set.to_array().map(x => x.value)
  let traversed = set.iter().map(x => x.value).to_array()
  assert_eq(actual, traversed)
}
