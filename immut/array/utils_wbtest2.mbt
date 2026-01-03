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
test "immutable_set" {
  let arr = FixedArray::from_array([1, 2, 3, 4, 5])
  let new_arr = immutable_set(arr, 2, 10)
  inspect(new_arr[2], content="10")
  inspect(arr[2], content="3") // Original array unchanged
  inspect(new_arr.length(), content="5")
}

///|
test "immutable_push" {
  let arr = FixedArray::from_array([1, 2, 3])
  let new_arr = immutable_push(arr, 4)
  inspect(new_arr.length(), content="4")
  inspect(new_arr[3], content="4")
  inspect(arr.length(), content="3") // Original array unchanged
}

///|
test "shr_as_uint" {
  inspect(shr_as_uint(16, 2), content="4")
  inspect(shr_as_uint(8, 1), content="4")
  inspect(shr_as_uint(-1, 1), content="2147483647") // Handle negative numbers as unsigned
}

///|
test "radix_indexing" {
  // Assuming bitmask is 31 (0x1F) for 5 bits
  inspect(radix_indexing(35, 5), content="1") // 35 >> 5 = 1, 1 & 31 = 1
  inspect(radix_indexing(100, 5), content="3") // 100 >> 5 = 3, 3 & 31 = 3
  inspect(radix_indexing(7, 5), content="0") // 7 >> 5 = 0, 0 & 31 = 0
}

///|
test "get_branch_index" {
  let sizes = FixedArray::from_array([3, 6, 10, 15])
  inspect(get_branch_index(sizes, 2), content="0") // Index 2 is in first branch (contains indexes 0-2)
  inspect(get_branch_index(sizes, 5), content="1") // Index 5 is in second branch (contains indexes 3-5)
  inspect(get_branch_index(sizes, 8), content="2") // Index 8 is in third branch (contains indexes 6-9)
}

///|
test "copy_sizes with Some" {
  let original = FixedArray::from_array([1, 2, 3])
  let sizes = Some(original)
  let copied = copy_sizes(sizes)
  match copied {
    Some(copied_arr) => {
      inspect(copied_arr.length(), content="3")
      inspect(copied_arr[0], content="1")
      inspect(copied_arr[1], content="2")
      inspect(copied_arr[2], content="3")
      // Verify it's a copy by modifying original
      original[0] = 100
      inspect(copied_arr[0], content="1") // Should still be 1
    }
    None => inspect("Should not be None", content="error")
  }
}

///|
test "copy_sizes with None" {
  let sizes : FixedArray[Int]? = None
  let copied = copy_sizes(sizes)
  match copied {
    None => inspect("None copied correctly", content="None copied correctly")
    Some(_) => inspect("Should be None", content="error")
  }
}

///|
test "min function" {
  inspect(min(5, 3), content="3")
  inspect(min(1, 10), content="1")
  inspect(min(-5, 0), content="-5")
  inspect(min(42, 42), content="42")
}
