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
test "Bytes::from_array empty inputs" {
  inspect(Bytes::from_array(([] : Array[Byte])), content="b\"\"")
  inspect(Bytes::from_array(([] : FixedArray[Byte])), content="b\"\"")
  let arr = FixedArray::make(3, b'a')
  inspect(Bytes::from_array(arr[3:3]), content="b\"\"")
  let arr : Array[Byte] = Array(capacity=8)
  inspect(Bytes::from_array(arr), content="b\"\"")
}

///|
test "Bytes::from_array consumes full buffers" {
  let fixed = FixedArray::makei(4, i => (i * 85).to_byte())
  inspect(Bytes::from_array(fixed), content="b\"\\x00U\\xaa\\xff\"")
  let dynamic = Array::makei(4, i => (i * 85).to_byte())
  inspect(Bytes::from_array(dynamic), content="b\"\\x00U\\xaa\\xff\"")
  let view = FixedArray::makei(3, i => (97 + i).to_byte())[:]
  inspect(Bytes::from_array(view), content="b\"abc\"")
}

///|
test "Bytes::from_array preserves fixed array independence" {
  let arr : FixedArray[Byte] = [b'a', b'b', b'c']
  let bytes = Bytes::from_array(arr)
  arr[0] = b'z'
  inspect(bytes, content="b\"abc\"")
  inspect(
    arr[0],
    content=(
      #|b'\x7A'
    ),
  )
}

///|
test "Bytes::from_array preserves dynamic array independence" {
  let arr : Array[Byte] = [b'a', b'b', b'c']
  let bytes = Bytes::from_array(arr)
  arr[0] = b'z'
  arr.push(b'd')
  inspect(bytes, content="b\"abc\"")
  inspect(Bytes::from_array(arr), content="b\"zbcd\"")
}

///|
test "Bytes::from_array accounts for captured aliases" {
  let arr : Array[Byte] = [b'a', b'b', b'c']
  let mutate = () => arr[0] = b'z'
  let bytes = Bytes::from_array(arr)
  mutate()
  inspect(bytes, content="b\"abc\"")
}

///|
test "Bytes::from_array accounts for mutable buffer views" {
  let arr : Array[Byte] = [b'a', b'b', b'c']
  let view = arr.mut_view()
  let bytes = Bytes::from_array(arr)
  view[1] = b'z'
  inspect(bytes, content="b\"abc\"")
  inspect(view[1], content="b'\\x7A'")
}

///|
#borrow(arr)
#inline(never)
fn bytes_from_borrowed_array(arr : FixedArray[Byte]) -> Bytes {
  Bytes::from_array(arr)
}

///|
test "Bytes::from_array preserves borrowed caller ownership" {
  let arr : FixedArray[Byte] = [b'a', b'b', b'c']
  let bytes = bytes_from_borrowed_array(arr)
  arr[0] = b'z'
  inspect(bytes, content="b\"abc\"")
  inspect(
    arr[0],
    content=(
      #|b'\x7A'
    ),
  )
}

///|
test "Bytes::from_array respects unique slice bounds" {
  let arr = FixedArray::makei(4, i => (97 + i).to_byte())
  inspect(Bytes::from_array(arr[:3]), content="b\"abc\"")
  let arr = FixedArray::makei(4, i => (97 + i).to_byte())
  inspect(Bytes::from_array(arr[1:]), content="b\"bcd\"")
  let arr = FixedArray::makei(4, i => (97 + i).to_byte())
  inspect(Bytes::from_array(arr[1:3]), content="b\"bc\"")
}

///|
test "Bytes::from_array omits spare capacity" {
  let arr : Array[Byte] = Array(capacity=8)
  arr.push(b'a')
  arr.push(b'b')
  arr.push(b'c')
  inspect(Bytes::from_array(arr), content="b\"abc\"")
  let arr = Array::make(8, b'z')
  arr.clear()
  arr.push(b'a')
  arr.push(b'b')
  inspect(Bytes::from_array(arr), content="b\"ab\"")
}

///|
test "Bytes::from_array preserves shared views and readonly arrays" {
  let arr = FixedArray::makei(3, i => (97 + i).to_byte())
  let view = arr[:]
  let first = Bytes::from_array(view)
  let second = Bytes::from_array(view)
  inspect(first, content="b\"abc\"")
  inspect(second, content="b\"abc\"")
  let read_only : ReadOnlyArray[Byte] = [b'a', b'b', b'c']
  inspect(Bytes::from_array(read_only), content="b\"abc\"")
  inspect(read_only[0], content="b'\\x61'")
}
