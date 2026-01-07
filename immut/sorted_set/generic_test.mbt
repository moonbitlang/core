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
test "sorted set equality comparison with unequal elements" {
  let set1 = @sorted_set.from_array([1, 2, 3])
  let set2 = @sorted_set.from_array([1, 2, 4])
  assert_false(set1 == set2)
}

///|
test "compare with shared prefix" {
  let set1 = @sorted_set.from_array([1, 2, 3])
  let set2 = @sorted_set.from_array([1, 2, 4])
  assert_true(set1 < set2)
}

///|
test "iter early termination - value" {
  let set = @sorted_set.from_array([1, 2, 3])
  let mut count = 0
  for x in set {
    if x == 2 {
      break
    } else {
      count = count + 1
    }
  }
  inspect(count, content="1")
}

///|
test "iter terminates on right" {
  let set = @sorted_set.from_array([1, 2, 3])
  let result = set.iter().take(2).to_array()
  inspect(result, content="[1, 2]")
}

///|
test "iter with early termination on left subtree" {
  // Create a binary search tree with both left and right subtrees
  let set = @sorted_set.new()
    .add(2) // root
    .add(1) // left child
    .add(3) // right child

  // Create an iterator that stops after processing the left subtree
  let mut count = 0
  let iter = set.iter()
  for _ in iter {
    count = count + 1
    if count == 1 {
      break
    }
  }

  // Verify that we stopped after processing the first element
  inspect(count, content="1")
}

///|
test "rev_iter returns elements in descending order" {
  let set = @sorted_set.from_array([1, 2, 3, 4, 5])
  let result = set.rev_iter().collect()
  inspect(result, content="[5, 4, 3, 2, 1]")
}

///|
test "rev_iter on empty set" {
  let set : @sorted_set.SortedSet[Int] = @sorted_set.new()
  let result = set.rev_iter().collect()
  inspect(result, content="[]")
}

///|
test "rev_iter on single element set" {
  let set = @sorted_set.singleton(42)
  let result = set.rev_iter().collect()
  inspect(result, content="[42]")
}

///|
test "rev_iter early termination" {
  let set = @sorted_set.from_array([1, 2, 3, 4, 5])
  let result = set.rev_iter().take(3).collect()
  inspect(result, content="[5, 4, 3]")
}

///|
test "rev_iter on unbalanced insertion" {
  let set = @sorted_set.from_array([7, 2, 9, 4, 5, 6, 3, 8, 1])
  let result = set.rev_iter().collect()
  inspect(result, content="[9, 8, 7, 6, 5, 4, 3, 2, 1]")
}

///|
test "rev_iter is reverse of iter" {
  let set = @sorted_set.from_array([3, 1, 4, 1, 5, 9, 2, 6])
  let forward = set.iter().collect()
  let reverse = set.rev_iter().collect()
  assert_eq(reverse, forward.rev())
}

///|
test "rev_iter with early termination on right subtree" {
  // Create a binary search tree with both left and right subtrees
  let set = @sorted_set.new()
    .add(2) // root
    .add(1) // left child
    .add(3) // right child

  // Create an iter that stops after processing the first element (from right)
  let mut count = 0
  for _ in set.rev_iter() {
    count = count + 1
    if count == 1 {
      break
    }
  }

  // Verify that we stopped after processing the first element
  inspect(count, content="1")
}

///|
test "rev_iter with complex tree structure" {
  let set = @sorted_set.from_array([
    15, 10, 20, 5, 12, 18, 25, 3, 7, 11, 14, 17, 19, 23, 27,
  ])
  let result = set.rev_iter().collect()
  inspect(
    result,
    content="[27, 25, 23, 20, 19, 18, 17, 15, 14, 12, 11, 10, 7, 5, 3]",
  )
}

///|
test "rev_iter terminates on left" {
  let set = @sorted_set.from_array([1, 2, 3])
  let result = set.rev_iter().take(2).to_array()
  inspect(result, content="[3, 2]")
}
