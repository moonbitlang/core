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

/// High Precision Decimal structure for "Simple Decimal Conversion" algorithm.
/// Developed by Ken. Thompson, Russ Cox, Robert Griesemer, Nigel Tao.
/// 
/// reference:
/// - <https://nigeltao.github.io/blog/2020/parse-number-f64-simple.html>
/// - <https://nigeltao.github.io/blog/2020/eisel-lemire.html>
struct Decimal {
  digits : Bytes
  mut digits_num : Int
  mut decimal_point : Int
  mut negative : Bool
  mut truncated : Bool
}

/// Maximum shift that we can do in one pass without overflow.
/// We have to be able to accommodate 9 << max_shift.
let max_shift = 59

/// Decimal power of ten to binary power of two.
/// The Ith entry (starting at I = 0) is the largest power of 2 less than (10 ** I)
let powtab = [
  1, 3, 6, 9, 13, 16, 19, 23, 26, 29, 33, 36, 39, 43, 46, 49, 53, 56, 59,
]

/// Create a zero decimal.
pub fn Decimal::new() -> Decimal {
  {
    digits: Bytes::make(800, b'\x00'),
    digits_num: 0,
    decimal_point: 0,
    negative: false,
    truncated: false,
  }
}

/// Create a decimal with an Int64 value.
pub fn Decimal::from_int64(v : Int64) -> Decimal {
  let d = Decimal::new()
  d.assign(v)
  d
}

/// Create a decimal from number string.
pub fn Decimal::parse_decimal(str : String) -> Result[Decimal, String] {
  let d = Decimal::new()
  if str.length() <= 0 {
    return Err(syntax_err)
  }
  let mut i = 0
  // read digits part
  let mut has_dp = false
  let mut has_digits = false
  while i < str.length() {
    match str[i] {
      '-' => if i != 0 { return Err(syntax_err) } else { d.negative = true }
      '+' => if i != 0 { return Err(syntax_err) }
      '_' => () // skip underscores
      '.' => {
        // decimal point
        if has_dp {
          return Err(syntax_err)
        }
        has_dp = true
        d.decimal_point = d.digits_num
      }
      '0' | '1' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' => {
        // digits
        has_digits = true
        if str[i] == '0' && d.digits_num == 0 {
          // ignore leading zeros
          d.decimal_point -= 1
          i += 1
          continue
        }
        if d.digits_num < d.digits.length() {
          d.digits[d.digits_num] = (str[i].to_int() - '0'.to_int()).to_byte()
          d.digits_num += 1
        } else if str[i] != '0' {
          d.truncated = true
        }
      }
      _ => break
    }
    i += 1
  }
  if not(has_digits) {
    return Err(syntax_err)
  }
  if not(has_dp) {
    d.decimal_point = d.digits_num
  }
  // read exponent part
  if i < str.length() && (str[i] == 'e' || str[i] == 'E') {
    i += 1
    if i >= str.length() {
      return Err(syntax_err)
    }
    let mut exp_sign = 1
    if str[i] == '+' {
      i += 1
    } else if str[i] == '-' {
      i += 1
      exp_sign = -1
    }
    if i >= str.length() || str[i] < '0' || str[i] > '9' {
      return Err(syntax_err)
    }
    let mut exp = 0
    while i < str.length() && ('0' <= str[i] && str[i] <= '9' || str[i] == '_') {
      if str[i] == '_' {
        i += 1
        continue
      }
      exp = exp * 10 + (str[i].to_int() - '0'.to_int())
      i += 1
    }
    d.decimal_point += exp_sign * exp
  }
  // finish
  d.trim()
  if i != str.length() {
    Err(syntax_err)
  } else {
    Ok(d)
  }
}

/// Convert the decimal to Double.
pub fn to_double(self : Decimal) -> Result[Double, String] {
  let mut exponent = 0
  let mut mantissa = 0L
  // check the underflow and overflow
  // Double: 1.79769e+308 (10^308) - 2.22507e-308 (10^-308)
  if self.digits_num == 0 || self.decimal_point < -330 {
    // zero
    mantissa = 0L
    exponent = double_info.bias
    let bits = assemble_bits(mantissa, exponent, self.negative)
    return Ok(bits.reinterpret_as_double())
  }
  if self.decimal_point > 310 {
    // overflow
    return Err(range_err)
  }

  // scale by powers of 2 until in range [0.5 .. 1]
  // right shift
  while self.decimal_point > 0 {
    let mut n = 0
    if self.decimal_point >= powtab.length() {
      n = 60
    } else {
      n = powtab[self.decimal_point]
    }
    self.shift(-n)
    exponent += n
  }
  // left shift
  while self.decimal_point < 0 || self.decimal_point == 0 && self.digits[0].to_int() < 5 {
    let mut n = 0
    if -self.decimal_point >= powtab.length() {
      n = 60
    } else {
      n = powtab[-self.decimal_point]
    }
    self.shift(n)
    exponent -= n
  }

  // normalized floating point range is [1, 2), current [0.5, 1)
  // should decrease the exponent by 1
  exponent -= 1

  // minimum representable exponent is bias + 1
  // if the exponent is smaller, move it up and shift decimal accordingly
  if exponent < double_info.bias + 1 {
    let n = double_info.bias + 1 - exponent
    self.shift(-n)
    exponent += n
  }
  if exponent - double_info.bias >= (1).lsl(double_info.exponent_bits) - 1 {
    // overflow
    return Err(range_err)
  }

  // multiply by (2 ** precision) and round to get mantissa
  // extract mantissa_bits + 1 bits
  self.shift(double_info.mantissa_bits + 1)
  mantissa = self.rounded_integer()

  // rounding might have added a bit, shift down.
  if mantissa == 2L.lsl(double_info.mantissa_bits) {
    mantissa = mantissa.lsr(1)
    exponent += 1
    if exponent - double_info.bias >= (1).lsl(double_info.exponent_bits) - 1 {
      // overflow
      return Err(range_err)
    }
  }

  // denormalized
  if mantissa.land(1L.lsl(double_info.mantissa_bits)) == 0L {
    exponent = double_info.bias
  }

  // combining the 52 mantissa bits with the 11 exponent bits and 1 sign bit
  let bits = assemble_bits(mantissa, exponent, self.negative)
  Ok(bits.reinterpret_as_double())
}

/// Binary shift left (s > 0) or right (s < 0).
/// The shift count must not larger than the max_shift to avoid overflow.
pub fn shift(self : Decimal, s : Int) -> Unit {
  if self.digits_num == 0 {
    return
  }
  let mut s = s
  if s > 0 {
    while s > max_shift {
      self.left_shift(max_shift)
      s -= max_shift
    }
    self.left_shift(s)
  }
  if s < 0 {
    while s < -max_shift {
      self.right_shift(max_shift)
      s += max_shift
    }
    self.right_shift(-s)
  }
}

fn assemble_bits(mantissa : Int64, exponent : Int, negative : Bool) -> Int64 {
  let biased_exp = exponent - double_info.bias
  // set the mantissa bits
  let mut bits = mantissa.land(1L.lsl(double_info.mantissa_bits) - 1L)
  // set the exponent bits
  let exp_bits = biased_exp.land((1).lsl(double_info.exponent_bits) - 1).to_int64()
  bits = bits.lor(exp_bits.lsl(double_info.mantissa_bits))
  // set the sign bit
  if negative {
    bits = bits.lor(
      1L.lsl(double_info.mantissa_bits).lsl(double_info.exponent_bits),
    )
  }
  bits
}

/// Extract a rounded 64bit integer
fn rounded_integer(self : Decimal) -> Int64 {
  if self.decimal_point > 20 {
    return 0xFFFFFFFFFFFFFFFFL
  }
  let mut n = 0L
  let mut i = 0
  while i < self.decimal_point && i < self.digits_num {
    n = n * 10L + self.digits[i].to_int64()
    i += 1
  }
  while i < self.decimal_point {
    n *= 10L
    i += 1
  }
  if self.should_round_up(self.decimal_point) {
    n += 1L
  }
  n
}

/// Check if truncate at d digits should round up.
/// Typically, when rounding a decimal fraction to an integer, 7.3 rounds down to 7 and 7.6 rounds up to 8. 
/// Rounding numbers like 7.5, half-way between two integers, will round to even.
fn should_round_up(self : Decimal, d : Int) -> Bool {
  if d < 0 || d >= self.digits_num {
    return false
  }
  if self.digits[d].to_int() == 5 && d + 1 == self.digits_num {
    // half-way between two integers
    // if truncated, the real value is higher than stored value, round up.
    if self.truncated {
      return true
    }
    // round to even
    return d > 0 && self.digits[d - 1].to_int() % 2 != 0
  }
  // normal case
  self.digits[d].to_int() >= 5
}

/// Assign a Int64 value to decimal.
fn assign(self : Decimal, v : Int64) -> Unit {
  let buf = Bytes::make(24, b'\x00')

  // write value to buf
  let mut n = 0
  let mut v = v
  while v > 0L {
    let v1 = v / 10L
    buf[n] = (v - 10L * v1).to_byte()
    n += 1
    v = v1
  }

  // reverse the buf
  self.digits_num = 0
  for i = n - 1; i >= 0; i = i - 1 {
    self.digits[self.digits_num] = buf[i]
    self.digits_num += 1
  }
  self.decimal_point = self.digits_num
  self.trim()
}

/// Binary shift right by s bits.
fn right_shift(self : Decimal, s : Int) -> Unit {
  let mut read_index = 0
  let mut write_index = 0

  // read enough leading digits to start a shift
  let mut acc = 0L
  while acc.lsr(s) == 0L {
    if read_index >= self.digits_num {
      while acc.lsr(s) == 0L {
        acc *= 10L
        read_index += 1
      }
      break
    }
    let d = self.digits[read_index]
    acc = acc * 10L + d.to_int64()
    read_index += 1
  }
  self.decimal_point -= read_index - 1

  // read a digit and output a shifted digit
  let mask = 1L.lsl(s) - 1L
  while read_index < self.digits_num {
    // output (acc >> s)
    let out = acc.lsr(s).to_int()
    self.digits[write_index] = out.to_byte()
    write_index += 1
    // contract
    acc = acc.land(mask)
    // expand
    let d = self.digits[read_index]
    acc = acc * 10L + d.to_int64()
    read_index += 1
  }

  // output extra digits
  while acc > 0L {
    let out = acc.lsr(s).to_int()
    if write_index < self.digits.length() {
      self.digits[write_index] = out.to_byte()
      write_index += 1
    } else if out > 0 {
      self.truncated = true
    }
    acc = acc.land(mask)
    acc = acc * 10L
  }

  // update and trim
  self.digits_num = write_index
  self.trim()
}

/// Cheat sheet for left shift: table indexed by shift count giving
/// number of new digits that will be introduced by that shift.
/// left_shift_cheats[s] = (new digits num, (5 ** s))
let left_shift_cheats = [
  (0, ""),
  (1, "5"), // * 2
  (1, "25"), // * 4
  (1, "125"), // * 8
  (2, "625"), // * 16
  (2, "3125"), // * 32
  (2, "15625"), // * 64
  (3, "78125"), // * 128
  (3, "390625"), // * 256
  (3, "1953125"), // * 512
  (4, "9765625"), // * 1024
  (4, "48828125"), // * 2048
  (4, "244140625"), // * 4096
  (4, "1220703125"), // * 8192
  (5, "6103515625"), // * 16384
  (5, "30517578125"), // * 32768
  (5, "152587890625"), // * 65536
  (6, "762939453125"), // * 131072
  (6, "3814697265625"), // * 262144
  (6, "19073486328125"), // * 524288
  (7, "95367431640625"), // * 1048576
  (7, "476837158203125"), // * 2097152
  (7, "2384185791015625"), // * 4194304
  (7, "11920928955078125"), // * 8388608
  (8, "59604644775390625"), // * 16777216
  (8, "298023223876953125"), // * 33554432
  (8, "1490116119384765625"), // * 67108864
  (9, "7450580596923828125"), // * 134217728
  (9, "37252902984619140625"), // * 268435456
  (9, "186264514923095703125"), // * 536870912
  (10, "931322574615478515625"), // * 1073741824
  (10, "4656612873077392578125"), // * 2147483648
  (10, "23283064365386962890625"), // * 4294967296
  (10, "116415321826934814453125"), // * 8589934592
  (11, "582076609134674072265625"), // * 17179869184
  (11, "2910383045673370361328125"), // * 34359738368
  (11, "14551915228366851806640625"), // * 68719476736
  (12, "72759576141834259033203125"), // * 137438953472
  (12, "363797880709171295166015625"), // * 274877906944
  (12, "1818989403545856475830078125"), // * 549755813888
  (13, "9094947017729282379150390625"), // * 1099511627776
  (13, "45474735088646411895751953125"), // * 2199023255552
  (13, "227373675443232059478759765625"), // * 4398046511104
  (13, "1136868377216160297393798828125"), // * 8796093022208
  (14, "5684341886080801486968994140625"), // * 17592186044416
  (14, "28421709430404007434844970703125"), // * 35184372088832
  (14, "142108547152020037174224853515625"), // * 70368744177664
  (15, "710542735760100185871124267578125"), // * 140737488355328
  (15, "3552713678800500929355621337890625"), // * 281474976710656
  (15, "17763568394002504646778106689453125"), // * 562949953421312
  (16, "88817841970012523233890533447265625"), // * 1125899906842624
  (16, "444089209850062616169452667236328125"), // * 2251799813685248
  (16, "2220446049250313080847263336181640625"), // * 4503599627370496
  (16, "11102230246251565404236316680908203125"), // * 9007199254740992
  (17, "55511151231257827021181583404541015625"), // * 18014398509481984
  (17, "277555756156289135105907917022705078125"), // * 36028797018963968
  (17, "1387778780781445675529539585113525390625"), // * 72057594037927936
  (18, "6938893903907228377647697925567626953125"), // * 144115188075855872
  (18, "34694469519536141888238489627838134765625"), // * 288230376151711744
  (18, "173472347597680709441192448139190673828125"), // * 576460752303423488
  (19, "867361737988403547205962240695953369140625"), // * 1152921504606846976
]

/// Lookup the cheat sheet to find the new digits num.
fn new_digits(self : Decimal, s : Int) -> Int {
  let new_digits = left_shift_cheats[s].0
  let cheat_num = left_shift_cheats[s].1
  // check if the leading digits lexicographically less than cheats num.
  let mut less = false
  for i = 0; i < cheat_num.length(); i = i + 1 {
    if i >= self.digits_num {
      less = true
      break
    }
    let d = cheat_num[i].to_int() - '0'.to_int()
    if self.digits[i].to_int() != d {
      less = self.digits[i].to_int() < d
      break
    }
  }
  if less {
    new_digits - 1
  } else {
    new_digits
  }
}

/// Binary shift left by s bits.
fn left_shift(self : Decimal, s : Int) -> Unit {
  let new_digits = self.new_digits(s)
  // from right to left
  let mut read_index = self.digits_num
  let mut write_index = self.digits_num + new_digits

  // read a digit and output a shifted digit
  let mut acc = 0L
  read_index -= 1
  while read_index >= 0 {
    let d = self.digits[read_index].to_int64()
    acc += d.lsl(s)
    let quo = acc / 10L
    let rem = (acc - quo * 10L).to_int()
    write_index -= 1
    if write_index < self.digits.length() {
      self.digits[write_index] = rem.to_byte()
    } else if rem != 0 {
      self.truncated = true
    }
    acc = quo
    read_index -= 1
  }

  // output extra digits
  while acc > 0L {
    let quo = acc / 10L
    let rem = (acc - 10L * quo).to_int()
    write_index -= 1
    if write_index < self.digits.length() {
      self.digits[write_index] = rem.to_byte()
    } else if rem != 0 {
      self.truncated = true
    }
    acc = quo
  }

  // update and trim
  self.digits_num += new_digits
  if self.digits_num > self.digits.length() {
    self.digits_num = self.digits.length()
  }
  self.decimal_point += new_digits
  self.trim()
}

/// Trim trailing zeros.
fn trim(self : Decimal) -> Unit {
  while self.digits_num > 0 && self.digits[self.digits_num - 1].to_int() == 0 {
    self.digits_num -= 1
  }
  if self.digits_num == 0 {
    self.decimal_point = 0
  }
}

fn to_string(self : Decimal) -> String {
  if self.digits_num == 0 {
    return "0"
  }
  let mut n = self.digits_num
  if self.decimal_point > 0 {
    n += self.decimal_point
  }
  if self.decimal_point < 0 {
    n += -self.decimal_point
  }
  let buf = Buffer::make(n)
  if self.decimal_point <= 0 {
    // zeros filling between the decimal point and the digits
    buf.write_string("0.")
    for i = 0; i < -self.decimal_point; i = i + 1 {
      buf.write_char('0')
    }
    for i = 0; i < self.digits_num; i = i + 1 {
      buf.write_string(self.digits[i].to_int().to_string())
    }
  } else if self.decimal_point < self.digits_num {
    // decimal point in the middle of digits
    for i = 0; i < self.digits_num; i = i + 1 {
      if i == self.decimal_point {
        buf.write_char('.')
      }
      buf.write_string(self.digits[i].to_int().to_string())
    }
  } else {
    // zeros filling between the digits and the decimal point
    for i = 0; i < self.digits_num; i = i + 1 {
      buf.write_string(self.digits[i].to_int().to_string())
    }
    for i = 0; i < self.decimal_point - self.digits_num; i = i + 1 {
      buf.write_char('0')
    }
  }
  buf.to_string()
}

test "new" {
  let hpd = Decimal::from_int64(1L)
  @assertion.assert_eq(hpd.digits.length(), 800)?
  @assertion.assert_eq(hpd.digits_num, 1)?
  @assertion.assert_eq(hpd.decimal_point, 1)?
  @assertion.assert_eq(hpd.negative, false)?
  @assertion.assert_eq(hpd.truncated, false)?
}

test "from_int64" {
  let hpd = Decimal::from_int64(123456789L)
  @assertion.assert_eq(hpd.to_string(), "123456789")?
}

test "parse_decimal" {
  let s = "0.0000000000000000000000000000007888609052210118054117285652827862296732064351090230047702789306640625"
  let hpd = Decimal::parse_decimal(s)?
  @assertion.assert_eq(hpd.to_string(), s)?
  let hpd = Decimal::parse_decimal("1.0e-10")?
  @assertion.assert_eq(hpd.to_string(), "0.0000000001")?
}

test "to_string" {
  let hpd = Decimal::from_int64(123456789L)
  hpd.decimal_point = 1
  @assertion.assert_eq(hpd.to_string(), "1.23456789")?
  hpd.decimal_point = 0
  @assertion.assert_eq(hpd.to_string(), "0.123456789")?
  hpd.decimal_point = -1
  @assertion.assert_eq(hpd.to_string(), "0.0123456789")?
  hpd.decimal_point = 10
  @assertion.assert_eq(hpd.to_string(), "1234567890")?
}

test "shift" {
  let tests : Array[_] = [
    (0L, 100, "0"),
    (0L, -100, "0"),
    (1L, 100, "1267650600228229401496703205376"),
    (
      1L, -100, "0.0000000000000000000000000000007888609052210118054117285652827862296732064351090230047702789306640625",
    ),
    (12345678L, 8, "3160493568"),
    (12345678L, -8, "48225.3046875"),
    (195312L, 9, "99999744"),
    (1953125L, 9, "1000000000"),
  ]
  for i = 0; i < tests.length(); i = i + 1 {
    let t = tests[i]
    let d = Decimal::from_int64(t.0)
    d.shift(t.1)
    @assertion.assert_eq(d.to_string(), t.2)?
  }
}
