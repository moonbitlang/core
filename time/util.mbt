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

fn add_prefix_zero(s : String, len : Int) -> String {
  let buf = Buffer::make(len)
  for i = s.length(); i < len; i = i + 1 {
    buf.write_char('0')
  }
  buf.write_string(s)
  buf.to_string()
}

fn remove_prefix_zero(s : String) -> String {
  if s.length() == 0 {
    return s
  }
  let mut i = 0
  while i < s.length() && s[i] == '0' {
    i += 1
  }
  if i < s.length() {
    s.substring(start=i)
  } else {
    s.substring(start=s.length() - 1)
  }
}

test "add_prefix_zero" {
  inspect(add_prefix_zero("", 2), content="00")?
  inspect(add_prefix_zero("1", 0), content="1")?
  inspect(add_prefix_zero("1", 1), content="1")?
  inspect(add_prefix_zero("1", 2), content="01")?
  inspect(add_prefix_zero("1", 3), content="001")?
}

test "remove_prefix_zero" {
  inspect(remove_prefix_zero(""), content="")?
  inspect(remove_prefix_zero("01"), content="1")?
  inspect(remove_prefix_zero("09"), content="9")?
  inspect(remove_prefix_zero("000"), content="0")?
}

fn add_suffix_zero(s : String, len : Int) -> String {
  let buf = Buffer::make(len)
  buf.write_string(s)
  for i = s.length(); i < len; i = i + 1 {
    buf.write_char('0')
  }
  buf.to_string()
}

fn remove_suffix_zero(s : String) -> String {
  if s.length() == 0 {
    return s
  }
  let mut i = s.length() - 1
  while s[i] == '0' && i > 0 {
    i -= 1
  }
  s.substring(end=i + 1)
}

test "add_suffix_zero" {
  inspect(add_suffix_zero("1", 0), content="1")?
  inspect(add_suffix_zero("1", 1), content="1")?
  inspect(add_suffix_zero("1", 2), content="10")?
  inspect(add_suffix_zero("1", 3), content="100")?
}

test "remove_suffix_zero" {
  inspect(remove_suffix_zero(""), content="")?
  inspect(remove_suffix_zero("1000100"), content="10001")?
  inspect(remove_suffix_zero("000"), content="0")?
}

/// FIXME: use split method of String
fn split(s : String, delimiter : Char) -> @vec.Vec[String] {
  let spl : @vec.Vec[String] = @vec.Vec::new()
  if s.length() == 0 {
    return spl
  }
  let buf = Buffer::make(0)
  for i = 0; i < s.length(); i = i + 1 {
    if s[i] == delimiter {
      spl.push(buf.to_string())
      buf.reset()
    } else {
      buf.write_char(s[i])
    }
  }
  spl.push(buf.to_string())
  spl
}

test "split" {
  inspect(split("2000-01-01", '-'), content="Vec::[2000, 01, 01]")?
  inspect(split("-01-01", '-'), content="Vec::[, 01, 01]")?
  inspect(split("12-31", '-'), content="Vec::[12, 31]")?
  inspect(split("-01", '-'), content="Vec::[, 01]")?
  inspect(split("-", '-'), content="Vec::[, ]")?
  inspect(split("", '-'), content="Vec::[]")?
  inspect(split("0", '-'), content="Vec::[0]")?
}

let int_overflow_err = "Int overflow"

let int64_overflow_err = "Int64 overflow"

/// FIXME: use checked_add method of Int
fn checked_add_int(x : Int, y : Int) -> Result[Int, String] {
  let r = x.to_int64() + y.to_int64()
  if r < Int::min_value().to_int64() || r > Int::max_value().to_int64() {
    Err(int_overflow_err)
  } else {
    Ok(r.to_int())
  }
}

/// FIXME: use checked_mul method of Int
fn checked_mul_int(x : Int, y : Int) -> Result[Int, String] {
  let r = x.to_int64() * y.to_int64()
  if r < Int::min_value().to_int64() || r > Int::max_value().to_int64() {
    Err(int_overflow_err)
  } else {
    Ok(r.to_int())
  }
}

/// FIXME: use checked_add method of Int64
fn checked_add_int64(x : Int64, y : Int64) -> Result[Int64, String] {
  let r = x + y
  // Overflow iff both arguments have the opposite sign of the result
  if x.lxor(r).land(y.lxor(r)) < 0L {
    Err(int64_overflow_err)
  } else {
    Ok(r)
  }
}

/// FIXME: use checked_mul method of Int64
fn checked_mul_int64(x : Int64, y : Int64) -> Result[Int64, String] {
  let r = x * y
  let abs_x = x.abs()
  let abs_y = y.abs()
  if abs_x.lor(abs_y).lsr(31) != 0L {
    // bits that greater than 2^31 might cause overflow
    if y != 0L && r / y != x || x == Int64::min_value() && y == -1L {
      return Err(int64_overflow_err)
    }
  }
  Ok(r)
}

test "checked_add_int" {
  inspect(checked_add_int(1, 1), content="Ok(2)")?
  inspect(checked_add_int(1, -1), content="Ok(0)")?
  inspect(checked_add_int(-1, -1), content="Ok(-2)")?
  inspect(checked_add_int(Int::max_value(), 1), content="Err(Int overflow)")?
  inspect(checked_add_int(Int::min_value(), -1), content="Err(Int overflow)")?
}

test "checked_mul_int" {
  inspect(checked_mul_int(2, 3), content="Ok(6)")?
  inspect(checked_mul_int(2, -3), content="Ok(-6)")?
  inspect(checked_mul_int(-2, -3), content="Ok(6)")?
  inspect(checked_mul_int(Int::max_value(), 2), content="Err(Int overflow)")?
  inspect(checked_mul_int(Int::min_value(), 2), content="Err(Int overflow)")?
}

test "checked_add_int64" {
  inspect(checked_add_int64(1L, 1L), content="Ok(2)")?
  inspect(checked_add_int64(1L, -1L), content="Ok(0)")?
  inspect(checked_add_int64(-1L, -1L), content="Ok(-2)")?
  inspect(
    checked_add_int64(1L, Int64::max_value()),
    content="Err(Int64 overflow)",
  )?
  inspect(
    checked_add_int64(-1L, Int64::min_value()),
    content="Err(Int64 overflow)",
  )?
}

test "checked_mul_int64" {
  inspect(checked_mul_int64(2L, 3L), content="Ok(6)")?
  inspect(checked_mul_int64(2L, -3L), content="Ok(-6)")?
  inspect(checked_mul_int64(-2L, -3L), content="Ok(6)")?
  inspect(
    checked_mul_int64(Int64::max_value(), 2L),
    content="Err(Int64 overflow)",
  )?
  inspect(
    checked_mul_int64(Int64::min_value(), 2L),
    content="Err(Int64 overflow)",
  )?
}

fn floor(x : Double) -> Double {
  if x.is_pos_inf() || x.is_neg_inf() || x.is_nan() {
    return x
  }
  let n = x.to_int64()
  let d = n.to_double()
  if x >= 0.0 || x == d {
    d
  } else {
    d - 1.0
  }
}

fn floor_div_int(x : Int, y : Int) -> Result[Int, String] {
  if y == 0 {
    return Err("division by zero")
  }
  let r = x.to_double() / y.to_double()
  Ok(floor(r).to_int())
}

test "floor_div_int" {
  inspect(floor_div_int(1, 10), content="Ok(0)")?
  inspect(floor_div_int(-1, 10), content="Ok(-1)")?
  inspect(floor_div_int(9, 10), content="Ok(0)")?
  inspect(floor_div_int(-9, 10), content="Ok(-1)")?
  inspect(floor_div_int(0, 10), content="Ok(0)")?
  inspect(floor_div_int(10, 0), content="Err(division by zero)")?
}

fn floor_div_int64(x : Int64, y : Int64) -> Result[Int64, String] {
  if y == 0L {
    return Err("division by zero")
  }
  let r = x.to_double() / y.to_double()
  Ok(floor(r).to_int64())
}

test "floor_div_int64" {
  inspect(floor_div_int64(1L, 10L), content="Ok(0)")?
  inspect(floor_div_int64(-1L, 10L), content="Ok(-1)")?
  inspect(floor_div_int64(9L, 10L), content="Ok(0)")?
  inspect(floor_div_int64(-9L, 10L), content="Ok(-1)")?
  inspect(floor_div_int64(0L, 10L), content="Ok(0)")?
  inspect(floor_div_int64(10L, 0L), content="Err(division by zero)")?
}

fn floor_mod_int(x : Int, y : Int) -> Result[Int, String] {
  Ok(x - floor_div_int(x, y)? * y)
}

test "floor_mod_int" {
  inspect(floor_mod_int(1, 10), content="Ok(1)")?
  inspect(floor_mod_int(-1, 10), content="Ok(9)")?
  inspect(floor_mod_int(11, 10), content="Ok(1)")?
  inspect(floor_mod_int(-11, 10), content="Ok(9)")?
  inspect(floor_mod_int(0, 10), content="Ok(0)")?
  inspect(floor_mod_int(10, 0), content="Err(division by zero)")?
}

fn floor_mod_int64(x : Int64, y : Int64) -> Result[Int64, String] {
  Ok(x - floor_div_int64(x, y)? * y)
}

test "floor_mod_int64" {
  inspect(floor_mod_int64(1L, 10L), content="Ok(1)")?
  inspect(floor_mod_int64(-1L, 10L), content="Ok(9)")?
  inspect(floor_mod_int64(11L, 10L), content="Ok(1)")?
  inspect(floor_mod_int64(-11L, 10L), content="Ok(9)")?
  inspect(floor_mod_int64(0L, 10L), content="Ok(0)")?
  inspect(floor_mod_int64(10L, 0L), content="Err(division by zero)")?
}
