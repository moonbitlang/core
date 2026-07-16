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
// Convert view-relative bounds to backing-string offsets before scanning.
fn find_code_unit_from_view(
  target : StringView,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  let target_start = target.start_offset()
  let found = find_code_unit_from_string(
    target.data(),
    target_start + start,
    target_start + end,
    code,
  )
  if found < 0 {
    -1
  } else {
    found - target_start
  }
}

///|
// Convert view-relative bounds to backing-string offsets before reverse
// scanning.
fn rev_find_code_unit_from_view(
  target : StringView,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  let target_start = target.start_offset()
  let found = rev_find_code_unit_from_string(
    target.data(),
    target_start + start,
    target_start + end,
    code,
  )
  if found < 0 {
    -1
  } else {
    found - target_start
  }
}

///|
// The caller must ensure `0 <= start <= end <= data.length()`.
#inline
fn find_code_unit_scalar(
  data : String,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  for pos in start..<end {
    if data.unsafe_get(pos) == code {
      break pos
    }
  } nobreak {
    -1
  }
}

///|
// The caller must ensure `0 <= start <= end <= data.length()`.
#inline
fn rev_find_code_unit_scalar(
  data : String,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  for pos = end - 1; pos >= start; {
    if data.unsafe_get(pos) == code {
      break pos
    }
    continue pos - 1
  } nobreak {
    -1
  }
}

///|
#cfg(not(any(target="native", target="wasm")))
fn find_code_unit_from_string(
  data : String,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  find_code_unit_scalar(data, start, end, code)
}

///|
#cfg(not(any(target="native", target="wasm")))
fn rev_find_code_unit_from_string(
  data : String,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  rev_find_code_unit_scalar(data, start, end, code)
}

///|
// SIMD code-unit scanner for linear-memory backends. The vector loop scans
// eight UTF-16 code units at a time, then the scalar tail handles the remainder.
#cfg(any(target="native", target="wasm"))
fn find_code_unit_from_string(
  data : String,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  guard start < end else { return -1 }
  if data.unsafe_get(start) == code {
    return start
  }
  let code_v = i16x8_splat(code)
  let tail_start = for pos = start; pos + 8 <= end; {
    let mask = i16x8_bitmask(i16x8_eq(v128_load_i16x8(data, pos), code_v))
    if mask != 0 {
      return pos + mask.ctz()
    }
    continue pos + 8
  } nobreak {
    pos
  }
  find_code_unit_scalar(data, tail_start, end, code)
}

///|
// SIMD reverse code-unit scanner for linear-memory backends. It scans
// eight-code-unit chunks from the end and returns the highest matching offset.
#cfg(any(target="native", target="wasm"))
fn rev_find_code_unit_from_string(
  data : String,
  start : Int,
  end : Int,
  code : UInt16,
) -> Int {
  guard start < end else { return -1 }
  if data.unsafe_get(end - 1) == code {
    return end - 1
  }
  let code_v = i16x8_splat(code)
  let head_end = for pos = end; pos - 8 >= start; {
    let chunk_start = pos - 8
    let mask = i16x8_bitmask(
      i16x8_eq(v128_load_i16x8(data, chunk_start), code_v),
    )
    if mask != 0 {
      return chunk_start + 31 - mask.clz()
    }
    continue chunk_start
  } nobreak {
    pos
  }
  rev_find_code_unit_scalar(data, start, head_end, code)
}
