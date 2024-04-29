// Copyright 2024 International Digital Economy Academy
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


// NOTE: Since the `builtin` package cannot contain tests, the tests of 
// primitive type `Byte` lays in this file.

/// Convert an `Int` within 0-255 (0x00-0xFF) to `Byte`.
pub fn Byte::from_int_checked(v: Int) -> Option[Byte] {
  if 0x00 <= v && v <= 0xff {
    Some(Byte::from_int(v))
  } else {
    None
  }
}

test "from_int_checked" {
  let map_byte_to_int = fn (byte: Byte) -> Int {
    byte.to_int()
  }

  for i = 0; i <= 0xff; i = i + 1 {
    let r = Byte::from_int_checked(i).map(map_byte_to_int);
    @assertion.assert_eq(r, Some(i))?;
  }
  @assertion.assert_eq(Byte::from_int_checked(-0x70000000).map(map_byte_to_int), None)?;
  @assertion.assert_eq(Byte::from_int_checked(-1).map(map_byte_to_int), None)?;
  @assertion.assert_eq(Byte::from_int_checked(256).map(map_byte_to_int), None)?;
  @assertion.assert_eq(Byte::from_int_checked(0x70000000).map(map_byte_to_int), None)?;
}
