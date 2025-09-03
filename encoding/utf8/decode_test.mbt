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
/// Reference : https://www.unicode.org/versions/Unicode16.0.0/core-spec/chapter-3/#G66453
test "U+FFFD" {
  let table_3_8 = b"\xc0\xaf\xe0\x80\xbf\xf0\x81\x82\x41"
  inspect(@utf8.decode_lossy(table_3_8), content="��������A")
  let table_3_9 = b"\xed\xa0\x80\xed\xbf\xbf\xed\xaf\x41"
  inspect(@utf8.decode_lossy(table_3_9), content="��������A")
  let table_3_10 = b"\xf4\x91\x92\x93\xff\x41\x80\xbf\x42"
  inspect(@utf8.decode_lossy(table_3_10), content="�����A��B")
  let table_3_11 = b"\xe1\x80\xe2\xf0\x91\x92\xf1\xbf\x41"
  inspect(@utf8.decode_lossy(table_3_11), content="����A")
}

///|
test "decoding UTF8 encoded data to String" {
  let buf = @buffer.new(size_hint=10)
  buf.write_bytes(b"abc")
  buf.write_bytes(b"\xe4\xbd\xa0") // 你
  buf.write_bytes(b"\xe5\xa5\xbd") // 好
  buf.write_bytes(b"\xf0\x9f\x91\x80") // 👀
  let chars = @utf8.decode(buf.to_bytes())
  inspect(chars, content="abc你好👀")
}

///|
test "decoding UTF8 invalid data to String" {
  let table_3_8 = b"\xc0\xaf\xe0\x80\xbf\xf0\x81\x82\x41"
  try {
    let _ = @utf8.decode(table_3_8)
    panic()
  } catch {
    Malformed(e) =>
      inspect(
        e,
        content=(
          #|b"\xc0\xaf\xe0\x80\xbf\xf0\x81\x82\x41"
        ),
      )
  }
}

///|
test "decoding UTF8 with bom" {
  let text = b"\xef\xbb\xbf\x61\x62\x63\xe4\xbd\xa0\xe5\xa5\xbd\xf0\x9f\x91\x80"
  inspect(try! @utf8.decode(text), content="﻿abc你好👀")
  inspect(try! @utf8.decode(text, ignore_bom=true), content="abc你好👀")
}
