// Copyright 2025 International Digital Economy Academy
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
  let set1 = @sorted_set.of([1, 2, 3])
  let set2 = @sorted_set.of([1, 2, 4])
  assert_false(set1 == set2)
}

///|
test "compare with shared prefix" {
  let set1 = @sorted_set.of([1, 2, 3])
  let set2 = @sorted_set.of([1, 2, 4])
  assert_true(set1 < set2)
}

///|
test "iter early termination - value" {
  let set = @sorted_set.of([1, 2, 3])
  let mut count = 0
  let _ = set
    .iter()
    .run(x => if x == 2 {
      IterEnd
    } else {
      count = count + 1
      IterContinue
    })
  inspect(count, content="1")
}

///|
test "iter terminates on right" {
  let set = @sorted_set.of([1, 2, 3])
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
  let _ = iter.run((_ : Int) => {
    count = count + 1
    if count == 1 {
      IterEnd
    } else {
      IterContinue
    }
  })

  // Verify that we stopped after processing the first element
  inspect(count, content="1")
}

///|
test "iterator" {
  let set = @sorted_set.of([2, 1, 3])
  let result = set.iterator().collect()
  inspect(result, content="[1, 2, 3]")
}
