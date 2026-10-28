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

// On JS a MoonBit string is a JS string, so searches can use the engine's
// `indexOf` and `lastIndexOf`. Both compare UTF-16 code units and return
// code-unit offsets, as `find` and `rev_find` do.

///|
// Offset in `data` of the first occurrence of `pattern` inside
// `data[start:end]`, or -1. A window that stops before the end of `data` is
// sliced first, so that a miss does not scan the rest of the string.
extern "js" fn js_index_of(
  data : String,
  start : Int32,
  end : Int32,
  pattern : String,
) -> Int32 =
  #|(s, start, end, p) => {
  #|  if (end - start < p.length) return -1;
  #|  if (end === s.length) return s.indexOf(p, start);
  #|  const i = s.substring(start, end).indexOf(p);
  #|  return i < 0 ? i : start + i;
  #|}

///|
// Offset in `data` of the last occurrence of `pattern` inside
// `data[start:end]`, or -1. A window that starts after the start of `data`
// is sliced first, so that a miss does not scan the rest of the string.
extern "js" fn js_last_index_of(
  data : String,
  start : Int32,
  end : Int32,
  pattern : String,
) -> Int32 =
  #|(s, start, end, p) => {
  #|  if (end - start < p.length) return -1;
  #|  if (start === 0) return s.lastIndexOf(p, end - p.length);
  #|  const i = s.substring(start, end).lastIndexOf(p);
  #|  return i < 0 ? i : start + i;
  #|}

///|
extern "js" fn js_code_unit_string(code : UInt16) -> String =
  #|(c) => String.fromCharCode(c)

///|
extern "js" fn js_substring(
  data : String,
  start : Int32,
  end : Int32,
) -> String =
  #|(s, start, end) => start === 0 && end === s.length ? s : s.substring(start, end)

///|
// Windows up to this many code units are scanned in MoonBit: below it the
// call into the engine costs more than the scan.
const JS_SCALAR_SCAN_MAX = 8

///|
// The caller must ensure `0 <= start <= end <= data.length()`.
fn find_code_unit_from_string(
  data : String,
  start : Int32,
  end : Int32,
  code : UInt16,
) -> Int32 {
  if end - start <= JS_SCALAR_SCAN_MAX {
    find_code_unit_scalar(data, start, end, code)
  } else {
    js_index_of(data, start, end, js_code_unit_string(code))
  }
}

///|
// The caller must ensure `0 <= start <= end <= data.length()`.
fn rev_find_code_unit_from_string(
  data : String,
  start : Int32,
  end : Int32,
  code : UInt16,
) -> Int32 {
  if end - start <= JS_SCALAR_SCAN_MAX {
    rev_find_code_unit_scalar(data, start, end, code)
  } else {
    js_last_index_of(data, start, end, js_code_unit_string(code))
  }
}

///|
// Longest pattern handed to `indexOf`. V8 builds its Boyer-Moore tables from
// at most the last 250 code units of a pattern, so a longer pattern that
// differs from the text only before them is searched in quadratic time.
// Longer patterns keep the two-anchor search and its linear fallback.
const JS_INDEX_OF_MAX_PATTERN = 250

///|
// The caller must ensure `2 <= pattern.length() <= target.length()`.
fn find_pattern(target : StringView, pattern : StringView) -> Int32? {
  guard pattern.length() <= JS_INDEX_OF_MAX_PATTERN else {
    return find_by_two_anchors(target, pattern)
  }
  let target_start = target.start_offset()
  let pattern_start = pattern.start_offset()
  let found = js_index_of(
    target.data(),
    target_start,
    target_start + target.length(),
    js_substring(
      pattern.data(),
      pattern_start,
      pattern_start + pattern.length(),
    ),
  )
  if found < 0 {
    None
  } else {
    Some(found - target_start)
  }
}
