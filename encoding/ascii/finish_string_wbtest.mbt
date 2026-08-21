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
/// Every decoder finishes through `finish_string`; it must keep exactly the
/// first `len` code units, both when the buffer is full and when it must
/// truncate.
test "quickcheck: finish_string keeps exactly the first len code units" {
  @quickcheck.check(count=100, (input : (Array[Int], Int)) => {
    let units = input.0.map(x => (x & 0x7F).to_uint16())
    let buffer = FixedArray::makei(units.length(), i => units[i])
    let take = if units.is_empty() {
      0
    } else {
      let r = input.1 % (units.length() + 1)
      if r < 0 {
        r + units.length() + 1
      } else {
        r
      }
    }
    let expected = StringBuilder(size_hint=take)
    for i in 0..<take {
      expected.write_char(
        units[i].to_uint().reinterpret_as_int().unsafe_to_char(),
      )
    }
    finish_string(buffer, take) == expected.to_string()
  })
}
