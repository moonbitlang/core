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

// Public-API tests for the views backed by `String::unsafe_range_equal` and
// `Bytes::unsafe_range_equal` (see range_equal_wbtest.mbt for the boundary
// tests of the primitives themselves).

///|
test "range equality through the public view APIs" {
  let text = "0123456789abcdef中文😀0123456789abcdef中文😀"
  let half = text.length() / 2
  let left = text[:half]
  let right = text[half:]
  assert_true(left == right)
  assert_true(text.has_prefix(right))
  assert_true(text.has_suffix(left))
  assert_true(left.equal_to_string(right.to_owned()))
  assert_false(text.has_prefix("0123456789abcdef中文😁"))
  assert_false(text[1:].has_suffix("0123456789abcdeg中文😀"))
  let bytes = b"0123456789abcdef0123456789abcdef!0123456789abcdef0123456789abcdef!"
  let bhalf = bytes.length() / 2
  assert_true(bytes[:bhalf] == bytes[bhalf:])
  assert_false(bytes[:bhalf - 1] == bytes[bhalf + 1:])
  assert_true(bytes[bhalf:].equal_to_bytes(bytes[:bhalf].to_owned()))
  debug_inspect(bytes.find(b"f!0123456789abcdef0"), content="Some(31)")
  debug_inspect(bytes.rev_find(b"0123456789abcdef0123"), content="Some(33)")
}

///|
test "quickcheck: StringView == agrees with a char-by-char comparison" {
  @quickcheck.check(
    (input : (Array[Byte], UInt, UInt, UInt, UInt)) => {
      let (seed, len0, lo0, ro0, pos0) = input
      let len = (len0 % 80).reinterpret_as_int()
      let lo = (lo0 % 9).reinterpret_as_int()
      let ro = (ro0 % 9).reinterpret_as_int()
      // small alphabet with a surrogate pair so random data collides often
      let alphabet : ReadOnlyArray[Char] = ['a', 'b', '😀', '中']
      let body = Array::makei(len, i => {
        let s = if seed.length() == 0 {
          0
        } else {
          seed[i % seed.length()].to_int()
        }
        alphabet[(s + i / 5) % alphabet.length()]
      })
      let other = body.copy()
      // mismatch at `pos` when it is inside the body, none otherwise
      let pos = (pos0 % (len.reinterpret_as_uint() + 1)).reinterpret_as_int()
      if pos < len {
        other[pos] = match other[pos] {
          'a' => 'b'
          'b' => 'a'
          '😀' => '😁'
          _ => '文'
        }
      }
      let left = String::make(lo, '.') + String::from_array(body) + "!"
      let right = String::make(ro, '?') + String::from_array(other)
      let body_units = left.length() - lo - 1
      let lview = left[lo:lo + body_units]
      let rview = right[ro:]
      let expected = body == other
      expected == (pos >= len) &&
      (lview == rview) == expected &&
      right.has_suffix(lview) == expected &&
      right[ro:].has_prefix(lview) == expected
    },
    count=500,
  )
}

///|
test "quickcheck: BytesView == agrees with a byte-by-byte comparison" {
  @quickcheck.check(
    (input : (Array[Byte], UInt, UInt, UInt, UInt)) => {
      let (seed, len0, lo0, ro0, pos0) = input
      let len = (len0 % 150).reinterpret_as_int()
      let lo = (lo0 % 17).reinterpret_as_int()
      let ro = (ro0 % 17).reinterpret_as_int()
      let body = Array::makei(len, i => {
        let s = if seed.length() == 0 {
          b'\x00'
        } else {
          seed[i % seed.length()]
        }
        s & 0x81
      })
      let other = body.copy()
      let pos = (pos0 % (len.reinterpret_as_uint() + 1)).reinterpret_as_int()
      if pos < len {
        other[pos] = other[pos] ^ 0x80
      }
      let left = Bytes::from_array(Array::make(lo, b'.') + body + [b'!'])
      let right = Bytes::from_array(Array::make(ro, b'?') + other)
      let expected = body == other
      expected == (pos >= len) &&
      (left[lo:lo + len] == right[ro:]) == expected &&
      left[lo:lo + len].equal_to_bytes(Bytes::from_array(other)) == expected
    },
    count=500,
  )
}
