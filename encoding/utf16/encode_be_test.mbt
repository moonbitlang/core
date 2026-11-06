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
test "big endian encode preserves every code unit, view offset and BOM" {
  // Exhaust non-surrogate BMP units with valid UTF-16 input.
  let count = 0xF800
  let raw = FixedArray::makei(count * 2, i => {
    let code = i / 2
    let code = if code < 0xD800 { code } else { code + 0x800 }
    (code >> (i % 2 * 8)).to_byte()
  })
  let text = raw.unsafe_reinterpret_as_bytes().to_unchecked_string()
  let views : Array[StringView] = []
  for start in 0..<5 {
    for length in [0, 1, 7, 8, 9, 15, 16, 17, 31, 32, count - start] {
      views.push(text[start:start + length])
    }
  }
  // Each high and low surrogate occurs once, always in a valid pair.
  let pairs = String::from_array(
    Array::makei(1024, i => (0x10000 + i * 0x401).unsafe_to_char()),
  )
  for prefix in 0..<9 {
    let padded = "---" + String::make(prefix, 'a') + pairs + "+++"
    views.push(padded[3:padded.length() - 3])
  }
  for view in views {
    for bom in [false, true] {
      let got = @utf16.encode(view, bom~, endianness=Big)
      let prefix = if bom { 2 } else { 0 }
      assert_eq(got.length(), view.length() * 2 + prefix)
      if bom {
        assert_eq(got[0], b'\xfe')
        assert_eq(got[1], b'\xff')
      }
      for i in 0..<view.length() {
        let unit = view.unsafe_get(i).to_int()
        assert_eq(got[prefix + i * 2], (unit >> 8).to_byte())
        assert_eq(got[prefix + i * 2 + 1], (unit & 0xff).to_byte())
      }
    }
  }
}
