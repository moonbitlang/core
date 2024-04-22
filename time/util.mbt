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
  let mut i = 0
  while s[i] == '0' && i < s.length() {
    i += 1
  }
  if i < s.length() {
    substring(s, i, s.length() - i)
  } else {
    substring(s, s.length() - 1, 1)
  }
}

/// FIXME: use substring method of String
fn substring(s : String, start : Int, len : Int) -> String {
  let mut sub_len = len
  if start + len > s.length() {
    sub_len = s.length() - start
  }
  if sub_len < 1 {
    return ""
  }
  let buf = Buffer::make(sub_len)
  buf.write_sub_string(s, start, sub_len)
  buf.to_string()
}

/// FIXME: use split method of String
fn split(s : String, delimiter : Char) -> @vec.Vec[String] {
  let spl : @vec.Vec[String] = @vec.Vec::new()
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

/// FIXME: use checked_add method of Int
fn checked_add_int(x : Int, y : Int) -> Option[Int] {
  let r = x.to_int64() + y.to_int64()
  if r < Int::min_value().to_int64() || r > Int::max_value().to_int64() {
    None
  } else {
    Some(r.to_int())
  }
}

/// FIXME: use checked_mul method of Int
fn checked_mul_int(x : Int, y : Int) -> Option[Int] {
  let r = x.to_int64() * y.to_int64()
  if r < Int::min_value().to_int64() || r > Int::max_value().to_int64() {
    None
  } else {
    Some(r.to_int())
  }
}

/// FIXME: use checked_add method of Int64
fn checked_add_int64(x : Int64, y : Int64) -> Option[Int64] {
  let r = x + y
  // Overflow iff both arguments have the opposite sign of the result
  if x.lxor(r).land(y.lxor(r)) < 0L {
    None
  } else {
    Some(r)
  }
}

test "add_prefix_zero" {
  inspect(add_prefix_zero("1", 0), content="1")?
  inspect(add_prefix_zero("1", 1), content="1")?
  inspect(add_prefix_zero("1", 2), content="01")?
  inspect(add_prefix_zero("1", 3), content="001")?
}

test "remove_prefix_zero" {
  inspect(remove_prefix_zero("01"), content="1")?
  inspect(remove_prefix_zero("09"), content="9")?
  inspect(remove_prefix_zero("000"), content="0")?
}

test "split" {
  inspect(split("2000-01-01", '-'), content="Vec::[2000, 01, 01]")?
  inspect(split("-01-01", '-'), content="Vec::[, 01, 01]")?
  inspect(split("12-31", '-'), content="Vec::[12, 31]")?
  inspect(split("-01", '-'), content="Vec::[, 01]")?
}

test "checked_add_int64" {
  inspect(checked_add_int64(1L, 1L), content="Some(2)")?
  inspect(checked_add_int64(1L, -1L), content="Some(0)")?
  inspect(checked_add_int64(-1L, -1L), content="Some(-2)")?
  inspect(checked_add_int64(1L, Int64::max_value()), content="None")?
  inspect(checked_add_int64(-1L, Int64::min_value()), content="None")?
}

test "checked_add_int" {
  inspect(checked_add_int(1, 1), content="Some(2)")?
  inspect(checked_add_int(1, -1), content="Some(0)")?
  inspect(checked_add_int(-1, -1), content="Some(-2)")?
  inspect(checked_add_int(Int::max_value(), 1), content="None")?
  inspect(checked_add_int(Int::min_value(), -1), content="None")?
}

test "checked_mul_int" {
  inspect(checked_mul_int(2, 3), content="Some(6)")?
  inspect(checked_mul_int(2, -3), content="Some(-6)")?
  inspect(checked_mul_int(-2, -3), content="Some(6)")?
  inspect(checked_mul_int(Int::max_value(), 2), content="None")?
  inspect(checked_mul_int(Int::min_value(), 2), content="None")?
}
