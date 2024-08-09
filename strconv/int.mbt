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

let int_min = 0x80000000

let int_max = 0x7fffffff

let int64_min = -0x8000000000000000L

let int64_max = 0x7fffffffffffffffL

/// Parse a string in the given base (0, 2 to 36), return a Int64 number or an error.
/// If the `~base` argument is 0, the base will be inferred by the prefix.
pub fn parse_int64(str : String, ~base : Int = 0) -> Int64!StrConvError {
  if str == "" {
    syntax_err!()
  }
  // check underscore
  if not(check_underscore(str)) {
    syntax_err!()
  }
  let mut s = str
  // check sign
  let mut neg = false
  if s[0] == '+' || s[0] == '-' {
    neg = s[0] == '-'
    s = s.substring(start=1)
  }

  // determine base
  let mut num_base = 10
  if base == 0 {
    num_base = determine_base(s)
    if num_base != 10 {
      s = s.substring(start=2)
    }
  } else if 2 <= base && base <= 36 {
    num_base = base
  } else {
    base_err!()
  }

  // calculate overflow threshold
  let overflow_threshold = overflow_threshold(num_base, neg)

  // convert
  let mut n = 0L
  for i = 0; i < s.length(); i = i + 1 {
    let c = s[i]
    let mut d = 0
    if c == '_' {
      continue
    }
    if '0' <= c && c <= '9' {
      d = c.to_int() - '0'.to_int()
    } else if 'a' <= c && c <= 'z' {
      d = c.to_int() - 'a'.to_int() + 10
    } else if 'A' <= c && c <= 'Z' {
      d = c.to_int() - 'A'.to_int() + 10
    } else {
      syntax_err!()
    }
    if d >= num_base {
      syntax_err!()
    }
    if (neg && n < overflow_threshold) || (not(neg) && n >= overflow_threshold) {
      range_err!()
    }
    // n*base overflows
    n *= num_base.to_int64()
    if neg {
      let n1 = n - d.to_int64()
      if n1 > n {
        range_err!()
      }
      n = n1
    } else {
      let n1 = n + d.to_int64()
      if n1 < n {
        // n+d overflows
        range_err!()
      }
      n = n1
    }
  }
  n
}

/// Parse a string in the given base (0, 2 to 36), return a Int number or an error.
/// If the `~base` argument is 0, the base will be inferred by the prefix.
pub fn parse_int(str : String, ~base : Int = 0) -> Int!StrConvError {
  let n = parse_int64!(str, ~base)
  if n < int_min.to_int64() || n > int_max.to_int64() {
    range_err!()
  }
  n.to_int()
}

// Check whether the underscores are correct.
// Underscores must appear only between digits or between a base prefix and a digit.
fn check_underscore(str : String) -> Bool {
  let mut s = str
  // 0 digit or base prefix
  // _ underscore
  // ! other
  let mut last_char = '!'
  // sign
  if s.length() > 1 && (s[0] == '-' || s[0] == '+') {
    s = s.substring(start=1)
  }
  // base prefix
  let mut hex = false
  if s.length() >= 2 &&
    s[0] == '0' &&
    (
      s[1] == 'b' ||
      s[1] == 'B' ||
      s[1] == 'o' ||
      s[1] == 'O' ||
      s[1] == 'x' ||
      s[1] == 'X'
    ) {
    last_char = '0'
    hex = s[1] == 'x' || s[1] == 'X'
    s = s.substring(start=2)
  }
  // number
  for i = 0; i < s.length(); i = i + 1 {
    // digits
    if '0' <= s[i] && s[i] <= '9' {
      last_char = '0'
      continue
    }
    if (hex && 'a' <= s[i] && s[i] <= 'f') || ('A' <= s[i] && s[i] <= 'F') {
      last_char = '0'
      continue
    }
    // underscore must follow digit
    if s[i] == '_' {
      if last_char != '0' {
        return false
      }
      last_char = '_'
      continue
    }
    // underscore cannot follow by underscore
    if last_char == '_' {
      return false
    }
    // other
    last_char = '!'
  }
  return last_char != '_'
}

// Determine the base of the value.
fn determine_base(s : String) -> Int {
  if s.length() < 2 {
    return 10
  }
  match s.substring(end=2) {
    "0x" | "0X" => 16
    "0o" | "0O" => 8
    "0b" | "0B" => 2
    _ => 10
  }
}

fn overflow_threshold(base : Int, neg : Bool) -> Int64 {
  if not(neg) {
    if base == 10 {
      int64_max / 10L + 1L
    } else if base == 16 {
      int64_max / 16L + 1L
    } else {
      int64_max / base.to_int64() + 1L
    }
  } else if base == 10 {
    int64_min / 10L
  } else if base == 16 {
    int64_min / 16L
  } else {
    int64_min / base.to_int64()
  }
}

test "check_underscore" {
  @test.is_true!(check_underscore("123"))
  @test.is_true!(check_underscore("0x123"))
  @test.is_true!(check_underscore("0o123"))
  @test.is_true!(check_underscore("0b101"))
  @test.is_true!(check_underscore("1_2_3"))
  @test.is_true!(check_underscore("0x_1_2_3_A_F"))
  @test.is_true!(check_underscore("0o_1_2_3"))
  @test.is_true!(check_underscore("0b_1_0_1"))
  @test.is_false!(check_underscore("1__2_3"))
  @test.is_false!(check_underscore("_123"))
  @test.is_false!(check_underscore("123_"))
}

test "determine_base" {
  @test.eq!(determine_base("1234"), 10)
  @test.eq!(determine_base("0x1234"), 16)
  @test.eq!(determine_base("0X1234"), 16)
  @test.eq!(determine_base("0o1234"), 8)
  @test.eq!(determine_base("0O1234"), 8)
  @test.eq!(determine_base("0b1010"), 2)
  @test.eq!(determine_base("0B1010"), 2)
}

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
  for i = 0; i < tests.length(); i = i + 1 {
    let t = tests[i]
    @test.eq!(
      try {
        Result::Ok(parse_int64!(t.0))
      } catch {
        StrConvError(err) => Err(err)
      },
      t.1,
    )
  }
}

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
    ("1000000000000000", 2, Ok(1L.lsl(15))),
    (
      "111111111111111111111111111111111111111111111111111111111111111",
      2,
      Ok(1L.lsl(63) - 1L),
    ),
    (
      "1000000000000000000000000000000000000000000000000000000000000000",
      2,
      Err(range_err_str),
    ),
    (
      "-1000000000000000000000000000000000000000000000000000000000000000",
      2,
      Ok(-1L.lsl(63)),
    ),
    (
      "-1000000000000000000000000000000000000000000000000000000000000001",
      2,
      Err(range_err_str),
    ),
    // base 8
    ("-10", 8, Ok(-8L)),
    ("57635436545", 8, Ok(0o57635436545L)),
    ("100000000", 8, Ok(1L.lsl(24))),
    // base 16
    ("10", 16, Ok(16L)),
    ("-123456789abcdef", 16, Ok(-0x123456789abcdefL)),
    ("7fffffffffffffff", 16, Ok(1L.lsl(63) - 1L)),
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
  for i = 0; i < tests.length(); i = i + 1 {
    let t = tests[i]
    @test.eq!(
      try {
        Result::Ok(parse_int64!(t.0, base=t.1))
      } catch {
        StrConvError(err) => Err(err)
      },
      t.2,
    )
  }
}

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
    ("2147483647", Ok((1).lsl(31) - 1)),
    ("-2147483647", Ok(-((1).lsl(31) - 1))),
    ("2147483648", Err(range_err_str)),
    ("-2147483648", Ok((-1).lsl(31))),
    ("2147483649", Err(range_err_str)),
    ("-2147483649", Err(range_err_str)),
    ("-1_2_3_4_5", Ok(-12345)),
    ("-_12345", Err(syntax_err_str)),
    ("_12345", Err(syntax_err_str)),
    ("1__2345", Err(syntax_err_str)),
    ("12345_", Err(syntax_err_str)),
    ("123%45", Err(syntax_err_str)),
  ]
  for i = 0; i < tests.length(); i = i + 1 {
    let t = tests[i]
    @test.eq!(
      try {
        Result::Ok(parse_int!(t.0))
      } catch {
        StrConvError(err) => Err(err)
      },
      t.1,
    )
  }
}
