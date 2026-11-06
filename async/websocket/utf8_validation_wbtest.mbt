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
/// Validate `bytes` in one go and return the final state or the error.
fn check(bytes : Array[Byte], remaining~ : Int32 = 0) -> String {
  try verify_utf8(Bytes::from_array(bytes), remaining~) catch {
    err => @debug.to_string(err)
  } noraise {
    state => state.to_string()
  }
}

///|
test "validate utf8 single byte" {
  inspect(check([0x79]), content="0")
  inspect(check([0x00, 0x7f]), content="0")
}

///|
test "validate utf8 two bytes" {
  inspect(check([0xc2]), content="1")
  inspect(check([0xc2, 0x80]), content="0")
  inspect(check([0xdf, 0xbf]), content="0")
  inspect(check([0xc2, 0x79]), content="InvalidUtf8(1)")
  // overlong encodings of U+0000..U+007F
  inspect(check([0xc0, 0x80]), content="InvalidUtf8(0)")
  inspect(check([0xc1, 0xbf]), content="InvalidUtf8(0)")
}

///|
test "validate utf8 three bytes" {
  inspect(check([0xe1]), content="2")
  inspect(check([0xe1, 0x80]), content="1")
  inspect(check([0xef, 0xbf, 0xbf]), content="0")
  inspect(check([0xe0, 0xa0, 0x80]), content="0")
  inspect(check([0xed, 0x9f, 0xbf]), content="0")
  inspect(check([0xe1, 0x79]), content="InvalidUtf8(1)")
  inspect(check([0xe1, 0x80, 0x79]), content="InvalidUtf8(2)")
  // overlong encodings below U+0800
  inspect(check([0xe0]), content="4")
  inspect(check([0xe0, 0x80, 0x80]), content="InvalidUtf8(1)")
  inspect(check([0xe0, 0x9f, 0xbf]), content="InvalidUtf8(1)")
  // UTF-16 surrogates U+D800..U+DFFF
  inspect(check([0xed]), content="5")
  inspect(check([0xed, 0xa0, 0x80]), content="InvalidUtf8(1)")
  inspect(check([0xed, 0xbf, 0xbf]), content="InvalidUtf8(1)")
}

///|
test "validate utf8 four bytes" {
  inspect(check([0xf1]), content="3")
  inspect(check([0xf1, 0x80]), content="2")
  inspect(check([0xf1, 0x80, 0x80]), content="1")
  inspect(check([0xf0, 0x90, 0x80, 0x80]), content="0")
  inspect(check([0xf4, 0x8f, 0xbf, 0xbf]), content="0")
  inspect(check([0xf1, 0x79]), content="InvalidUtf8(1)")
  inspect(check([0xf1, 0x80, 0x80, 0x79]), content="InvalidUtf8(3)")
  inspect(check([0xf1, 0x80, 0x80, 0x80, 0x79]), content="0")
  // overlong encodings below U+10000
  inspect(check([0xf0]), content="6")
  inspect(check([0xf0, 0x80, 0x80, 0x80]), content="InvalidUtf8(1)")
  inspect(check([0xf0, 0x8f, 0xbf, 0xbf]), content="InvalidUtf8(1)")
  // above U+10FFFF
  inspect(check([0xf4]), content="7")
  inspect(check([0xf4, 0x90, 0x80, 0x80]), content="InvalidUtf8(1)")
  inspect(check([0xf5, 0x80, 0x80, 0x80]), content="InvalidUtf8(0)")
  inspect(check([0xf7, 0x80, 0x80, 0x80]), content="InvalidUtf8(0)")
}

///|
test "invalid utf8 first byte" {
  let bytes : Array[Byte] = [0x80, 0xbf, 0xc0, 0xc1, 0xf5, 0xf8, 0xff]
  for b in bytes {
    @test.assert_eq(check([b]), "InvalidUtf8(0)")
  }
}

///|
test "validate utf8 in the middle" {
  inspect(check([0x79], remaining=1), content="InvalidUtf8(0)")
  inspect(check([0xc2], remaining=1), content="InvalidUtf8(0)")
  inspect(check([0x80], remaining=1), content="0")
  inspect(check([0x80], remaining=2), content="1")
  inspect(check([0x80, 0x80], remaining=3), content="1")
  inspect(check([0x80, 0x80, 0x79], remaining=2), content="0")
  inspect(check([0x80, 0x80, 0x80], remaining=2), content="InvalidUtf8(2)")
  // the restricted first continuation byte also applies across chunks
  inspect(check([0x80], remaining=4), content="InvalidUtf8(0)")
  inspect(check([0xa0, 0x80], remaining=4), content="0")
  inspect(check([0xa0], remaining=5), content="InvalidUtf8(0)")
  inspect(check([0x90], remaining=6), content="2")
  inspect(check([0x90], remaining=7), content="InvalidUtf8(0)")
}
