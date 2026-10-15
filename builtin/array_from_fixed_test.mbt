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
test "from_fixed_array consumes full value and reference buffers" {
  let arr = Array::from_fixed_array(FixedArray::makei(3, i => [i]))
  arr[1] = [8]
  arr.push([9])
  debug_inspect(arr, content="[[0], [8], [2], [9]]")
  let wide = FixedArray::makei(3, i => 0x1_0000_0000L + i.to_int64())
  debug_inspect(
    Array::from_fixed_array(wide),
    content="[4294967296, 4294967297, 4294967298]",
  )
  debug_inspect(Array::from_fixed_array(([] : FixedArray[Int32])), content="[]")
}

///|
test "from_fixed_array preserves shared source and surviving view independence" {
  let source = FixedArray::makei(3, i => i)
  let arr = Array::from_fixed_array(source)
  arr[0] = 9
  source[1] = 8
  debug_inspect(source, content="<FixedArray: [0, 8, 2]>")
  debug_inspect(arr, content="[9, 1, 2]")
  let source = FixedArray::makei(3, i => i)
  let view = source[:]
  let arr = Array::from_fixed_array(source)
  arr[0] = 8
  debug_inspect(view, content="<ArrayView: [0, 1, 2]>")
}

///|
#borrow(arr)
#inline(never)
fn array_from_borrowed_fixed(arr : FixedArray[Int32]) -> Array[Int32] {
  Array::from_fixed_array(arr)
}

///|
test "from_fixed_array retains borrowed caller ownership" {
  let fixed = FixedArray::makei(3, i => i)
  let arr = array_from_borrowed_fixed(fixed)
  arr[0] = 6
  debug_inspect(fixed, content="<FixedArray: [0, 1, 2]>")
}

///|
test "from_fixed_array preserves shallow reference sharing" {
  let element = [1]
  let source = FixedArray::make(2, element)
  let arr = Array::from_fixed_array(source)
  source[0] = [9]
  element[0] = 7
  debug_inspect(source, content="<FixedArray: [[9], [7]]>")
  debug_inspect(arr, content="[[7], [7]]")
}
