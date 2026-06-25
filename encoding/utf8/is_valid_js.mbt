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
extern "js" fn is_valid_utf8_js(
  bytes : Bytes,
  start : Int,
  len : Int,
  preserve_bom : Bool,
) -> Bool =
  #| ((preserveBOMDecoder, dropBOMDecoder) => function(bytes, start, len, preserveBOM) {
  #|   try {
  #|     const end = start + len;
  #|     const slice = bytes.subarray(start, end);
  #|     const decoder = preserveBOM ? preserveBOMDecoder : dropBOMDecoder;
  #|     decoder.decode(slice);
  #|     return true;
  #|   } catch (_) {
  #|     return false;
  #|   }
  #| })(
  #|   new TextDecoder("utf-8", { fatal: true, ignoreBOM: true }),
  #|   new TextDecoder("utf-8", { fatal: true, ignoreBOM: false }),
  #| )

///|
/// Returns true if the input bytes are well-formed UTF-8.
pub fn is_valid(bytes : BytesView, ignore_bom? : Bool = false) -> Bool {
  is_valid_utf8_js(
    bytes.data(),
    bytes.start_offset(),
    bytes.length(),
    !ignore_bom,
  )
}
