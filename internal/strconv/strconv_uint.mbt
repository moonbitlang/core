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
const UINT_MAX : UInt32 = 0xffffffff

///|
const UINT64_MAX : UInt64 = 0xffffffffffffffffUL

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
///   inspect(@strconv.parse_uint64("123"), content="123")
///   inspect(@strconv.parse_uint64("0xff", base=0), content="255")
///   inspect(@strconv.parse_uint64("0o10"), content="8")
///   inspect(@strconv.parse_uint64("0b1010"), content="10")
///   inspect(@strconv.parse_uint64("1_234"), content="1234")
///   inspect(@strconv.parse_uint64("ff", base=16), content="255")
///   inspect(@strconv.parse_uint64("zz", base=36), content="1295")
/// }
/// ```
///
pub fn parse_uint64(str : StringView, base~ : Int32 = 0) -> UInt64 raise {
  guard str != "" else { syntax_err() }
  if str is ['+' | '-', ..] {
    syntax_err()
  }

  // `allow_underscore` is used to check validity of underscores
  let (num_base, rest, allow_underscore) = check_and_consume_base(str, base)

  // calculate overflow threshold
  let overflow_threshold = match num_base {
    10 => UINT64_MAX / 10 + 1
    16 => UINT64_MAX / 16 + 1
    _ => UINT64_MAX / num_base.to_uint64() + 1
  }
  let has_digit = rest
    is (['0'..<='9' | 'a'..<='z' | 'A'..<='Z', ..]
    | ['_', '0'..<='9' | 'a'..<='z' | 'A'..<='Z', ..])
  guard has_digit else { syntax_err() }
  for rest = rest, acc = 0UL, allow_underscore = allow_underscore {
    match (rest, acc, allow_underscore) {
      (['_'], _, _) =>
        // the last character cannot be underscore
        syntax_err()
      (['_', ..], _, false) => syntax_err()
      (['_', .. rest], acc, true) => continue rest, acc, false
      ([c, .. rest], acc, _) => {
        let c = c.to_int()
        let d = match c {
          '0'..<='9' => c - '0'
          'a'..<='z' => c + (10 - 'a')
          'A'..<='Z' => c + (10 - 'A')
          _ => syntax_err()
        }
        guard d < num_base else { syntax_err() }
        guard acc < overflow_threshold else { range_err() }
        let next_acc = acc * num_base.to_uint64() + d.to_uint64()
        guard next_acc >= acc && next_acc <= UINT64_MAX else { range_err() }
        continue rest, next_acc, true
      }
      ([], acc, _) => break acc
    }
  }
}

///|
/// Parse a string in the given base (0, 2 to 36), return an UInt number or an error.
/// If the `base` argument is 0, the base will be inferred by the prefix.
pub fn parse_uint(str : StringView, base~ : Int32 = 0) -> UInt32 raise {
  let n = parse_uint64(str, base~)
  if n > UINT_MAX.to_uint64() {
    range_err()
  }
  n.to_uint()
}
