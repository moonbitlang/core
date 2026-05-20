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
extern "js" fn encode_utf8_js(
  src : String,
  start : Int,
  len : Int,
  bom : Bool,
) -> Bytes =
  #| (() => {
  #|   const encoder = new TextEncoder();
  #|   return function(src, start, len, bom) {
  #|     const end = start + len;
  #|     const encoded = encoder.encode(src.slice(start, end));
  #|     if (!bom) {
  #|       return encoded;
  #|     }
  #|     const result = new Uint8Array(encoded.length + 3);
  #|     result[0] = 0xEF;
  #|     result[1] = 0xBB;
  #|     result[2] = 0xBF;
  #|     result.set(encoded, 3);
  #|     return result;
  #|   };
  #| })()

///|
/// Encodes a string into a UTF-8 byte array.
///
/// Panics if the string contains an invalid surrogate pair.
pub fn encode(str : StringView, bom? : Bool = false) -> Bytes {
  encode_utf8_js(str.data(), str.start_offset(), str.length(), bom)
}
