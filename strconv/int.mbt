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
  view : StringView,
  base : Int,
) -> (Int, StringView, Bool) raise StrConvError {
  // if the base is not given, we need to determine it from the prefix
  if base == 0 {
    match view {
      ['0', 'x' | 'X', .. rest] => (16, rest, true)
      ['0', 'o' | 'O', .. rest] => (8, rest, true)
      ['0', 'b' | 'B', .. rest] => (2, rest, true)
      _ => (10, view, false)
    }
  } else {
    // if the base is given, we need to check whether the prefix is consistent with it
    match view {
      ['0', 'x' | 'X', .. rest] if base == 16 => (16, rest, true)
      ['0', 'o' | 'O', .. rest] if base == 8 => (8, rest, true)
      ['0', 'b' | 'B', .. rest] if base == 2 => (2, rest, true)
      _ => if base is (2..=36) { (base, view, false) } else { base_err() }
    }
  }
}

///|
test {
  inspect(try? parse_int64("0b01", base=3), content="Err(invalid syntax)")
  inspect(try? parse_int64("0x01", base=3), content="Err(invalid syntax)")
  inspect(try? parse_int64("0o01", base=3), content="Err(invalid syntax)")
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
/// ```mbt check
/// test {
///   inspect(@strconv.parse_int64("123"), content="123")
///   inspect(@strconv.parse_int64("0xff", base=0), content="255")
///   inspect(@strconv.parse_int64("0o10"), content="8")
///   inspect(@strconv.parse_int64("0b1010"), content="10")
///   inspect(@strconv.parse_int64("1_234"), content="1234")
///   inspect(@strconv.parse_int64("-123"), content="-123")
///   inspect(@strconv.parse_int64("ff", base=16), content="255")
///   inspect(@strconv.parse_int64("zz", base=36), content="1295")
/// }
/// ```
/// 
pub fn parse_int64(
  str : StringView,
  base? : Int = 0,
) -> Int64 raise StrConvError {
  guard str != "" else { syntax_err() }
  let (neg, rest) = match str.view() {
    ['+', .. rest] => (false, rest)
    ['-', .. rest] => (true, rest)
    rest => (false, rest)
  }

  // `allow_underscore` is used to check validity of underscores
  let (num_base, rest, allow_underscore) = check_and_consume_base(rest, base)

  // calculate overflow threshold
  let overflow_threshold = overflow_threshold(num_base, neg)
  let has_digit = rest
    is (['0'..='9' | 'a'..='z' | 'A'..='Z', ..]
    | ['_', '0'..='9' | 'a'..='z' | 'A'..='Z', ..])
  guard has_digit else { syntax_err() }
  // convert
  loop (rest, 0L, allow_underscore) {
    (['_'], _, _) =>
      // the last character cannot be underscore
      syntax_err()
    (['_', ..], _, false) => syntax_err()
    (['_', .. rest], acc, true) => continue (rest, acc, false)
    ([c, .. rest], acc, _) => {
      let c = c.to_int()
      let d = match c {
        '0'..='9' => c - '0'
        'a'..='z' => c + (10 - 'a')
        'A'..='Z' => c + (10 - 'A')
        _ => syntax_err()
      }
      guard d < num_base else { syntax_err() }
      if neg {
        guard acc >= overflow_threshold else { range_err() }
        let next_acc = acc * num_base.to_int64() - d.to_int64()
        guard next_acc <= acc else { range_err() }
        continue (rest, next_acc, true)
      } else {
        guard acc < overflow_threshold else { range_err() }
        let next_acc = acc * num_base.to_int64() + d.to_int64()
        guard next_acc >= acc else { range_err() }
        continue (rest, next_acc, true)
      }
    }
    ([], acc, _) => acc
  }
}

///|
/// Parse a string in the given base (0, 2 to 36), return a Int number or an error.
/// If the `~base` argument is 0, the base will be inferred by the prefix.
pub fn parse_int(str : StringView, base? : Int = 0) -> Int raise StrConvError {
  let n = parse_int64(str, base~)
  if n < INT_MIN.to_int64() || n > INT_MAX.to_int64() {
    range_err()
  }
  n.to_int()
}

// Check whether the underscores are correct.
// Underscores must appear only between digits or between a base prefix and a digit.

///|
fn check_underscore(str : StringView) -> Bool {
  // skip the sign
  let rest = match str {
    ['+' | '-', .. rest] => rest
    rest => rest
    // CR: the type maybe a bit confusing?
  }

  // base prefix
  let (rest, allow_underscore, hex) = lexmatch rest {
    ("0[xX]", rest) => (rest, true, true)
    ("0[oO]", rest) => (rest, true, false)
    ("0[bB]", rest) => (rest, true, false)
    _ => (rest, false, false)
  }

  // 'e' and 'E' are valid hex digits
  // but are not treated as digits in decimal strings since they're used for scientific notation
  fn is_digit(c : Char) -> Bool {
    c is ('0'..='9') || (hex && c is ('a'..='f' | 'A'..='F'))
  }

  // Track whether the previous character was an underscore
  let follow_underscore = false
  loop (rest, allow_underscore, follow_underscore) {
    // Empty string is valid
    ([], _, _) => true
    // String ending with underscore is invalid
    (['_'], _, _) => false
    // Underscore not allowed in current position (e.g., between non-digits)
    (['_', ..], false, _) => false
    // Valid underscore - continue but mark that next char must be a digit
    (['_', .. rest], true, _) => continue (rest, false, true)
    // Handle non-underscore character
    ([c, .. rest], _, follow_underscore) =>
      if is_digit(c) {
        // Digit found - allow underscore in next position
        continue (rest, true, false)
      } else if follow_underscore {
        // Non-digit found after underscore - invalid
        false
      } else {
        // Non-digit found (not after underscore) - continue but don't allow underscores
        continue (rest, false, false)
      }
  }
}

///|
fn overflow_threshold(base : Int, neg : Bool) -> Int64 {
  if !neg {
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
