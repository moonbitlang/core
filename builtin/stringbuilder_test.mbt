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
// when we write the string into the buffer
// we assume the string is utf16 and blit
// we assume the bytes (in valid region [0, len)) is utf16
// so that
fn id(s : String) -> String {
  StringBuilder::new()..write_string(s).to_string()
}

test "stringbuilder" {
  let buf = StringBuilder::new()
  buf.write_string("hello")
  buf.write_char(' ')
  buf.write_substring("world", 0, 3)
  inspect!(buf.to_string(), content="hello wor")
}

test "is_empty method" {
  let buf = StringBuilder::new()
  inspect!(buf.is_empty(), content="true")
  buf.write_string("Test")
  inspect!(buf.is_empty(), content="false")
  buf.reset()
  inspect!(buf.is_empty(), content="true")
}

test {
  let data = ["a", "b", "c", "hello world"]
  @json.inspect!(data.map(id), content=["a", "b", "c", "hello world"])
  // assert_eq!(StringBuilder::new()..write_string("hello").to_string(), "hello")
}

test "write_iter" {
  let str = "Hello🤣🤣🤣"
  let sb = StringBuilder::new()
  sb.write_iter(str.iter())
  inspect!(sb.to_string(), content="Hello🤣🤣🤣")
  guard let Some(offset) = str.index_at(1)
  guard let Some(offset2) = str.index_at(6)
  let str_view = str[offset:offset2]
  sb.write_iter(str_view.iter())
  inspect!(sb.to_string(), content="Hello🤣🤣🤣ello🤣")
}
