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
test "parse_uint64 overflow check" {
  let largest_uint64 = "18446744073709551615" // Maximum UInt64 value
  let result = @strconv.parse_uint64(largest_uint64)
  inspect(result, content="18446744073709551615")

  // Test overflow with very large value
  try {
    let overflow_val = "18446744073709551616" // One more than max UInt64
    let _ = @strconv.parse_uint64(overflow_val)
    fail("Expected range error for overflow value")
  } catch {
    @strconv.StrConvError(err) => inspect(err, content="value out of range")
    _ => fail("Expected StrConvError but got different error")
  }

  // Test overflow with large base 16 value
  try {
    let overflow_hex = "ffffffffffffffff1" // Larger than max UInt64 in hex
    let _ = @strconv.parse_uint64(overflow_hex, base=16)
    fail("Expected range error for overflow hex value")
  } catch {
    @strconv.StrConvError(err) => inspect(err, content="value out of range")
    _ => fail("Expected StrConvError but got different error")
  }
}
