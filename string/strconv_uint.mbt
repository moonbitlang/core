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
/// Parses a string into a UInt64 number using the specified base, or returns an error.
/// The base must be 0 or between 2 and 36 (inclusive). If base is 0, it will be
/// inferred from the string prefix:
///   - "0x" or "0X" for base 16 (hex)
///   - "0o" or "0O" for base 8 (octal)
///   - "0b" or "0B" for base 2 (binary)
///   - Default is base 10 (decimal)
/// For readability, underscores may appear after base prefixes or between digits.
/// These underscores do not affect the value.
/// Examples:
/// ```mbt check
/// test {
///   inspect(@string.parse_uint64("123"), content="123")
///   inspect(@string.parse_uint64("0xff", base=0), content="255")
///   inspect(@string.parse_uint64("0o10"), content="8")
///   inspect(@string.parse_uint64("0b1010"), content="10")
///   inspect(@string.parse_uint64("1_234"), content="1234")
///   inspect(@string.parse_uint64("ff", base=16), content="255")
///   inspect(@string.parse_uint64("zz", base=36), content="1295")
/// }
/// ```
///
pub fn parse_uint64(str : StringView, base? : Int = 0) -> UInt64 raise {
  @internal/strconv.parse_uint64(str, base~)
}

///|
/// Parse a string in the given base (0, 2 to 36), return an UInt number or an error.
/// If the `~base` argument is 0, the base will be inferred by the prefix.
pub fn parse_uint(str : StringView, base? : Int = 0) -> UInt raise {
  @internal/strconv.parse_uint(str, base~)
}

///|
test "parse_uint64 wrapper" {
  inspect(parse_uint64("18446744073709551615"), content="18446744073709551615")
  inspect(
    try? parse_uint64("18446744073709551616"),
    content=(
      #|Err(Failure("value out of range"))
    ),
  )
}

///|
test "parse_uint64 uppercase hex and invalid base" {
  inspect(try? parse_uint64("ABCD", base=16), content="Ok(43981)")
  inspect(
    try? parse_uint64("1234", base=37),
    content=(
      #|Err(Failure("invalid base"))
    ),
  )
}
