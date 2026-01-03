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
test "is_disjoint with different sizes" {
  let set1 = @hashset.new()
  let set2 = @hashset.new()

  // Add fewer elements to set1
  set1.add(1)
  set1.add(2)

  // Add more elements to set2, no overlap
  set2.add(3)
  set2.add(4)
  set2.add(5)
  set2.add(6)
  inspect(set1.is_disjoint(set2), content="true")
  // This should trigger the else branch where other.length() < self.length()
  inspect(set2.is_disjoint(set1), content="true")
}

///|
test "is_disjoint with overlap" {
  let set1 = @hashset.new()
  let set2 = @hashset.new()
  set1.add(1)
  set1.add(2)
  set2.add(2)
  set2.add(3)
  set2.add(4)
  inspect(set1.is_disjoint(set2), content="false")
  inspect(set2.is_disjoint(set1), content="false")
}

///|
test "is_subset with different sizes" {
  let subset = @hashset.new()
  let superset = @hashset.new()
  subset.add(1)
  subset.add(2)
  superset.add(1)
  superset.add(2)
  superset.add(3)
  superset.add(4)
  inspect(subset.is_subset(superset), content="true")
  // This should trigger the else branch where self.length() > other.length()
  inspect(superset.is_subset(subset), content="false")
}

///|
test "contains with probe sequence length comparison" {
  let set = @hashset.new()

  // Create a scenario that might trigger PSL comparison
  // Add multiple elements to create collisions and probe sequences
  for i in 0..<50 {
    set.add(i)
  }

  // Test containment
  inspect(set.contains(25), content="true")
  inspect(set.contains(100), content="false") // Not in set
}

///|
test "large set operations" {
  // Create a large enough set to test growth scenarios
  let set = @hashset.new()

  // Add many elements to trigger multiple grows
  for i in 0..<1000 {
    set.add(i)
  }
  inspect(set.length(), content="1000")
  inspect(set.contains(500), content="true")
  inspect(set.contains(1500), content="false")
}
