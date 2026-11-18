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
/// Compare UTF-8 text using Moon's snapshot semantics: remove every CR.
/// A missing baseline is empty. Only the baseline read buffer is bounded;
/// the actual output and legacy mismatch payload remain buffered in memory.
/// WasmGC also buffers the entire baseline in the legacy host ABI.
pub fn matches(
  source : String,
  filename : String,
  actual : Bytes,
) -> Bool raise {
  // Moon runs tests at the module root; SourceLoc includes the source directory.
  // Keep path components intact (especially .. next to symlinks).
  let source = if file_host_is_unix {
    source
  } else {
    source.replace(old="\\", new="/")
  }
  let parts = source.split("/").to_array()
  ignore(parts.pop())
  let directory = parts.join("/")
  // Windows rooted and drive-prefixed paths require drive resolution. Leave
  // those uncommon names to Moon's existing protocol instead of guessing.
  if !file_host_is_unix &&
    (
      filename.contains(":") ||
      filename.has_prefix("\\") ||
      filename.has_prefix("/")
    ) {
    return false
  }
  let path = if filename.has_prefix("/") {
    filename
  } else {
    (if directory.is_empty() { "" } else { directory + "/" }) +
    "__snapshot__/" +
    filename
  }
  guard !path.contains("\u0000") else { fail("NUL in snapshot path") }
  guard open(path) is Some(file) else {
    return actual.iter().all(b => b == b'\r')
  }
  defer file.close()
  let buffer : FixedArray[Byte] = FixedArray::make(65536, 0)
  let mut index = 0
  let mut equal = true
  // Validate UTF-8 before normalization, just like Moon's read_to_string.
  // Keep decoder state across reads, including the restricted second byte
  // ranges that exclude overlong sequences, surrogates, and values > U+10FFFF.
  let mut remaining = 0
  let mut low : Byte = 0x80
  let mut high : Byte = 0xBF
  for position = 0L {
    let count = file.read(buffer, 0, buffer.length(), position)
    if count == 0 {
      break
    }
    for i = 0; i < count; i = i + 1 {
      let b = buffer[i]
      if remaining > 0 {
        guard b >= low && b <= high else {
          fail("snapshot baseline is not UTF-8: \{path}")
        }
        remaining -= 1
        low = 0x80
        high = 0xBF
      } else if b >= 0x80 {
        match b {
          0xC2..<=0xDF => remaining = 1
          0xE0 => {
            remaining = 2
            low = 0xA0
          }
          0xE1..<=0xEC | 0xEE..<=0xEF => remaining = 2
          0xED => {
            remaining = 2
            high = 0x9F
          }
          0xF0 => {
            remaining = 3
            low = 0x90
          }
          0xF1..<=0xF3 => remaining = 3
          0xF4 => {
            remaining = 3
            high = 0x8F
          }
          _ => fail("snapshot baseline is not UTF-8: \{path}")
        }
      }
      if b == b'\r' {
        continue
      }
      while index < actual.length() && actual[index] == b'\r' {
        index += 1
      }
      if index >= actual.length() || actual[index] != b {
        equal = false
      }
      if index < actual.length() {
        index += 1
      }
    }
    continue position + count.to_int64()
  }
  guard remaining == 0 else { fail("snapshot baseline is not UTF-8: \{path}") }
  while index < actual.length() && actual[index] == b'\r' {
    index += 1
  }
  equal && index == actual.length()
}
