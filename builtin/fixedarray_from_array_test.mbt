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
test "fixed and readonly conversions consume full reference buffers" {
  let fixed = FixedArray::from_array(Array::makei(3, i => [i]))
  fixed[1][0] = 8
  fixed[2] = [9]
  debug_inspect(fixed, content="<FixedArray: [[0], [8], [9]]>")
  let immutable = ReadOnlyArray::from_array(Array::makei(3, i => [i]))
  debug_inspect(immutable, content="<ReadOnlyArray: [[0], [1], [2]]>")
  let bytes = FixedArray::from_array(Array::makei(3, i => i.to_byte()))
  bytes[1] = b'z'
  inspect(Bytes::from_array(bytes), content="b\"\\x00z\\x02\"")
  let optional = FixedArray::from_array(
    Array::makei(3, i => if i == 1 { None } else { Some([i]) }),
  )
  debug_inspect(optional, content="<FixedArray: [Some([0]), None, Some([2])]>")
}

///|
test "fixed and readonly conversions preserve surviving aliases" {
  let arr = Array::makei(3, i => i)
  let mutate = () => arr[0] = 9
  let fixed = FixedArray::from_array(arr)
  let immutable = ReadOnlyArray::from_array(arr)
  mutate()
  fixed[1] = 8
  debug_inspect(arr, content="[9, 1, 2]")
  debug_inspect(fixed, content="<FixedArray: [0, 8, 2]>")
  debug_inspect(immutable, content="<ReadOnlyArray: [0, 1, 2]>")
  let arr = Array::makei(3, i => i)
  let mutable_view = arr.mut_view()
  let fixed = FixedArray::from_array(arr)
  let immutable = ReadOnlyArray::from_array(arr)
  mutable_view[0] = 6
  debug_inspect(fixed, content="<FixedArray: [0, 1, 2]>")
  debug_inspect(immutable, content="<ReadOnlyArray: [0, 1, 2]>")
  let view = FixedArray::makei(3, i => i)[:]
  let fixed = FixedArray::from_array(view)
  fixed[0] = 7
  debug_inspect(view, content="<ArrayView: [0, 1, 2]>")
}

///|
#borrow(view)
#inline(never)
fn fixed_from_borrowed_view(view : ArrayView[Int32]) -> FixedArray[Int32] {
  FixedArray::from_array(view)
}

///|
#borrow(view)
#inline(never)
fn readonly_from_borrowed_view(view : ArrayView[Int32]) -> ReadOnlyArray[Int32] {
  ReadOnlyArray::from_array(view)
}

///|
test "fixed and readonly conversions retain borrowed caller ownership" {
  let view = FixedArray::makei(3, i => i)[:]
  let fixed = fixed_from_borrowed_view(view)
  fixed[0] = 8
  debug_inspect(view, content="<ArrayView: [0, 1, 2]>")
  let fixed = FixedArray::makei(3, i => i)
  let immutable = readonly_from_borrowed_view(fixed)
  fixed[0] = 7
  debug_inspect(immutable, content="<ReadOnlyArray: [0, 1, 2]>")
}

///|
fn fixed_conversion_spare_capacity() -> Array[Array[Int32]] {
  let arr : Array[Array[Int32]] = Array(capacity=8)
  arr.push([1])
  arr.push([2])
  arr
}

///|
test "fixed and readonly conversions respect slices and spare capacity" {
  for start in 0..<=4 {
    for end in start..<=4 {
      let fixed = FixedArray::from_array(
        FixedArray::makei(4, i => [i])[start:end],
      )
      let immutable = ReadOnlyArray::from_array(
        Array::makei(4, i => [i])[start:end],
      )
      assert_eq(fixed.length(), end - start)
      assert_eq(immutable.length(), end - start)
      for i in 0..<(end - start) {
        assert_eq(fixed[i][0], start + i)
        assert_eq(immutable[i][0], start + i)
      }
    }
  }
  debug_inspect(
    FixedArray::from_array(fixed_conversion_spare_capacity()),
    content="<FixedArray: [[1], [2]]>",
  )
  debug_inspect(
    ReadOnlyArray::from_array(fixed_conversion_spare_capacity()),
    content="<ReadOnlyArray: [[1], [2]]>",
  )
  let arr = Array::makei(8, i => [i])
  arr.clear()
  arr.push([9])
  debug_inspect(FixedArray::from_array(arr), content="<FixedArray: [[9]]>")
}

///|
let fixed_conversion_static_source : ReadOnlyArray[Int32] = [1, 2, 3]

///|
test "fixed and readonly conversions preserve constants and shallow sharing" {
  let fixed = FixedArray::from_array(fixed_conversion_static_source)
  fixed[1] = 8
  debug_inspect(
    fixed_conversion_static_source,
    content="<ReadOnlyArray: [1, 2, 3]>",
  )
  let element = [1]
  let source = FixedArray::make(2, element)
  let fixed = FixedArray::from_array(source)
  let immutable = ReadOnlyArray::from_array(source)
  source[0] = [9]
  element[0] = 7
  debug_inspect(source, content="<FixedArray: [[9], [7]]>")
  debug_inspect(fixed, content="<FixedArray: [[7], [7]]>")
  debug_inspect(immutable, content="<ReadOnlyArray: [[7], [7]]>")
}
