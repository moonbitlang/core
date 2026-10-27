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

// Public-API tests for string ranges and views backed by
// `String::unsafe_range_equal` and `Bytes::unsafe_range_equal`. See
// range_equal_wbtest.mbt for boundary tests of the primitives themselves.

///|
test "String range equality basics and empty ranges" {
  inspect(
    "xhello".range_equal("hello!", start=1, other_start=0, len=5),
    content="true",
  )
  inspect(
    "xhello".unsafe_range_equal("hello!", start=1, other_start=0, len=5),
    content="true",
  )
  inspect(
    "hello".range_equal("hallo", start=0, other_start=0, len=5),
    content="false",
  )
  inspect(
    "hello".unsafe_range_equal("hallo", start=0, other_start=0, len=5),
    content="false",
  )
  inspect(
    "abcabc".range_equal("abcabc", start=0, other_start=3, len=3),
    content="true",
  )
  inspect(
    "abcabc".unsafe_range_equal("abcabc", start=0, other_start=3, len=3),
    content="true",
  )
  inspect("".range_equal("", start=0, other_start=0, len=0), content="true")
  inspect(
    "".unsafe_range_equal("", start=0, other_start=0, len=0),
    content="true",
  )
  inspect(
    "abc".range_equal("xy", start=3, other_start=2, len=0),
    content="true",
  )
  inspect(
    "abc".unsafe_range_equal("xy", start=3, other_start=2, len=0),
    content="true",
  )
}

///|
test "String range equality permits boundaries inside surrogate pairs" {
  // U+1F600 and U+1F601 share the high surrogate D83D, but differ in the low one.
  inspect(
    "😀".range_equal("😁", start=0, other_start=0, len=1),
    content="true",
  )
  inspect(
    "😀".unsafe_range_equal("😁", start=0, other_start=0, len=1),
    content="true",
  )
  inspect(
    "😀".range_equal("😁", start=1, other_start=1, len=1),
    content="false",
  )
  inspect(
    "😀".unsafe_range_equal("😁", start=1, other_start=1, len=1),
    content="false",
  )
  // Start inside the same surrogate pair at different absolute offsets.
  inspect(
    "😀".range_equal("x😀", start=1, other_start=2, len=1),
    content="true",
  )
  inspect(
    "😀".unsafe_range_equal("x😀", start=1, other_start=2, len=1),
    content="true",
  )
  inspect(
    "😀".range_equal("😁", start=1, other_start=1, len=0),
    content="true",
  )
  inspect(
    "😀".unsafe_range_equal("😁", start=1, other_start=1, len=0),
    content="true",
  )
  // A failed literal comparison may end halfway through an input character.
  inspect(
    "abcdef😀".range_equal("abcdefg", start=0, other_start=0, len=7),
    content="false",
  )
  inspect(
    "abcdef😀".unsafe_range_equal("abcdefg", start=0, other_start=0, len=7),
    content="false",
  )
}

///|
test "String range equality agrees with code unit comparison" {
  let left = "prefix:A😀B中😁C:suffix"
  let right = "prefix:Z😀B文😁D:suffix"
  for start in 0..<=left.length() {
    for other_start in 0..<=right.length() {
      let max_len = (left.length() - start).min(right.length() - other_start)
      for len in 0..<=max_len {
        let mut expected = true
        for i in 0..<len {
          if left[start + i] != right[other_start + i] {
            expected = false
            break
          }
        }
        assert_eq(left.range_equal(right, start~, other_start~, len~), expected)
        assert_eq(
          left.unsafe_range_equal(right, start~, other_start~, len~),
          expected,
        )
      }
    }
  }
}

///|
test "StringView range equality uses view-relative starts" {
  let left = "xxhelloworld!"[2:12]
  let right = "yyyworldhello?"[3:13]
  inspect(
    left.range_equal(right, start=0, other_start=5, len=5),
    content="true",
  )
  inspect(
    left.range_equal(right, start=5, other_start=0, len=5),
    content="true",
  )
  inspect(
    left.range_equal(right, start=0, other_start=0, len=5),
    content="false",
  )
  let repeated = "xabcabcy"[1:7]
  inspect(
    repeated.range_equal(repeated, start=0, other_start=3, len=3),
    content="true",
  )
  inspect(
    left.range_equal(right, start=10, other_start=10, len=0),
    content="true",
  )
  let empty = "prefix:suffix"[7:7]
  inspect(
    empty.range_equal(empty, start=0, other_start=0, len=0),
    content="true",
  )
}

///|
test "StringView range equality permits boundaries inside surrogate pairs" {
  let left = "x😀y"[1:3]
  let right = "zz😁w"[2:4]
  inspect(
    left.range_equal(right, start=0, other_start=0, len=1),
    content="true",
  )
  inspect(
    left.range_equal(right, start=1, other_start=1, len=1),
    content="false",
  )
  inspect(
    left.range_equal(right, start=1, other_start=1, len=0),
    content="true",
  )
  inspect(
    left.range_equal("q😀"[1:], start=1, other_start=1, len=1),
    content="true",
  )
  inspect(
    "xabcdef😀y"[1:9].range_equal("abcdefg", start=0, other_start=0, len=7),
    content="false",
  )
}

///|
test "StringView range equality agrees with code unit comparison" {
  let left = "prefix:A😀B中😁C:suffix"[7:15]
  let right = "xxZ😀B文😁Dyy"[2:10]
  for start in 0..<=left.length() {
    for other_start in 0..<=right.length() {
      let max_len = (left.length() - start).min(right.length() - other_start)
      for len in 0..<=max_len {
        let mut expected = true
        for i in 0..<len {
          if left[start + i] != right[other_start + i] {
            expected = false
            break
          }
        }
        assert_eq(left.range_equal(right, start~, other_start~, len~), expected)
      }
    }
  }
}

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
    (input : (Array[Byte], UInt32, UInt32, UInt32, UInt32)) => {
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
    (input : (Array[Byte], UInt32, UInt32, UInt32, UInt32)) => {
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
