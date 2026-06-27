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

// Black-box tests covering strconv paths the existing suites miss: explicit
// base prefixes and signs, uppercase hex digits, overflow detection, the
// disguised double fast-path, and underscore handling.

///|
/// Whether parsing `s` as an Int64 (in the given base) raises.
fn int64_raises(s : String, base : Int) -> Bool {
  try {
    @strconv.parse_int64(s, base~) |> ignore
    false
  } catch {
    _ => true
  }
}

///|
/// Whether parsing `s` as a Double raises.
fn double_raises(s : String) -> Bool {
  try {
    @strconv.parse_double(s) |> ignore
    false
  } catch {
    _ => true
  }
}

///|
/// Whether parsing `s` as an Int (32-bit) raises.
fn int_raises(s : String) -> Bool {
  try {
    @strconv.parse_int(s) |> ignore
    false
  } catch {
    _ => true
  }
}

///|
test "explicit base with matching prefix and uppercase hex digits" {
  inspect(@strconv.parse_int64("0xFF", base=16), content="255")
  inspect(@strconv.parse_int64("FF", base=16), content="255")
  inspect(@strconv.parse_int64("0XAB", base=16), content="171")
  inspect(@strconv.parse_int64("0o17", base=8), content="15")
  inspect(@strconv.parse_int64("0B101", base=2), content="5")
}

///|
test "leading plus sign is accepted" {
  inspect(@strconv.parse_int64("+123"), content="123")
  inspect(@strconv.parse_int64("+0xff", base=16), content="255")
}

///|
test "negative values with non-decimal bases" {
  inspect(@strconv.parse_int64("-ff", base=16), content="-255")
  inspect(@strconv.parse_int64("-17", base=8), content="-15")
  inspect(@strconv.parse_int64("-101", base=2), content="-5")
}

///|
test "missing digits and trailing underscores are rejected" {
  // prefix with no following digit
  inspect(int64_raises("0x", 16), content="true")
  // trailing underscore
  inspect(int64_raises("1_", 0), content="true")
  // lone sign
  inspect(int64_raises("+", 0), content="true")
}

///|
test "int64 overflow is detected on both signs" {
  // INT64_MAX is 9223372036854775807
  inspect(int64_raises("9223372036854775808", 0), content="true")
  // INT64_MIN is -9223372036854775808
  inspect(int64_raises("-9223372036854775809", 0), content="true")
  // far past the range
  inspect(int64_raises("99999999999999999999999", 0), content="true")
}

///|
test "parse_int narrows to 32 bits and rejects out-of-range values" {
  inspect(@strconv.parse_int("2147483647"), content="2147483647")
  // 3000000000 fits in Int64 but not Int
  inspect(int_raises("3000000000"), content="true")
  inspect(int_raises("-3000000000"), content="true")
}

///|
test "double disguised fast path and overflow fallback" {
  // exponent in (max_fast, max_disguised] with small mantissa
  inspect(@strconv.parse_double("1e23") == 1.0e23, content="true")
  inspect(@strconv.parse_double("2e23") == 2.0e23, content="true")
  // large mantissa * large disguised exponent overflows the checked multiply
  // and falls back to the slow path, still producing a finite value
  inspect(@strconv.parse_double("9007199254740992e37") > 0.0, content="true")
}

///|
test "double underscore handling" {
  inspect(@strconv.parse_double("1_000.5") == 1000.5, content="true")
  inspect(@strconv.parse_double("1_2.3_4") == 12.34, content="true")
  // a non-digit immediately after an underscore is rejected
  inspect(double_raises("1_x"), content="true")
  // a lone sign is not a number
  inspect(double_raises("+"), content="true")
}

///|
test "leading underscore and invalid digit characters are rejected" {
  // underscore before any digit (no base prefix => underscores not yet allowed)
  inspect(int64_raises("_5", 0), content="true")
  // a character that is not a valid digit in the base
  inspect(int64_raises("12@", 0), content="true")
}

///|
test "double slow path: signs, subnormals and buffer-filling fractions" {
  // a leading '+' routed through the slow decimal path
  inspect(
    @strconv.parse_double("+12345678901234567890123456789") > 0.0,
    content="true",
  )
  // >19 significant digits with underscores exercise the 19-digit scanner
  inspect(
    @strconv.parse_double("1_2345_6789_0123_4567_8901") > 0.0,
    content="true",
  )
  // mantissa in range but the product exceeds max_mantissa after the disguised
  // multiply, forcing the slow path
  inspect(@strconv.parse_double("9000000000000000e23") > 0.0, content="true")
  // smallest normal and subnormal doubles drive the right-shift rounding
  inspect(
    @strconv.parse_double("2.2250738585072014e-308") > 0.0,
    content="true",
  )
  inspect(@strconv.parse_double("5e-324") > 0.0, content="true")
  inspect(@strconv.parse_double("4.9e-324") > 0.0, content="true")
  // a fraction with more than the 800-digit buffer overflows it and forces
  // left-shift truncation/trimming during the binary conversion
  let frac = StringBuilder::new()
  frac.write_string("0.")
  for _ in 0..<90 {
    frac.write_string("1234567890")
  }
  frac.write_string("5")
  inspect(@strconv.parse_double(frac.to_string()) > 0.0, content="true")
  // the same digit count at magnitude ~1.5 drives right-shift truncation
  let mid = StringBuilder::new()
  mid.write_string("1.5")
  for _ in 0..<90 {
    mid.write_string("1234567890")
  }
  inspect(@strconv.parse_double(mid.to_string()) > 1.0, content="true")
  // a huge integer part runs through the slow path and overflows the range
  let big = StringBuilder::new()
  for _ in 0..<40 {
    big.write_string("1234567890")
  }
  inspect(double_raises(big.to_string()), content="true")
}

///|
test "double slow path: exponents past the digit-position limits" {
  // a large positive exponent with a long integer part pushes the decimal
  // point past the upper accumulation limit
  let hi = StringBuilder::new()
  for _ in 0..<320 {
    hi.write_string("9")
  }
  hi.write_string("e10")
  inspect(double_raises(hi.to_string()), content="true")
  // a long leading-zero fraction with a negative exponent pushes the decimal
  // point past the lower limit, underflowing to zero
  let lo = StringBuilder::new()
  lo.write_string("0.")
  for _ in 0..<340 {
    lo.write_string("0")
  }
  lo.write_string("1e-10")
  inspect(@strconv.parse_double(lo.to_string()) == 0.0, content="true")
}

///|
test "doubles with many significant digits use the slow path" {
  // more than 19 significant digits forces the big-decimal path
  inspect(
    @strconv.parse_double("123456789012345678901234567890") > 0.0,
    content="true",
  )
  inspect(
    @strconv.parse_double("0.12345678901234567890123456789") > 0.0,
    content="true",
  )
  inspect(
    @strconv.parse_double("0.00000000000000000001234567890123456789") > 0.0,
    content="true",
  )
  inspect(@strconv.parse_double("+1.5") == 1.5, content="true")
  // exact double decimal expansion, needs careful rounding
  let exact = "0.1000000000000000055511151231257827021181583404541015625"
  inspect(@strconv.parse_double(exact) == 0.1, content="true")
  // a value that rounds at the boundary of representable doubles
  inspect(
    @strconv.parse_double("2.2250738585072014e-308") > 0.0,
    content="true",
  )
}
