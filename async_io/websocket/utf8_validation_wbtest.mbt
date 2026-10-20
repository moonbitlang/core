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
test "validate utf8 single byte" {
  @debug.debug_inspect(verify_utf8([0x79], remaining=0), content="0")
}

///|
test "validate utf8 two bytes" {
  @debug.debug_inspect(verify_utf8([0xc0], remaining=0), content="1")
  @debug.debug_inspect(verify_utf8([0xdf, 0x80], remaining=0), content="0")
  @debug.debug_inspect(
    @test.expect_error(() => verify_utf8([0xc0, 0x79], remaining=0)),
    content=(
      #|Malformed(<BytesView: [0xc0, 0x79]>)
    ),
  )
}

///|
test "validate utf8 three bytes" {
  @debug.debug_inspect(verify_utf8([0xe0], remaining=0), content="2")
  @debug.debug_inspect(verify_utf8([0xe0, 0x80], remaining=0), content="1")
  @debug.debug_inspect(
    verify_utf8([0xef, 0x80, 0x80], remaining=0),
    content="0",
  )
  @debug.debug_inspect(
    @test.expect_error(() => verify_utf8([0xe0, 0x79], remaining=0)),
    content=(
      #|Malformed(<BytesView: [0xc0, 0x79]>)
    ),
  )
  @debug.debug_inspect(
    @test.expect_error(() => verify_utf8([0xe0, 0x80, 0x79], remaining=0)),
    content=(
      #|Malformed(<BytesView: [0xc0, 0x79]>)
    ),
  )
}

///|
test "validate utf8 four bytes" {
  @debug.debug_inspect(verify_utf8([0xf0], remaining=0), content="3")
  @debug.debug_inspect(verify_utf8([0xf0, 0x80], remaining=0), content="2")
  @debug.debug_inspect(
    verify_utf8([0xf0, 0x80, 0x80], remaining=0),
    content="1",
  )
  @debug.debug_inspect(
    verify_utf8([0xf7, 0x80, 0x80, 0x80], remaining=0),
    content="0",
  )
  @debug.debug_inspect(
    @test.expect_error(() => verify_utf8([0xf0, 0x79], remaining=0)),
    content=(
      #|Malformed(<BytesView: [0xc0, 0x79]>)
    ),
  )
  @debug.debug_inspect(
    @test.expect_error(() => verify_utf8([0xf0, 0x80, 0x79], remaining=0)),
    content=(
      #|Malformed(<BytesView: [0xc0, 0x79]>)
    ),
  )
  @debug.debug_inspect(
    @test.expect_error(() => verify_utf8([0xf0, 0x80, 0x80, 0x79], remaining=0)),
    content=(
      #|Malformed(<BytesView: [0xc0, 0x79]>)
    ),
  )
  @debug.debug_inspect(
    verify_utf8([0xf0, 0x80, 0x80, 0x80, 0x79], remaining=0),
    content="0",
  )
}

///|
test "invalid utf8 first byte" {
  @debug.debug_inspect(
    @test.expect_error(() => verify_utf8([0xf8], remaining=0)),
    content=(
      #|Malformed(<BytesView: [0xf8]>)
    ),
  )
}

///|
test "validate utf8 in the middle" {
  @debug.debug_inspect(
    @test.expect_error(() => verify_utf8([0x79], remaining=1)),
    content=(
      #|Malformed(<BytesView: [0xc0, 0x79]>)
    ),
  )
  @debug.debug_inspect(
    @test.expect_error(() => verify_utf8([0xc0], remaining=1)),
    content=(
      #|Malformed(<BytesView: [0xc0, 0xc0]>)
    ),
  )
  @debug.debug_inspect(
    @test.expect_error(() => verify_utf8([0xe0], remaining=1)),
    content=(
      #|Malformed(<BytesView: [0xc0, 0xe0]>)
    ),
  )
  @debug.debug_inspect(
    @test.expect_error(() => verify_utf8([0xf0], remaining=1)),
    content=(
      #|Malformed(<BytesView: [0xc0, 0xf0]>)
    ),
  )
  @debug.debug_inspect(verify_utf8([0x80], remaining=1), content="0")
  @debug.debug_inspect(verify_utf8([0x80], remaining=2), content="1")
  @debug.debug_inspect(verify_utf8([0x80, 0x80], remaining=3), content="1")
  @debug.debug_inspect(
    verify_utf8([0x80, 0x80, 0x79], remaining=2),
    content="0",
  )
  @debug.debug_inspect(
    @test.expect_error(() => verify_utf8([0x80, 0x80, 0x80], remaining=2)),
    content=(
      #|Malformed(<BytesView: [0x80]>)
    ),
  )
}
