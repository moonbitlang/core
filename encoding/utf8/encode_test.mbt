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
test "encode" {
  let s = "abc你好👀"
  let encoded = @utf8.encode(s)
  inspect(
    encoded,
    content=(
      #|b"abc\xe4\xbd\xa0\xe5\xa5\xbd\xf0\x9f\x91\x80"
    ),
  )
  let encoded_with_bom = @utf8.encode(s, bom=true)
  inspect(
    encoded_with_bom,
    content=(
      #|b"\xef\xbb\xbfabc\xe4\xbd\xa0\xe5\xa5\xbd\xf0\x9f\x91\x80"
    ),
  )
}

///|
fn encode_via_buffer(str : StringView, bom : Bool) -> Bytes {
  let buffer = @buffer.new(size_hint=str.length() * 4)
  if bom {
    buffer.write_char_utf8('\u{FEFF}')
  }
  buffer.write_string_utf8(str)
  buffer.to_bytes()
}

///|
test "encode matches previous buffer implementation" {
  let sample = "abc你好👀"
  assert_eq(@utf8.encode(sample), encode_via_buffer(sample, false))
  assert_eq(@utf8.encode(sample, bom=true), encode_via_buffer(sample, true))

  let view = "zabc你好👀w"[1:8]
  assert_eq(@utf8.encode(view), encode_via_buffer(view, false))
  assert_eq(@utf8.encode(view, bom=true), encode_via_buffer(view, true))
}

///|
test "panic encode with invalid leading surrogate" {
  let invalid = String::from_array([(0xD800).unsafe_to_char(), 'A'])
  ignore(@utf8.encode(invalid))
}

///|
test "panic encode with dangling trailing surrogate" {
  let invalid = String::from_array(['A', (0xDC00).unsafe_to_char()])
  ignore(@utf8.encode(invalid))
}
