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
test "StringBuilder growth capacity doubles while representable" {
  inspect(stringbuilder_growth_capacity(8, 8, 9), content="16")
  inspect(stringbuilder_growth_capacity(8, 8, 33), content="64")
}

///|
test "StringBuilder growth capacity falls back to the exact requirement" {
  inspect(
    stringbuilder_growth_capacity(0x40000000, 0x40000000, 0x40000001),
    content="1073741825",
  )
  inspect(
    stringbuilder_growth_capacity(0x20000000, 0x20000000, 0x40000001),
    content="1073741825",
  )
}

///|
test "panic StringBuilder growth rejects a wrapped required size" {
  ignore(stringbuilder_growth_capacity(16, 16, -1))
}

///|
test "UTF-16 blit preserves copy boundaries and raw code units" {
  let pattern : Array[Int32] = [
    0, 0x61, 0xff, 0x100, 0x4e2d, 0xd83d, 0xde00, 0xd800, 0xffff,
  ]
  for len in 0..<66 {
    for
      (src_offset, dst_offset) in [
        (0, 0),
        (1, 0),
        (0, 1),
        (1, 3),
        (7, 5),
        (8, 16),
      ] {
      for src_suffix in [0, 9] {
        let units = FixedArray::makei(src_offset + len + src_suffix, i => {
          pattern[i % pattern.length()].to_uint16()
        })
        let source = unsafe_fixedarray_uint16_to_string(units)
        for dst_suffix in [0, 9] {
          let output = FixedArray::make(
            dst_offset + len + dst_suffix,
            (0xabcd).to_uint16(),
          )
          output.unsafe_blit_from_string(dst_offset, source, src_offset, len)
          for i in 0..<output.length() {
            let expected = if i >= dst_offset && i < dst_offset + len {
              pattern[(src_offset + i - dst_offset) % pattern.length()].to_uint16()
            } else {
              (0xabcd).to_uint16()
            }
            if output[i] != expected {
              fail(
                "len=\{len} src=\{src_offset} dst=\{dst_offset} index=\{i}: unexpected code unit",
              )
            }
          }
        }
      }
    }
  }
}
