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
test "Array::partition - slice-based with various ranges" {
  // Test 1: Partition entire array from start
  let arr1 = [3, 7, 1, 4, 6, 2, 5]
  let (pos1, partitioned1) = partition({ array: arr1, start: 0, end: 7 }, 3)
  inspect(pos1, content="3")
  inspect(partitioned1, content="false")
  inspect(arr1, content="[3, 1, 2, 4, 6, 7, 5]")

  // Test 2: Partition middle section of array
  let arr2 = [10, 20, 5, 3, 8, 1, 7, 30, 40]
  let (pos2, partitioned2) = partition({ array: arr2, start: 2, end: 7 }, 2) // pivot is 8 at relative index 2
  inspect(pos2, content="4")
  inspect(partitioned2, content="true")
  // Elements in range [2, 7): [5, 3, 8, 1, 7]
  // After partition with pivot 8: [5, 3, 1, 7, 8]
  inspect(arr2, content="[10, 20, 5, 3, 7, 1, 8, 30, 40]")

  // Test 3: Partition at the end of array
  let arr3 = [1, 2, 3, 9, 4, 6, 5]
  let (pos3, partitioned3) = partition({ array: arr3, start: 3, end: 7 }, 2) // pivot is 6 at relative index 2
  inspect(pos3, content="2")
  inspect(partitioned3, content="false")
  inspect(arr3, content="[1, 2, 3, 4, 5, 6, 9]")
}

///|
test "Array::partition - edge cases with slices" {
  // Test 2: Single element range
  let arr2 = [9, 8, 7, 6, 5]
  let (pos2, partitioned2) = partition({ array: arr2, start: 2, end: 3 }, 0) // Single element
  inspect(pos2, content="0")
  inspect(partitioned2, content="true")
  inspect(arr2[2], content="7")

  // Test 3: Two element range
  let arr3 = [1, 2, 8, 3, 5]
  let (pos3, _partitioned3) = partition({ array: arr3, start: 2, end: 4 }, 1) // pivot is 3 at relative index 1
  inspect(pos3, content="0")
  inspect(arr3, content="[1, 2, 3, 8, 5]")
}

///|
test "Array::partition - with duplicates" {
  // Test 1: Many duplicates of pivot value
  let arr1 = [3, 5, 2, 5, 1, 5, 4, 5, 6]
  let (pos1, _) = partition({ array: arr1, start: 0, end: 9 }, 1) // pivot is 5
  inspect(pos1, content="4")
  // Check that pivot is at the returned position
  inspect(arr1[pos1], content="5")
  // All elements before position should be < 5
  let mut all_less = true
  for i in 0..<pos1 {
    if arr1[i] >= 5 {
      all_less = false
      break
    }
  }
  inspect(all_less, content="true")

  // Test 2: All elements equal
  let arr2 = [7, 7, 7, 7, 7]
  let (pos2, partitioned2) = partition({ array: arr2, start: 0, end: 5 }, 2)
  inspect(pos2, content="0")
  inspect(partitioned2, content="true")
}

///|
test "Array::partition - already sorted arrays" {
  // Test 1: Already sorted ascending
  let arr1 = [1, 2, 3, 4, 5, 6, 7]
  let (pos1, partitioned1) = partition({ array: arr1, start: 0, end: 7 }, 3) // pivot is 4
  inspect(pos1, content="3")
  inspect(partitioned1, content="true")
  inspect(arr1, content="[1, 2, 3, 4, 5, 6, 7]")

  // Test 2: Already sorted descending
  let arr2 = [9, 8, 7, 6, 5, 4, 3, 2, 1]
  let (pos2, partitioned2) = partition({ array: arr2, start: 0, end: 9 }, 4) // pivot is 5
  inspect(pos2, content="4")
  inspect(partitioned2, content="false")
  // Elements < 5: [4, 3, 2, 1]
  let mut count = 0
  for i in 0..<pos2 {
    if arr2[i] < 5 {
      count += 1
    }
  }
  inspect(count, content="4")
}

///|
test "Array::partition - different pivot selections" {
  let arr = [8, 3, 5, 1, 9, 2, 7, 4, 6]

  // Test 1: First element as pivot
  let arr1 = arr.copy()
  let (pos1, _) = partition({ array: arr1, start: 0, end: 9 }, 0) // pivot is 8
  inspect(pos1, content="7")
  inspect(arr1[pos1], content="8")

  // Test 2: Last element as pivot  
  let arr2 = arr.copy()
  let (pos2, _) = partition({ array: arr2, start: 0, end: 9 }, 8) // pivot is 6
  inspect(pos2, content="5")
  inspect(arr2[pos2], content="6")

  // Test 3: Middle element as pivot
  let arr3 = arr.copy()
  let (pos3, _) = partition({ array: arr3, start: 0, end: 9 }, 4) // pivot is 9
  inspect(pos3, content="8")
  inspect(arr3[pos3], content="9")
}
