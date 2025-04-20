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
/// Creates a new bytes sequence from a byte array.
///
/// Parameters:
///
/// * `array` : An array of bytes to be converted.
///
/// Returns a new bytes sequence containing the same bytes as the input array.
///
/// Example:
///
/// ```moonbit
/// test "Bytes::from_array" {
///   let arr = [b'h', b'i']
///   let bytes = @bytes.from_array(arr)
///   inspect!(bytes, content=
///     #|b"\x68\x69"
///   )
/// }
/// ```
pub fn Bytes::from_array(arr : Array[Byte]) -> Bytes {
  Bytes::makei(arr.length(), fn(i) { arr[i] })
}

///|
/// same as `Bytes::from_array`
pub fn from_array(arr : Array[Byte]) -> Bytes {
  Bytes::makei(arr.length(), fn(i) { arr[i] })
}

///|
/// Creates a new bytes sequence from a fixed-size array of bytes with an
/// optional length parameter.
///
/// Parameters:
///
/// * `array` : A fixed-size array of bytes to be converted into a bytes
/// sequence.
/// * `length` : (Optional) The length of the resulting bytes sequence. If not
/// provided, uses the full length of the input array.
///
/// Returns a new bytes sequence containing the bytes from the input array. If a
/// length is specified, only includes up to that many bytes.
///
/// Example:
///
/// ```moonbit
/// test "Bytes::from_fixedarray" {
///   let arr : FixedArray[Byte] = [b'h', b'e', b'l', b'l', b'o']
///   let bytes = @bytes.from_fixedarray(arr, len=3)
///   inspect!(bytes, content=
///     #|b"\x68\x65\x6c"
///   )
/// }
/// ```
pub fn Bytes::from_fixedarray(arr : FixedArray[Byte], len? : Int) -> Bytes {
  let len = match len {
    None => arr.length()
    Some(x) => x
  }
  Bytes::makei(len, fn(i) { arr[i] })
}

///|
/// same as `Bytes::from_fixedarray`
pub fn from_fixedarray(arr : FixedArray[Byte], len? : Int) -> Bytes {
  Bytes::from_fixedarray(arr, len?)
}

///|
/// Converts a bytes sequence into a fixed-size array of bytes. If an optional
/// length is provided, the resulting array will have exactly that length,
/// otherwise it will match the length of the input bytes.
///
/// Parameters:
///
/// * `self` : The bytes sequence to convert.
/// * `len` : Optional. The desired length of the output array. If specified, the
/// resulting array will have this length. If not specified, the length of the
/// input bytes sequence will be used.
///
/// Returns a fixed-size array containing the bytes from the input sequence.
///
/// Example:
///
/// ```moonbit
/// test "Bytes::to_fixedarray" {
///   let bytes = b"hello"
///   let arr = bytes.to_fixedarray()
///   inspect!(arr, content="[b'\\x68', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F']")
///   let arr2 = bytes.to_fixedarray(len=3)
///   inspect!(arr2, content="[b'\\x68', b'\\x65', b'\\x6C']")
/// }
/// ```
pub fn to_fixedarray(self : Bytes, len? : Int) -> FixedArray[Byte] {
  let len = match len {
    None => self.length()
    Some(x) => x
  }
  let arr = FixedArray::make(len, Byte::default())
  for i in 0..<len {
    arr[i] = self[i]
  }
  arr
}

///|
/// Creates a new bytes sequence from an iterator of bytes.
///
/// Parameters:
///
/// * `iterator` : An iterator that yields bytes.
///
/// Returns a new bytes sequence containing all the bytes from the iterator.
///
/// Example:
///
/// ```moonbit
/// test "from_iter" {
///   let iter = Iter::singleton(b'h')
///   let bytes = @bytes.from_iter(iter)
///   inspect!(bytes, content=
///     #|b"\x68"
///   )
/// }
/// ```
pub fn Bytes::from_iter(iter : Iter[Byte]) -> Bytes {
  from_array(iter.collect())
}

///|
/// same as `Bytes::from_iter`
pub fn from_iter(iter : Iter[Byte]) -> Bytes {
  from_array(iter.collect())
}

///|
/// Creates a new bytes sequence from a fixed-size byte array.
///
/// Parameters:
///
/// * `array` : A fixed-size array of bytes to be converted into a bytes
/// sequence. Elements in the array should be of type `Byte`.
///
/// Returns a new bytes sequence containing the same bytes as the input array.
///
/// Example:
///
/// ```moonbit
/// test "of" {
///   let arr : FixedArray[Byte] = [b'h', b'e', b'l', b'l', b'o']
///   let bytes = @bytes.of(arr)
///   inspect!(bytes, content=
///     #|b"\x68\x65\x6c\x6c\x6f"
///   )
/// }
/// ```
/// TODO: marked as intrinsic, inline if it is constant
pub fn Bytes::of(arr : FixedArray[Byte]) -> Bytes {
  Bytes::makei(arr.length(), fn(i) { arr[i] })
}

///|
/// same as `Bytes::of`
pub fn of(arr : FixedArray[Byte]) -> Bytes {
  Bytes::makei(arr.length(), fn(i) { arr[i] })
}

///|
/// Converts a bytes sequence into an array of bytes.
///
/// Parameters:
///
/// * `bytes` : A sequence of bytes to be converted into an array.
///
/// Returns an array containing the same bytes as the input sequence.
///
/// Example:
///
/// ```moonbit
/// test "Bytes::to_array" {
///   let bytes = b"hello"
///   let arr = bytes.to_array()
///   inspect!(arr, content="[b'\\x68', b'\\x65', b'\\x6C', b'\\x6C', b'\\x6F']")
/// }
/// ```
pub fn to_array(self : Bytes) -> Array[Byte] {
  let rv = Array::make(self.length(), b'0')
  for i in 0..<self.length() {
    rv[i] = self[i]
  }
  rv
}

///|
/// Creates an iterator over the bytes in the sequence.
///
/// Parameters:
///
/// * `bytes` : A byte sequence to iterate over.
///
/// Returns an iterator that yields each byte in the sequence in order.
///
/// Example:
///
/// ```moonbit
/// test "Bytes::iter" {
///   let bytes = Bytes::from_array([b'h', b'i'])
///   let mut sum = 0
///   bytes.iter().each(fn(b) { sum = sum + b.to_int() })
///   inspect!(sum, content="209") // ASCII values: 'h'(104) + 'i'(105) = 209
/// }
/// ```
pub fn iter(self : Bytes) -> Iter[Byte] {
  Iter::new(fn(yield_) {
    for i = 0, len = self.length(); i < len; i = i + 1 {
      if yield_(self[i]) == IterEnd {
        break IterEnd
      }
    } else {
      IterContinue
    }
  })
}

///|
/// Creates a new empty bytes sequence.
///
/// Returns an empty bytes sequence.
///
/// Example:
///
/// ```moonbit
/// test "default" {
///   let bytes = @bytes.default()
///   inspect!(bytes, content="b\"\"")
///   inspect!(bytes.length(), content="0")
/// }
/// ```
pub impl Default for Bytes with default() {
  b""
}

///|
/// Retrieves a byte from the view at the specified index.
///
/// Parameters:
///
/// * `self` : The bytes view to retrieve the byte from.
/// * `index` : The position in the view from which to retrieve the byte.
///
/// Returns the byte at the specified index, or None if the index is out of bounds.
///
/// Example:
/// 
/// ```moonbit
/// test "Bytes::get" {
///   let bytes = b"\x01\x02\x03"
///   let byte = bytes.get(1)
///   inspect!(byte, content="Some(b'\\x02')")
/// }
/// test "Bytes::get/out_of_bounds" {
///   let bytes = b"\x01\x02\x03"
///   let byte = bytes.get(3)
///   inspect!(byte, content="None")
/// }
/// ```
pub fn get(self : Bytes, index : Int) -> Byte? {
  guard index >= 0 && index < self.length() else { None }
  Some(self[index])
}

///|
/// same as `Bytes::default`
pub fn default() -> Bytes {
  b""
}

///|
/// Reinterpret the byte sequence as Bytes.
fn unsafe_to_bytes(array : FixedArray[Byte]) -> Bytes = "%identity"

///|
/// Concatenates two bytes sequences.
///
/// Parameters:
///
/// * `self` : The first bytes sequence.
/// * `other` : The second bytes sequence.
/// TODO: marked as intrinsic, inline if it is constant
pub impl Add for Bytes with op_add(self : Bytes, other : Bytes) -> Bytes {
  let rv : FixedArray[Byte] = FixedArray::make(
    self.length() + other.length(),
    0,
  )
  for i in 0..<self.length() {
    rv[i] = self[i]
  }
  for i in 0..<other.length() {
    rv[self.length() + i] = other[i]
  }
  unsafe_to_bytes(rv)
}
