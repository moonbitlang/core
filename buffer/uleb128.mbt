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
pub impl Leb128 for UInt with output(self, buffer) {
  for value = self {
    if value < 128 {
      // Single byte: no continuation bit (0xxxxxxx)
      buffer.write_byte(value.to_byte())
      break
    } else {
      // Multiple bytes: set continuation bit (1xxxxxxx) and continue
      buffer.write_byte(((value % 128) | 128).to_byte())
      continue value / 128
    }
  }
}

///|
pub impl Leb128 for UInt64 with output(self, buffer) {
  for value = self {
    if value < 128 {
      // Single byte: no continuation bit (0xxxxxxx)
      buffer.write_byte(value.to_byte())
      break
    } else {
      // Multiple bytes: set continuation bit (1xxxxxxx) and continue
      buffer.write_byte(((value % 128) | 128).to_byte())
      continue value / 128
    }
  }
}
