// Copyright 2024 International Digital Economy Academy
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
pub fn encode(encoding : Encoding, src : String) -> Bytes {
  // NOTE: special case: MoonBit String are already valid UTF16(LE) bytes
  match encoding {
    UTF16 | UTF16LE => return src.to_bytes()
    _ => ()
  }
  let buf = @buffer.T::from_bytes(src.to_bytes())
  let chars = decode_strict(UTF16LE, buf)
  let new_buf = @buffer.T::new(size_hint=buf.length())
  let write = match encoding {
    UTF8 => @buffer.write_utf8_char
    UTF16BE => @buffer.write_utf16be_char
    _ => abort("unreachable")
  }
  for char in chars {
    // SAFETY: Assume String are always valid UTF16LE
    write(new_buf, char.unwrap())
  }
  new_buf.to_bytes()
}
