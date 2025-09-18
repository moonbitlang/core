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
test "decoding UTF16 encoded data to String" {
  let chars = @utf16le.decode(
    b"\x61\x00\x62\x00\x63\x00\x60\x4f\x7d\x59\x3d\xd8\x40\xdc",
  )
  inspect(chars, content="abc你好👀")
}

///|
test "decoding UTF16 with bom" {
  let text = b"\xff\xfe\x61\x00\x62\x00\x63\x00\x60\x4f\x7d\x59\x3d\xd8\x40\xdc"
  inspect(try! @utf16le.decode(text), content="﻿abc你好👀")
  inspect(try! @utf16le.decode(text, ignore_bom=true), content="abc你好👀")
}

///|
test "decoding UTF16 invalid data with replacement" {
  let unpaired = b"\x61\x00\x00"
  inspect(@utf16le.decode_lossy(unpaired), content="a�")
  let high_surrogate = b"\x00\xd8"
  inspect(@utf16le.decode_lossy(high_surrogate), content="�")
  let low_surrogate = b"\x00\xdc"
  inspect(@utf16le.decode_lossy(low_surrogate), content="�")
}

///|
test "decoding UTF16 invalid data to String" {
  let unpaired = b"\x61\x00\x00"
  try {
    let _ = @utf16le.decode(unpaired)
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
    let _ = @utf16le.decode(high_surrogate)
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
  let low_surrogate = b"\x00\xdc"
  try {
    let _ = @utf16le.decode(low_surrogate)
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
}
