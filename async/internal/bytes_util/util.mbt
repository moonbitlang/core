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
/// Converts a byte slice to a readable ASCII/escape representation.
///
/// # Behavior
/// - bytes in 0x20..0x7e are emitted as ASCII characters
/// - '\n' is emitted as a newline character
/// - '\r' and '\t' are emitted as the escape sequences "\\r" and "\\t"
/// - other bytes are emitted as "\\x" followed by lowercase hex without padding
///
/// # Example
/// ```mbt check
/// test {
///   let bytes : Bytes = [0, 1, 15, 16, 31, 32, 65, 10, 13, 9, 127]
///   let rendered = @bytes_util.ascii_to_string(bytes)
///   inspect(rendered, content="\\x0\\x1\\xf\\x10\\x1f A\n\\r\\t\\x7f")
/// }
/// ```
pub fn ascii_to_string(ascii : BytesView) -> String {
  let builder = StringBuilder()
  for byte in ascii {
    match byte {
      b'\n' => builder.write_char('\n')
      b'\r' => builder <+ "\\r"
      b'\t' => builder <+ "\\t"
      32..<=126 => builder.write_char(byte.to_int().unsafe_to_char())
      x => builder <+ "\\x\{x.to_int().to_string(radix=16)}"
    }
  }
  builder.to_string()
}
