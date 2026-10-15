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
test "to_owned consumes full buffers of values and references" {
  let arr = Array::makei(4, i => i + 1)[:].to_owned()
  arr[0] = 9
  arr.push(5)
  debug_inspect(arr, content="[9, 2, 3, 4, 5]")
  let arr = Array::makei(3, i => [i])[:].to_owned()
  arr[0] = [7]
  debug_inspect(arr, content="[[7], [1], [2]]")
  debug_inspect(
    Array::makei(3, i => i.to_double() + 0.5)[:].to_owned(),
    content="[0.5, 1.5, 2.5]",
  )
}

///|
test "to_owned preserves shared arrays and surviving views" {
  let source = Array::makei(3, i => i)
  let mutate = () => source[0] = 9
  let arr = source[:].to_owned()
  mutate()
  arr[1] = 8
  debug_inspect(source, content="[9, 1, 2]")
  debug_inspect(arr, content="[0, 8, 2]")
  let view = FixedArray::makei(3, i => i)[:]
  let arr = view.to_owned()
  arr[0] = 7
  debug_inspect(view, content="<ArrayView: [0, 1, 2]>")
}

///|
#borrow(view)
#inline(never)
fn owned_from_borrowed_view(view : ArrayView[Int32]) -> Array[Int32] {
  view.to_owned()
}

///|
test "to_owned retains borrowed caller ownership" {
  let view = FixedArray::makei(3, i => i)[:]
  let arr = owned_from_borrowed_view(view)
  arr[0] = 9
  debug_inspect(view, content="<ArrayView: [0, 1, 2]>")
}

///|
test "to_owned respects unique slice bounds and spare capacity" {
  for start in 0..<=4 {
    for end in start..<=4 {
      let arr = Array::makei(4, i => [i])[start:end].to_owned()
      assert_eq(arr.length(), end - start)
      for i in 0..<(end - start) {
        assert_eq(arr[i][0], start + i)
      }
    }
  }
  let arr : Array[Array[Int32]] = Array(capacity=8)
  arr.push([1])
  arr.push([2])
  debug_inspect(arr[:].to_owned(), content="[[1], [2]]")
  let arr = Array::makei(8, i => [i])
  arr.clear()
  arr.push([9])
  debug_inspect(arr[:].to_owned(), content="[[9]]")
  let arr = Array::makei(8, i => [i])
  arr.clear()
  debug_inspect(arr[:].to_owned(), content="[]")
}

///|
let to_owned_static_source : ReadOnlyArray[Int32] = [1, 2, 3]

///|
test "to_owned preserves constants and shallow element sharing" {
  let arr = to_owned_static_source[:].to_owned()
  arr[0] = 9
  debug_inspect(to_owned_static_source, content="<ReadOnlyArray: [1, 2, 3]>")
  let element = [1]
  let source = FixedArray::make(2, element)
  let arr = source[:].to_owned()
  source[0] = [9]
  element[0] = 7
  debug_inspect(source, content="<FixedArray: [[9], [7]]>")
  debug_inspect(arr, content="[[7], [7]]")
}
