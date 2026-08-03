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
test "decoded_len" {
  inspect(@hex.decoded_len(0), content="0")
  inspect(@hex.decoded_len(1), content="0")
  inspect(@hex.decoded_len(2), content="1")
  inspect(@hex.decoded_len(27), content="13")
}

///|
test "decode" {
  inspect(
    try! @hex.decode("48656c6c6f20476f7068657221"),
    content=(
      #|b"Hello Gopher!"
    ),
  )
  inspect(
    try! @hex.decode("48656C6C6F"),
    content=(
      #|b"Hello"
    ),
  )
  inspect(
    try! @hex.decode("000f107f80ff"),
    content=(
      #|b"\x00\x0f\x10\x7f\x80\xff"
    ),
  )
}

///|
test "decode all byte values" {
  let bytes = Bytes::makei(256, i => i.to_byte())
  let encoded = @hex.encode(bytes)
  inspect(try! (@hex.decode(encoded) == bytes), content="true")
}

///|
test "decode malformed" {
  let malformed = text => {
    try {
      let _ = @hex.decode(text)
      false
    } catch {
      Malformed(_) => true
    }
  }
  inspect(malformed("0"), content="true")
  inspect(malformed("0g"), content="true")
  inspect(malformed("xz"), content="true")
  inspect(malformed("12 3"), content="true")
  inspect(malformed("12\n"), content="true")
}

///|
test "Debug for Malformed" {
  try {
    let _ = @hex.decode("0g")
    panic()
  } catch {
    err =>
      @debug.debug_inspect(
        err,
        content=(
          #|Malformed(<StringView: "0g">)
        ),
      )
  }
}
