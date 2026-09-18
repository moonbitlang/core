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
test "need_escape SIMD blocks and scalar tail" {
  let cases : Array[(String, Bool, Bool)] = [
    ("", false, false),
    ("0123456", false, false),
    ("01234567", false, false),
    ("012345678", false, false),
    ("0123456\"", false, true),
    ("01234567\\", false, true),
    ("012345678901234\n", false, true),
    ("01234567/89", false, false),
    ("01234567/89", true, true),
    ("0123456😀", false, false),
  ]
  for case in cases {
    let (str, escape_slash, expected) = case
    assert_true(need_escape(str, escape_slash) == expected)
  }
}

///|
/// Exhaustively places each escapable code unit at every position of an
/// otherwise clean string, for every length spanning several 8-unit SIMD
/// blocks, so block starts, block interiors, and the scalar tail are all
/// covered for both `escape_slash` values.
test "need_escape boundary sweep" {
  let specials : Array[UInt16] = ['"', '\\', '\n', 0x00, 0x1F]
  fn place(len : Int, pos : Int, special : UInt16) -> String {
    let buf = StringBuilder(size_hint=len)
    for i in 0..<len {
      if i == pos {
        buf.write_char(special.unsafe_to_char())
      } else {
        buf.write_char('a')
      }
    }
    buf.to_string()
  }

  for len in 0..<=24 {
    let clean = "a".repeat(len)
    assert_false(need_escape(clean, false))
    assert_false(need_escape(clean, true))
    for pos in 0..<len {
      for special in specials {
        assert_true(need_escape(place(len, pos, special), false))
        assert_true(need_escape(place(len, pos, special), true))
      }
      let with_slash = place(len, pos, '/')
      assert_false(need_escape(with_slash, false))
      assert_true(need_escape(with_slash, true))
    }
  }
}

///|
test "need_escape SIMD agrees with scalar across all code units" {
  for code in 0..<0x10000 {
    let buf = StringBuilder()
    buf.write_string("aaaaaaa")
    buf.write_char(code.to_uint16().unsafe_to_char())
    let str = buf.to_string()
    for escape_slash in [false, true] {
      assert_true(
        need_escape(str, escape_slash) ==
        need_escape_scalar(str, escape_slash, 0, str.length()),
      )
    }
  }
}

///|
test "Json methods and conversion are available inside builtin" {
  let value : Json = {
    "name": "hello",
    "secret": true,
    "items": [{ "secret": false, "n": 2 }],
  }
  inspect(
    Json(value).stringify(),
    content=(
      #|{"name":"hello","secret":true,"items":[{"secret":false,"n":2}]}
    ),
  )
  let replacer = Replacer::exclude(["secret"])
  inspect(
    value.stringify(replacer~),
    content=(
      #|{"name":"hello","items":[{"n":2}]}
    ),
  )
  inspect(
    value.transform(replacer).stringify(),
    content=(
      #|{"name":"hello","items":[{"n":2}]}
    ),
  )
}
