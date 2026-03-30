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
#cfg(not(target="js"))
fn out_of_index(len : Int, index : Int, index2? : Int) -> String {
  let pre = "index out of bounds: the length is "
  let pre_length = 35
  let mid = " but the index is "
  let mid_length = 18
  let len = len.to_string()
  let index = index.to_string()
  let and_ = " and "
  let and_length = 5
  let index2_str = if index2 is Some(i) { i.to_string() } else { "" }

  let data : FixedArray[UInt16] = if index2 is Some(_) {
    FixedArray::make(
      pre_length +
      len.length() +
      mid_length +
      index.length() +
      and_length +
      index2_str.length(),
      0,
    )
  } else {
    FixedArray::make(pre_length + len.length() + mid_length + index.length(), 0)
  }

  // TODO : add blit intrinsic to copy string to fixed array
  let mut offset = 0
  for i in 0..<pre_length {
    data[i] = pre[i]
  }
  offset += pre_length
  for i in 0..<len.length() {
    data[offset + i] = len[i]
  }
  offset += len.length()
  for i in 0..<mid_length {
    data[offset + i] = mid[i]
  }
  offset += mid_length
  for i in 0..<index.length() {
    data[offset + i] = index[i]
  }
  if index2 is Some(_) {
    offset += index.length()
    for i in 0..<and_length {
      data[offset + i] = and_[i]
    }
    for i in 0..<index2_str.length() {
      data[offset + and_length + i] = index2_str[i]
    }
  }
  unsafe_fixedarray_uint16_to_string(data)
}

///|
#cfg(target="js")
fn out_of_index(len : Int, index : Int, index2? : Int) -> String {
  if index2 is Some(i) {
    "index out of bounds: the length is " +
    len.to_string() +
    " but the index is " +
    index.to_string() +
    " and " +
    i.to_string()
  } else {
    "index out of bounds: the length is " +
    len.to_string() +
    " but the index is " +
    index.to_string()
  }
}

///|
test "out of index msg" {
  let pre = "index out of bounds: the length is "
  inspect(
    pre.length(),
    content=(
      #|35
    ),
  )
  let mid = " but the index is "
  inspect(
    mid.length(),
    content=(
      #|18
    ),
  )
  let msg = out_of_index(10, 20)
  inspect(
    msg,
    content=(
      #|index out of bounds: the length is 10 but the index is 20
    ),
  )
  let msg2 = out_of_index(100, -10)
  inspect(
    msg2,
    content=(
      #|index out of bounds: the length is 100 but the index is -10
    ),
  )
  let msg3 = out_of_index(50, 60, index2=70)
  inspect(
    msg3,
    content=(
      #|index out of bounds: the length is 50 but the index is 60 and 70
    ),
  )
}
