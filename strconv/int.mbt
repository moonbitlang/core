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
const INT_MIN = 0x80000000

///|
const INT_MAX = 0x7fffffff

///|
const INT64_MIN = -0x8000000000000000L

///|
const INT64_MAX = 0x7fffffffffffffffL

///|
/// This function check whether the prefix of the string is consistent with the given base,
/// and consume the prefix.
/// The boolean flag `allow_underscore` is used to check validity of underscores.
fn check_and_consume_base(
  view : @string.StringView,
  base : Int
) -> (Int, @string.StringView, Bool)!StrConvError {
  match view {
    ['0', 'x' | 'X', .. rest] => {
      guard base is (0 | 16) else { base_err!() }
      (16, rest, true)
    }
    ['0', 'o' | 'O', .. rest] => {
      guard base is (0 | 8) else { base_err!() }
      (8, rest, true)
    }
    ['0', 'b' | 'B', .. rest] => {
      guard base is (0 | 2) else { base_err!() }
      (2, rest, true)
    }
    rest =>
      match base {
        0 => (10, rest, false)
        2..=36 => (base, rest, false)
        _ => base_err!()
      }
  }
}

///|
test {
  inspect!(parse_int64?("0b01", base=3), content="Err(invalid base)")
  inspect!(parse_int64?("0x01", base=3), content="Err(invalid base)")
  inspect!(parse_int64?("0o01", base=3), content="Err(invalid base)")
}

///|
/// Parses a string into an Int64 number using the specified base, or returns an error.
/// The base must be 0 or between 2 and 36 (inclusive). If base is 0, it will be 
/// inferred from the string prefix:
///   - "0x" or "0X" for base 16 (hex)
///   - "0o" or "0O" for base 8 (octal) 
///   - "0b" or "0B" for base 2 (binary)
///   - Default is base 10 (decimal)
/// For readability, underscores may appear after base prefixes or between digits.
/// These underscores do not affect the value.
/// Examples:
/// ```
/// inspect!(parse_int64!("123"), content="123")
/// inspect!(parse_int64!("0xff", base=0), content="255") 
/// inspect!(parse_int64!("0o10"), content="8")
/// inspect!(parse_int64!("0b1010"), content="10")
/// inspect!(parse_int64!("1_234"), content="1234")
/// inspect!(parse_int64!("-123"), content="-123")
/// inspect!(parse_int64!("ff", base=16), content="255")
/// inspect!(parse_int64!("zz", base=36), content="1295")
/// ```
/// 
pub fn parse_int64(str : String, base~ : Int = 0) -> Int64!StrConvError {
  guard str != "" else { syntax_err!() }
  let (neg, rest) = match str.view() {
    ['+', .. rest] => (false, rest)
    ['-', .. rest] => (true, rest)
    rest => (false, rest)
  }

  // `allow_underscore` is used to check validity of underscores
  let (num_base, rest, allow_underscore) = check_and_consume_base!(rest, base)

  // calculate overflow threshold
  let overflow_threshold = overflow_threshold(num_base, neg)
  let has_digit = rest
    is (['0'..='9' | 'a'..='z' | 'A'..='Z', ..]
    | ['_', '0'..='9' | 'a'..='z' | 'A'..='Z', ..])
  guard has_digit else { syntax_err!() }
  // convert
  loop rest, 0L, allow_underscore {
    ['_'], _, _ =>
      // the last character cannot be underscore
      syntax_err!()
    ['_', ..], _, false => syntax_err!()
    ['_', .. rest], acc, true => continue rest, acc, false
    [c, .. rest], acc, _ => {
      let c = c.to_int()
      let d = match c {
        '0'..='9' => c - '0'
        'a'..='z' => c + (10 - 'a')
        'A'..='Z' => c + (10 - 'A')
        _ => syntax_err!()
      }
      guard d < num_base else { syntax_err!() }
      if neg {
        guard acc >= overflow_threshold else { range_err!() }
        let next_acc = acc * num_base.to_int64() - d.to_int64()
        guard next_acc <= acc else { range_err!() }
        continue rest, next_acc, true
      } else {
        guard acc < overflow_threshold else { range_err!() }
        let next_acc = acc * num_base.to_int64() + d.to_int64()
        guard next_acc >= acc else { range_err!() }
        continue rest, next_acc, true
      }
    }
    [], acc, _ => acc
  }
}

///|
/// Parse a string in the given base (0, 2 to 36), return a Int number or an error.
/// If the `~base` argument is 0, the base will be inferred by the prefix.
pub fn parse_int(str : String, base~ : Int = 0) -> Int!StrConvError {
  let n = parse_int64!(str, base~)
  if n < INT_MIN.to_int64() || n > INT_MAX.to_int64() {
    range_err!()
  }
  n.to_int()
}

///|
// Check whether the underscores are correct.
// Underscores must appear only between digits or between a base prefix and a digit.
fn check_underscore(str : String) -> Bool {
  // skip the sign
  let rest = match str {
    ['+' | '-', .. rest] => rest
    rest => rest
    // CR: the type maybe a bit confusing?
  }

  // base prefix
  let (rest, allow_underscore, hex) = match rest {
    ['0', 'x' | 'X', .. rest] => (rest, true, true)
    ['0', 'o' | 'O', .. rest] => (rest, true, false)
    ['0', 'b' | 'B', .. rest] => (rest, true, false)
    rest => (rest, false, false)
  }

  // 'e' and 'E' are valid hex digits
  // but are not treated as digits in decimal strings since they're used for scientific notation
  fn is_digit(c : Char) -> Bool {
    c is ('0'..='9') || (hex && c is ('a'..='f' | 'A'..='F'))
  }

  // Track whether the previous character was an underscore
  let follow_underscore = false
  loop rest, allow_underscore, follow_underscore {
    // Empty string is valid
    [], _, _ => true
    // String ending with underscore is invalid
    ['_'], _, _ => false
    // Underscore not allowed in current position (e.g., between non-digits)
    ['_', ..], false, _ => false
    // Valid underscore - continue but mark that next char must be a digit
    ['_', .. rest], true, _ => continue rest, false, true
    // Handle non-underscore character
    [c, .. rest], _, follow_underscore =>
      if is_digit(c) {
        // Digit found - allow underscore in next position
        continue rest, true, false
      } else if follow_underscore {
        // Non-digit found after underscore - invalid
        false
      } else {
        // Non-digit found (not after underscore) - continue but don't allow underscores
        continue rest, false, false
      }
  }
}

///|
// Determine the base of the value.
fn determine_base(s : String) -> Int {
  match s {
    ['0', 'x' | 'X', ..] => 16
    ['0', 'o' | 'O', ..] => 8
    ['0', 'b' | 'B', ..] => 2
    _ => 10
  }
}

///|
fn overflow_threshold(base : Int, neg : Bool) -> Int64 {
  if not(neg) {
    if base == 10 {
      INT64_MAX / 10L + 1L
    } else if base == 16 {
      INT64_MAX / 16L + 1L
    } else {
      INT64_MAX / base.to_int64() + 1L
    }
  } else if base == 10 {
    INT64_MIN / 10L
  } else if base == 16 {
    INT64_MIN / 16L
  } else {
    INT64_MIN / base.to_int64()
  }
}

///|
test "check_underscore" {
  assert_true!(check_underscore("123"))
  assert_true!(check_underscore("0x123"))
  assert_true!(check_underscore("0o123"))
  assert_true!(check_underscore("0b101"))
  assert_true!(check_underscore("1_2_3"))
  assert_true!(check_underscore("0x_1_2_3_A_F"))
  assert_true!(check_underscore("0o_1_2_3"))
  assert_true!(check_underscore("0b_1_0_1"))
  assert_false!(check_underscore("1__2_3"))
  assert_false!(check_underscore("_123"))
  assert_false!(check_underscore("123_"))
}

///|
test "determine_base" {
  assert_eq!(determine_base("1234"), 10)
  assert_eq!(determine_base("0x1234"), 16)
  assert_eq!(determine_base("0X1234"), 16)
  assert_eq!(determine_base("0o1234"), 8)
  assert_eq!(determine_base("0O1234"), 8)
  assert_eq!(determine_base("0b1010"), 2)
  assert_eq!(determine_base("0B1010"), 2)
}

///|
test "parse_int64" {
  let tests : Array[(String, Result[Int64, String])] = [
    ("", Err(syntax_err_str)),
    ("0", Ok(0L)),
    ("-0", Ok(0L)),
    ("+0", Ok(0L)),
    ("1", Ok(1L)),
    ("-1", Ok(-1L)),
    ("+1", Ok(1L)),
    ("12345", Ok(12345L)),
    ("-12345", Ok(-12345L)),
    ("012345", Ok(12345L)),
    ("-012345", Ok(-12345L)),
    ("9876543210", Ok(9876543210L)),
    ("-9876543210", Ok(-9876543210L)),
    ("9223372036854775807", Ok(9223372036854775807L)),
    ("-9223372036854775807", Ok(-9223372036854775807L)),
    ("9223372036854775808", Err(range_err_str)),
    ("-9223372036854775808", Ok(-9223372036854775808L)),
    ("9223372036854775809", Err(range_err_str)),
    ("-9223372036854775809", Err(range_err_str)),
    ("-1_2_3_4_5", Ok(-12345L)),
    ("-_12345", Err(syntax_err_str)),
    ("_12345", Err(syntax_err_str)),
    ("1__2345", Err(syntax_err_str)),
    ("12345_", Err(syntax_err_str)),
    ("12345%", Err(syntax_err_str)),
  ]
  for i in 0..<tests.length() {
    let t = tests[i]
    assert_eq!(
      try {
        Result::Ok(parse_int64!(t.0))
      } catch {
        StrConvError(err) => Err(err)
      },
      t.1,
    )
  }
}

///|
test "parse_int64_base" {
  let tests : Array[(String, Int, Result[Int64, String])] = [
    ("", 0, Err(syntax_err_str)),
    ("0", 0, Ok(0L)),
    ("-0", 0, Ok(0L)),
    ("1", 0, Ok(1L)),
    ("-1", 0, Ok(-1L)),
    ("12345", 0, Ok(12345L)),
    ("-12345", 0, Ok(-12345L)),
    ("012345", 0, Ok(12345L)),
    ("-012345", 0, Ok(-12345L)),
    ("0x12345", 0, Ok(0x12345L)),
    ("-0x12345", 0, Ok(-0x12345L)),
    ("9876543210", 0, Ok(9876543210L)),
    ("-9876543210", 0, Ok(-9876543210L)),
    ("9223372036854775807", 0, Ok(9223372036854775807L)),
    ("-9223372036854775807", 0, Ok(-9223372036854775807L)),
    ("9223372036854775808", 0, Err(range_err_str)),
    ("12345x", 0, Err(syntax_err_str)),
    ("-12345x", 0, Err(syntax_err_str)),
    ("-9223372036854775808", 0, Ok(-9223372036854775808L)),
    ("9223372036854775809", 0, Err(range_err_str)),
    ("-9223372036854775809", 0, Err(range_err_str)),
    // other bases
    ("h", 18, Ok(17L)),
    ("10", 25, Ok(25L)),
    (
      "moonbit",
      35,
      Ok(
        (
          ((((22L * 35L + 24L) * 35L + 24L) * 35L + 23L) * 35L + 11L) * 35L +
          18L
        ) *
        35L +
        29L,
      ),
    ),
    (
      "moonbit",
      36,
      Ok(
        (
          ((((22L * 36L + 24L) * 36L + 24L) * 36L + 23L) * 36L + 11L) * 36L +
          18L
        ) *
        36L +
        29L,
      ),
    ),
    // base 2
    ("0", 2, Ok(0L)),
    ("-1", 2, Ok(-1L)),
    ("1010", 2, Ok(10L)),
    ("1000000000000000", 2, Ok(1L << 15)),
    (
      "111111111111111111111111111111111111111111111111111111111111111",
      2,
      Ok((1L << 63) - 1L),
    ),
    (
      "1000000000000000000000000000000000000000000000000000000000000000",
      2,
      Err(range_err_str),
    ),
    (
      "-1000000000000000000000000000000000000000000000000000000000000000",
      2,
      Ok(-1L << 63),
    ),
    (
      "-1000000000000000000000000000000000000000000000000000000000000001",
      2,
      Err(range_err_str),
    ),
    // base 8
    ("-10", 8, Ok(-8L)),
    ("57635436545", 8, Ok(0o57635436545L)),
    ("100000000", 8, Ok(1L << 24)),
    // base 16
    ("10", 16, Ok(16L)),
    ("-123456789abcdef", 16, Ok(-0x123456789abcdefL)),
    ("7fffffffffffffff", 16, Ok((1L << 63) - 1L)),
    // underscores
    ("-0x_1_2_3_4_5", 0, Ok(-0x12345L)),
    ("0x_1_2_3_4_5", 0, Ok(0x12345L)),
    ("-_0x12345", 0, Err(syntax_err_str)),
    ("_-0x12345", 0, Err(syntax_err_str)),
    ("_0x12345", 0, Err(syntax_err_str)),
    ("0x__12345", 0, Err(syntax_err_str)),
    ("0x1__2345", 0, Err(syntax_err_str)),
    ("0x1234__5", 0, Err(syntax_err_str)),
    ("0x12345_", 0, Err(syntax_err_str)),
    ("-0_1_2_3_4_5", 0, Ok(-12345L)),
    ("0_1_2_3_4_5", 0, Ok(12345L)),
    ("-_012345", 0, Err(syntax_err_str)),
    ("_-012345", 0, Err(syntax_err_str)),
    ("_012345", 0, Err(syntax_err_str)),
    ("0__12345", 0, Err(syntax_err_str)),
    ("01234__5", 0, Err(syntax_err_str)),
    ("012345_", 0, Err(syntax_err_str)),
    ("+0xf", 0, Ok(0xfL)),
    ("-0xf", 0, Ok(-0xfL)),
    ("0x+f", 0, Err(syntax_err_str)),
    ("0x-f", 0, Err(syntax_err_str)),
  ]
  for i in 0..<tests.length() {
    let t = tests[i]
    assert_eq!(
      try {
        Result::Ok(parse_int64!(t.0, base=t.1))
      } catch {
        StrConvError(err) => Err(err)
      },
      t.2,
    )
  }
}

///|
test "parse_int" {
  let tests : Array[(String, Result[Int, String])] = [
    ("", Err(syntax_err_str)),
    ("0", Ok(0)),
    ("-0", Ok(0)),
    ("1", Ok(1)),
    ("-1", Ok(-1)),
    ("12345", Ok(12345)),
    ("-12345", Ok(-12345)),
    ("012345", Ok(12345)),
    ("-012345", Ok(-12345)),
    ("12345x", Err(syntax_err_str)),
    ("-12345x", Err(syntax_err_str)),
    ("987654321", Ok(987654321)),
    ("-987654321", Ok(-987654321)),
    ("2147483647", Ok((1 << 31) - 1)),
    ("-2147483647", Ok(-((1 << 31) - 1))),
    ("2147483648", Err(range_err_str)),
    ("-2147483648", Ok(-1 << 31)),
    ("2147483649", Err(range_err_str)),
    ("-2147483649", Err(range_err_str)),
    ("-1_2_3_4_5", Ok(-12345)),
    ("-_12345", Err(syntax_err_str)),
    ("_12345", Err(syntax_err_str)),
    ("1__2345", Err(syntax_err_str)),
    ("12345_", Err(syntax_err_str)),
    ("123%45", Err(syntax_err_str)),
  ]
  for i in 0..<tests.length() {
    let t = tests[i]
    assert_eq!(
      try {
        Result::Ok(parse_int!(t.0))
      } catch {
        StrConvError(err) => Err(err)
      },
      t.1,
    )
  }
}
