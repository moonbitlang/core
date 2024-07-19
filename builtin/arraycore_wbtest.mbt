// Copyright 2024 International Digital Economy Academy
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

test "array_unsafe_blit_fixed" {
  let src = FixedArray::make(5, 0)
  let dst = UninitializedArray::make(5)
  for i = 0; i < 5; i = i + 1 {
    src[i] = i + 1
  }
  UninitializedArray::unsafe_blit_fixed(dst, 0, src, 0, 5)
  for i = 0; i < 5; i = i + 1 {
    assert_eq!(dst[i], src[i])
  }
}

test "array_resize_buffer" {
  let arr = Array::new(capacity=2)
  arr.push(1)
  arr.push(2)
  arr.resize_buffer(4)
  assert_eq!(arr.buffer().0.length() >= 4, true)
  arr.push(3)
  arr.push(4)
  assert_eq!(arr.length(), 4)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 2)
  assert_eq!(arr[2], 3)
  assert_eq!(arr[3], 4)
}

test "UninitializedArray::unsafe_blit_fixed" {
  let src = FixedArray::make(5, 0)
  let dst = UninitializedArray::make(5)
  for i = 0; i < 5; i = i + 1 {
    src[i] = i + 1
  }
  UninitializedArray::unsafe_blit_fixed(dst, 0, src, 0, 5)
  for i = 0; i < 5; i = i + 1 {
    assert_eq!(dst[i], src[i])
  }
}

test "Array::resize_buffer" {
  let arr = Array::new(capacity=2)
  arr.push(1)
  arr.push(2)
  arr.resize_buffer(4)
  assert_eq!(arr.buffer().0.length() >= 4, true)
  arr.push(3)
  arr.push(4)
  assert_eq!(arr.length(), 4)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 2)
  assert_eq!(arr[2], 3)
  assert_eq!(arr[3], 4)
}

test "UninitializedArray::unsafe_blit_fixed" {
  let src = FixedArray::make(5, 0)
  let dst = UninitializedArray::make(5)
  for i = 0; i < 5; i = i + 1 {
    src[i] = i + 1
  }
  UninitializedArray::unsafe_blit_fixed(dst, 0, src, 0, 5)
  for i = 0; i < 5; i = i + 1 {
    assert_eq!(dst[i], src[i])
  }
}

test "Array::resize_buffer" {
  let arr = Array::new(capacity=2)
  arr.push(1)
  arr.push(2)
  arr.resize_buffer(4)
  assert_eq!(arr.buffer().0.length() >= 4, true)
  arr.push(3)
  arr.push(4)
  assert_eq!(arr.length(), 4)
  assert_eq!(arr[0], 1)
  assert_eq!(arr[1], 2)
  assert_eq!(arr[2], 3)
  assert_eq!(arr[3], 4)
}
