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
/// Creates a lexbuf whose complete input is already available.
///
/// Deprecated: use `StringScanner` instead.
#deprecated("Use `StringScanner` instead")
pub fn Lexbuf::from_string(content : String) -> Lexbuf {
  {
    source: () => None,
    storage: LexbufStorage::from_string(content),
    cursor: 0,
    retained_from: -1,
    eof: true,
  }
}
