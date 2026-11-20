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
fn check(
  bytes : Array[Byte],
  state~ : Utf8State = Complete,
) -> Utf8State raise InvalidUtf8 {
  verify_utf8(Bytes::from_array(bytes), state~)
}

///|
test "validate utf8 single byte" {
  assert_true(check([0x79]) is Complete)
  assert_true(check([0x00, 0x7f]) is Complete)
}

///|
test "validate utf8 two bytes" {
  assert_true(check([0xc2]) is NeedOne)
  assert_true(check([0xc2, 0x80]) is Complete)
  assert_true(check([0xdf, 0xbf]) is Complete)
  @debug.debug_inspect(
    @test.expect_error(() => check([0xc2, 0x79])),
    content="InvalidUtf8(1)",
  )
  // overlong encodings of U+0000..U+007F
  @debug.debug_inspect(
    @test.expect_error(() => check([0xc0, 0x80])),
    content="InvalidUtf8(0)",
  )
  @debug.debug_inspect(
    @test.expect_error(() => check([0xc1, 0xbf])),
    content="InvalidUtf8(0)",
  )
}

///|
test "validate utf8 three bytes" {
  assert_true(check([0xe1]) is NeedTwo)
  assert_true(check([0xe1, 0x80]) is NeedOne)
  assert_true(check([0xef, 0xbf, 0xbf]) is Complete)
  assert_true(check([0xe0, 0xa0, 0x80]) is Complete)
  assert_true(check([0xed, 0x9f, 0xbf]) is Complete)
  @debug.debug_inspect(
    @test.expect_error(() => check([0xe1, 0x79])),
    content="InvalidUtf8(1)",
  )
  @debug.debug_inspect(
    @test.expect_error(() => check([0xe1, 0x80, 0x79])),
    content="InvalidUtf8(2)",
  )
  // overlong encodings below U+0800
  assert_true(check([0xe0]) is AfterE0)
  @debug.debug_inspect(
    @test.expect_error(() => check([0xe0, 0x80, 0x80])),
    content="InvalidUtf8(1)",
  )
  @debug.debug_inspect(
    @test.expect_error(() => check([0xe0, 0x9f, 0xbf])),
    content="InvalidUtf8(1)",
  )
  // UTF-16 surrogates U+D800..U+DFFF
  assert_true(check([0xed]) is AfterED)
  @debug.debug_inspect(
    @test.expect_error(() => check([0xed, 0xa0, 0x80])),
    content="InvalidUtf8(1)",
  )
  @debug.debug_inspect(
    @test.expect_error(() => check([0xed, 0xbf, 0xbf])),
    content="InvalidUtf8(1)",
  )
}

///|
test "validate utf8 four bytes" {
  assert_true(check([0xf1]) is NeedThree)
  assert_true(check([0xf1, 0x80]) is NeedTwo)
  assert_true(check([0xf1, 0x80, 0x80]) is NeedOne)
  assert_true(check([0xf0, 0x90, 0x80, 0x80]) is Complete)
  assert_true(check([0xf4, 0x8f, 0xbf, 0xbf]) is Complete)
  @debug.debug_inspect(
    @test.expect_error(() => check([0xf1, 0x79])),
    content="InvalidUtf8(1)",
  )
  @debug.debug_inspect(
    @test.expect_error(() => check([0xf1, 0x80, 0x80, 0x79])),
    content="InvalidUtf8(3)",
  )
  assert_true(check([0xf1, 0x80, 0x80, 0x80, 0x79]) is Complete)
  // overlong encodings below U+10000
  assert_true(check([0xf0]) is AfterF0)
  @debug.debug_inspect(
    @test.expect_error(() => check([0xf0, 0x80, 0x80, 0x80])),
    content="InvalidUtf8(1)",
  )
  @debug.debug_inspect(
    @test.expect_error(() => check([0xf0, 0x8f, 0xbf, 0xbf])),
    content="InvalidUtf8(1)",
  )
  // above U+10FFFF
  assert_true(check([0xf4]) is AfterF4)
  @debug.debug_inspect(
    @test.expect_error(() => check([0xf4, 0x90, 0x80, 0x80])),
    content="InvalidUtf8(1)",
  )
  @debug.debug_inspect(
    @test.expect_error(() => check([0xf5, 0x80, 0x80, 0x80])),
    content="InvalidUtf8(0)",
  )
  @debug.debug_inspect(
    @test.expect_error(() => check([0xf7, 0x80, 0x80, 0x80])),
    content="InvalidUtf8(0)",
  )
}

///|
test "invalid utf8 first byte" {
  let bytes : Array[Byte] = [0x80, 0xbf, 0xc0, 0xc1, 0xf5, 0xf8, 0xff]
  for b in bytes {
    @debug.debug_inspect(
      @test.expect_error(() => check([b])),
      content="InvalidUtf8(0)",
    )
  }
}

///|
test "validate utf8 in the middle" {
  @debug.debug_inspect(
    @test.expect_error(() => check([0x79], state=NeedOne)),
    content="InvalidUtf8(0)",
  )
  @debug.debug_inspect(
    @test.expect_error(() => check([0xc2], state=NeedOne)),
    content="InvalidUtf8(0)",
  )
  assert_true(check([0x80], state=NeedOne) is Complete)
  assert_true(check([0x80], state=NeedTwo) is NeedOne)
  assert_true(check([0x80, 0x80], state=NeedThree) is NeedOne)
  assert_true(check([0x80, 0x80, 0x79], state=NeedTwo) is Complete)
  @debug.debug_inspect(
    @test.expect_error(() => check([0x80, 0x80, 0x80], state=NeedTwo)),
    content="InvalidUtf8(2)",
  )
  // the restricted first continuation byte also applies across chunks
  @debug.debug_inspect(
    @test.expect_error(() => check([0x80], state=AfterE0)),
    content="InvalidUtf8(0)",
  )
  assert_true(check([0xa0, 0x80], state=AfterE0) is Complete)
  @debug.debug_inspect(
    @test.expect_error(() => check([0xa0], state=AfterED)),
    content="InvalidUtf8(0)",
  )
  assert_true(check([0x90], state=AfterF0) is NeedTwo)
  @debug.debug_inspect(
    @test.expect_error(() => check([0x90], state=AfterF4)),
    content="InvalidUtf8(0)",
  )
}
