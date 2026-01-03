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
          #|b"\xc0\xaf\xe0\x80\xbf\xf0\x81\x82A"
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

///|
test "decoding UTF8 with 8+ ASCII characters" {
  let text1 = b"abcdefgh"
  inspect(try! @utf8.decode(text1), content="abcdefgh")
  let text2 = b"12345678901234567890"
  inspect(try! @utf8.decode(text2), content="12345678901234567890")
  inspect(@utf8.decode_lossy(text1), content="abcdefgh")
  inspect(@utf8.decode_lossy(text2), content="12345678901234567890")
}

///|
test "decoding UTF8 with 2-byte sequences" {
  let copyright = b"\xc2\xa9"
  inspect(try! @utf8.decode(copyright), content="©")
  let registered = b"\xc2\xae"
  inspect(try! @utf8.decode(registered), content="®")
  let micro = b"\xc2\xb5"
  inspect(try! @utf8.decode(micro), content="µ")
  let o_slash = b"\xc3\x98"
  inspect(try! @utf8.decode(o_slash), content="Ø")
  let mixed = b"\x61\xc2\xa9\x62\xc2\xae\x63"
  inspect(try! @utf8.decode(mixed), content="a©b®c")
  inspect(@utf8.decode_lossy(copyright), content="©")
  inspect(@utf8.decode_lossy(mixed), content="a©b®c")
}

///|
test "decode_lossy with valid 3-byte and 4-byte sequences" {
  let chinese1 = b"\xe4\xb8\xad"
  inspect(@utf8.decode_lossy(chinese1), content="中")
  let chinese2 = b"\xe6\x96\x87"
  inspect(@utf8.decode_lossy(chinese2), content="文")
  let emoji1 = b"\xf0\x9f\x98\x80"
  inspect(@utf8.decode_lossy(emoji1), content="😀")
  let emoji2 = b"\xf0\x9f\x8e\x89" // 🎉 (U+1F389)
  inspect(@utf8.decode_lossy(emoji2), content="🎉")
  let mixed = b"\x61\xc2\xa9\xe4\xb8\xad\xf0\x9f\x98\x80\x62"
  inspect(@utf8.decode_lossy(mixed), content="a©中😀b")
}

///|
test "decode_lossy with bom" {
  let text = b"\xef\xbb\xbf\x61\x62\x63"
  inspect(@utf8.decode_lossy(text), content="﻿abc")
  inspect(@utf8.decode_lossy(text, ignore_bom=true), content="abc")
}
