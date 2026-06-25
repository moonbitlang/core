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
extern "js" fn decode_utf8_js(
  bytes : Bytes,
  start : Int,
  len : Int,
  preserve_bom : Bool,
) -> Array[String] =
  #| ((preserveBOMDecoder, dropBOMDecoder) => function(bytes, start, len, preserveBOM) {
  #|   try {
  #|     const end = start + len;
  #|     const slice = bytes.subarray(start, end);
  #|     const decoder = preserveBOM ? preserveBOMDecoder : dropBOMDecoder;
  #|     return [decoder.decode(slice)];
  #|   } catch (_) {
  #|     return [];
  #|   }
  #| })(
  #|   new TextDecoder("utf-8", { fatal: true, ignoreBOM: true }),
  #|   new TextDecoder("utf-8", { fatal: true, ignoreBOM: false }),
  #| )

///|
extern "js" fn decode_utf8_lossy_js(
  bytes : Bytes,
  start : Int,
  len : Int,
  preserve_bom : Bool,
) -> String =
  #| ((preserveBOMDecoder, dropBOMDecoder) => function(bytes, start, len, preserveBOM) {
  #|   const end = start + len;
  #|   const slice = bytes.subarray(start, end);
  #|   const decoder = preserveBOM ? preserveBOMDecoder : dropBOMDecoder;
  #|   return decoder.decode(slice);
  #| })(
  #|   new TextDecoder("utf-8", { ignoreBOM: true }),
  #|   new TextDecoder("utf-8", { ignoreBOM: false }),
  #| )

///|
fn strict_malformed_suffix(bytes : BytesView) -> BytesView {
  let input = bytes.data()
  let src_offset = bytes.start_offset()
  let src_length = bytes.length()
  let malformed_offset = utf8_find_malformed(input, src_offset, src_length)
  bytes[malformed_offset:]
}

///|
/// Decode input bytes/text into structured output.
pub fn decode(
  bytes : BytesView,
  ignore_bom? : Bool = false,
) -> String raise Malformed {
  let result = decode_utf8_js(
    bytes.data(),
    bytes.start_offset(),
    bytes.length(),
    !ignore_bom,
  )
  if result.length() == 1 {
    result[0]
  } else {
    let bytes = drop_utf8_bom(bytes, ignore_bom)
    raise Malformed(strict_malformed_suffix(bytes))
  }
}

///|
///
/// References :
/// - https://www.unicode.org/versions/Unicode16.0.0/core-spec/chapter-3/#G66453
/// - https://www.unicode.org/versions/Unicode16.0.0/core-spec/chapter-5/#G40630
pub fn decode_lossy(bytes : BytesView, ignore_bom? : Bool = false) -> String {
  decode_utf8_lossy_js(
    bytes.data(),
    bytes.start_offset(),
    bytes.length(),
    !ignore_bom,
  )
}
