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
#cfg(not(target="js"))
fn join_length_add(length : Int32, extra : Int32) -> Int32 {
  guard extra <= 0x7FFFFFFF - length else {
    abort("String join length overflow")
  }
  length + extra
}

///|
#cfg(not(target="js"))
fn[A : ToStringView] join_string_views(
  parts : ArrayView[A],
  separator : StringView,
) -> String {
  match parts {
    [] => ""
    [one] => one.to_string_view().to_owned()
    [first, .. rest] => {
      // ToStringView is closed to external implementations; String and
      // StringView conversions are stable, so two passes need no cache.
      let first = first.to_string_view()
      let length = for part in rest; length = first.length() {
        continue join_length_add(
            join_length_add(length, separator.length()),
            part.to_string_view().length(),
          )
      } nobreak {
        length
      }
      if length == 0 {
        return ""
      }
      let output : UninitializedArray[UInt16] = UninitializedArray::make(length)
      output.unsafe_blit_from_string_uninit(
        0,
        first.data(),
        first.start_offset(),
        first.length(),
      )
      for part in rest; offset = first.length() {
        let part = part.to_string_view()
        output.unsafe_blit_from_string_uninit(
          offset,
          separator.data(),
          separator.start_offset(),
          separator.length(),
        )
        let offset = offset + separator.length()
        output.unsafe_blit_from_string_uninit(
          offset,
          part.data(),
          part.start_offset(),
          part.length(),
        )
        continue offset + part.length()
      }
      // All `length` slots have been initialized exactly once. The output
      // buffer is local and will never be mutated after conversion.
      unsafe_fixedarray_uint16_to_string(
        unsafe_uint16_buffer_as_fixedarray(output),
      )
    }
  }
}

///|
#cfg(target="js")
fn[A : ToStringView] join_string_views(
  parts : ArrayView[A],
  separator : StringView,
) -> String {
  match parts {
    [] => ""
    [one] => one.to_string_view().to_owned()
    [first, .. rest] => {
      let separator = separator.to_owned()
      let mut result = first.to_string_view().to_owned()
      for part in rest {
        result += separator
        result += part.to_string_view().to_owned()
      }
      result
    }
  }
}
