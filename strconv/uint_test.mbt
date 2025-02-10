// Copyright 2025 International Digital Economy Academy
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
test "@strconv.parse_uint64/base_handling" {
  // Different bases with valid input
  inspect!(@strconv.parse_uint64?("FF", base=16), content="Ok(255)")
  inspect!(@strconv.parse_uint64?("0xFF"), content="Ok(255)")
  inspect!(@strconv.parse_uint64?("377", base=8), content="Ok(255)")
  inspect!(@strconv.parse_uint64?("0o377"), content="Ok(255)")
  inspect!(@strconv.parse_uint64?("11111111", base=2), content="Ok(255)")
  inspect!(@strconv.parse_uint64?("0b11111111"), content="Ok(255)")
}

///|
test "@strconv.parse_uint64/underscore" {
  // Valid underscore placements
  inspect!(@strconv.parse_uint64?("1_000_000"), content="Ok(1000000)")
  inspect!(@strconv.parse_uint64?("0xff_ff_ff"), content="Ok(16777215)")
  // Invalid underscore placements
  inspect!(@strconv.parse_uint64?("_123"), content="Err(invalid syntax)")
  inspect!(@strconv.parse_uint64?("123_"), content="Err(invalid syntax)")
  inspect!(@strconv.parse_uint64?("1__23"), content="Err(invalid syntax)")
}

///|
test "panic @strconv.parse_uint64/errors" {
  // Empty string
  ignore(@strconv.parse_uint64!(""))
  // Invalid base
  ignore(@strconv.parse_uint64!("123", base=37))
  // Signs not allowed
  ignore(@strconv.parse_uint64!("+123"))
  ignore(@strconv.parse_uint64!("-123"))
  // Range error (overflow)
  ignore(@strconv.parse_uint64!("18446744073709551616"))
}

///|
test "@strconv.parse_uint64/hex_and_edge_cases" {
  // Valid hexadecimal numbers with 0x/0X prefix
  inspect!(@strconv.parse_uint64?("0xDEADBEEF"), content="Ok(3735928559)")
  inspect!(@strconv.parse_uint64?("0XDEADBEEF"), content="Ok(3735928559)")

  // Valid hexadecimal numbers without prefix when base=16 is specified
  inspect!(
    @strconv.parse_uint64?("deadbeef", base=16),
    content="Ok(3735928559)",
  )

  // Valid hexadecimal numbers with allowed underscore placements
  inspect!(@strconv.parse_uint64?("0xDEAD_BEEF"), content="Ok(3735928559)")
  inspect!(
    @strconv.parse_uint64?("dead_beef", base=16),
    content="Ok(3735928559)",
  )
  inspect!(@strconv.parse_uint64?("0x1_2345"), content="Ok(74565)")

  // Edge case: zero value
  inspect!(@strconv.parse_uint64?("0x0"), content="Ok(0)")
  inspect!(@strconv.parse_uint64?("0x00"), content="Ok(0)")

  // Edge case: maximum valid uint64 value (all bits set)
  inspect!(
    @strconv.parse_uint64?("0xFFFFFFFFFFFFFFFF"),
    content="Ok(18446744073709551615)",
  )
  inspect!(@strconv.parse_uint64?("0xDEADBEEF_"), content="Err(invalid syntax)")
  inspect!(
    @strconv.parse_uint64?("0xDE__AD_BEEF"),
    content="Err(invalid syntax)",
  )

  // Invalid hex digit (G is not a valid base-16 digit)
  inspect!(@strconv.parse_uint64?("0xDEADBEG"), content="Err(invalid syntax)")
}

///|
test "edge cases" {
  // Invalid: Missing digits after hex prefix
  inspect!(@strconv.parse_uint64?("0x"), content="Err(invalid syntax)")
  inspect!(@strconv.parse_uint64?("0x_"), content="Err(invalid syntax)")

  // Underscore is allowed between the prefix and the first digit
  inspect!(@strconv.parse_uint64?("0x_DEADBEEF"), content="Ok(3735928559)")
}
