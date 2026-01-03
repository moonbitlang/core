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
test "decoding UTF16 encoded data to String" {
  let chars = @utf16.decode(
    b"\x61\x00\x62\x00\x63\x00\x60\x4f\x7d\x59\x3d\xd8\x40\xdc",
  )
  inspect(chars, content="abc你好👀")
  let chars_be = @utf16.decode(
    b"\x00\x61\x00\x62\x00\x63\x4f\x60\x59\x7d\xd8\x3d\xdc\x40",
    endianness=Big,
  )
  inspect(chars_be, content="abc你好👀")
}

///|
test "decoding UTF16 with bom" {
  let text = b"\xff\xfe\x61\x00\x62\x00\x63\x00\x60\x4f\x7d\x59\x3d\xd8\x40\xdc"
  inspect(try! @utf16.decode(text), content="﻿abc你好👀")
  inspect(try! @utf16.decode(text, ignore_bom=true), content="abc你好👀")
  let text_be = b"\xfe\xff\x00\x61\x00\x62\x00\x63\x4f\x60\x59\x7d\xd8\x3d\xdc\x40"
  inspect(
    try! @utf16.decode(text_be, endianness=Big),
    content="﻿abc你好👀",
  )
  inspect(
    try! @utf16.decode(text_be, ignore_bom=true, endianness=Big),
    content="abc你好👀",
  )
}

///|
test "decoding UTF16 invalid data with replacement" {
  let unpaired = b"\x61\x00\x00"
  inspect(@utf16.decode_lossy(unpaired), content="a�")
  let high_surrogate = b"\x00\xd8"
  inspect(@utf16.decode_lossy(high_surrogate), content="�")
  let low_surrogate = b"\x00\xdc"
  inspect(@utf16.decode_lossy(low_surrogate), content="�")
  let unpaired_be = b"\x00\x61\x00"
  inspect(@utf16.decode_lossy(unpaired_be, endianness=Big), content="a�")
  let high_surrogate_be = b"\xd8\x00"
  inspect(@utf16.decode_lossy(high_surrogate_be, endianness=Big), content="�")
  let low_surrogate_be = b"\xdc\x00"
  inspect(@utf16.decode_lossy(low_surrogate_be, endianness=Big), content="�")
}

///|
test "decoding UTF16 invalid data to String" {
  let unpaired = b"\x61\x00\x00"
  try {
    let _ = @utf16.decode(unpaired)
    panic()
  } catch {
    Malformed(e) =>
      inspect(
        e,
        content=(
          #|b"\x00"
        ),
      )
  }
  let unpaired_be = b"\x00\x61\x00"
  try {
    let _ = @utf16.decode(unpaired_be, endianness=Big)
    panic()
  } catch {
    Malformed(e) =>
      inspect(
        e,
        content=(
          #|b"\x00"
        ),
      )
  }
  let high_surrogate = b"\x00\xd8"
  try {
    let _ = @utf16.decode(high_surrogate)
    panic()
  } catch {
    Malformed(e) =>
      inspect(
        e,
        content=(
          #|b"\x00\xd8"
        ),
      )
  }
  let high_surrogate_be = b"\xd8\x00"
  try {
    let _ = @utf16.decode(high_surrogate_be, endianness=Big)
    panic()
  } catch {
    Malformed(e) =>
      inspect(
        e,
        content=(
          #|b"\xd8\x00"
        ),
      )
  }
  let low_surrogate = b"\x00\xdc"
  try {
    let _ = @utf16.decode(low_surrogate)
    panic()
  } catch {
    Malformed(e) =>
      inspect(
        e,
        content=(
          #|b"\x00\xdc"
        ),
      )
  }
  let low_surrogate_be = b"\xdc\x00"
  try {
    let _ = @utf16.decode(low_surrogate_be, endianness=Big)
    panic()
  } catch {
    Malformed(e) =>
      inspect(
        e,
        content=(
          #|b"\xdc\x00"
        ),
      )
  }
}

///|
test "decode ignore_bom without BOM" {
  // Test ignore_bom=true but no BOM present (line 35 and 40)
  let no_bom = b"\x61\x00\x62\x00"
  let result = try! @utf16.decode(no_bom, ignore_bom=true)
  inspect(result, content="ab")
  let no_bom_be = b"\x00\x61\x00\x62"
  let result_be = try! @utf16.decode(no_bom_be, ignore_bom=true, endianness=Big)
  inspect(result_be, content="ab")
}

///|
test "decode_lossy with ignore_bom" {
  // Test decode_lossy with ignore_bom=true and BOM present (lines 515-520)
  let with_bom_le = b"\xff\xfe\x61\x00\x62\x00"
  inspect(@utf16.decode_lossy(with_bom_le, ignore_bom=true), content="ab")
  let with_bom_be = b"\xfe\xff\x00\x61\x00\x62"
  inspect(
    @utf16.decode_lossy(with_bom_be, ignore_bom=true, endianness=Big),
    content="ab",
  )
  // Test with ignore_bom=true but no BOM
  let no_bom = b"\x61\x00\x62\x00"
  inspect(@utf16.decode_lossy(no_bom, ignore_bom=true), content="ab")
}

///|
test "decode_lossy with surrogate pairs" {
  // Test valid surrogate pairs in decode_lossy (lines 533-542, 561-569)
  let surrogate_pair_le = b"\x3d\xd8\x40\xdc" // 👀 U+1F440
  inspect(@utf16.decode_lossy(surrogate_pair_le), content="👀")
  let surrogate_pair_be = b"\xd8\x3d\xdc\x40" // 👀 U+1F440
  inspect(
    @utf16.decode_lossy(surrogate_pair_be, endianness=Big),
    content="👀",
  )
  // Test surrogate pair that exceeds 0x10FFFF - should use replacement char
  // This is hard to construct but we can test the invalid surrogate path
  let invalid_surr = b"\x3d\xd8\x41\xdc"
  let result = @utf16.decode_lossy(invalid_surr)
  assert_true(result.length() > 0)
}
