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

///|
fn println_mono(s : String) -> Unit = "%println"

///|
pub fn println[T : Show](input : T) -> Unit {
  println_mono(input.to_string())
}

///|
/// @alert deprecated "Use `println` instead"
pub fn print[T : Show](input : T) -> Unit {
  println(input)
}

///|
pub fn to_string(self : Bool) -> String {
  if self {
    "true"
  } else {
    "false"
  }
}

///|
pub fn to_string(self : Int64) -> String {
  fn abs(n : Int64) -> Int64 {
    if n < 0L {
      0L - n
    } else {
      n
    }
  }

  // The min and max value of i64 are -9223372036854775808 and 9223372036854775807,
  // so max=20 is enough.

  let buf = StringBuilder::new(size_hint=20)
  if self < 0L {
    buf.write_char('-')
  }
  fn write_digits(num) {
    let num2 = num / 10L
    if num2 != 0L {
      write_digits(num2)
    }
    buf.write_char(Char::from_int(abs(num % 10L).to_int() + 48))
  }

  write_digits(self)
  buf.to_string()
}

///|
pub fn to_string(self : Int) -> String {
  fn abs(n : Int) -> Int {
    if n < 0 {
      0 - n
    } else {
      n
    }
  }

  // The min and max value of i32 are -2147483648 and 2147483647,
  // so max=11 is enough.

  let buf = StringBuilder::new()
  if self < 0 {
    buf.write_char('-')
  }
  fn write_digits(num) {
    let num2 = num / 10
    if num2 != 0 {
      write_digits(num2)
    }
    buf.write_char(Char::from_int(abs(num % 10) + 48))
  }

  write_digits(self)
  buf.to_string()
}

///|
pub fn UInt::to_string(self : UInt) -> String {
  let buf = StringBuilder::new()
  fn write_digits(num) {
    let num2 = num / 10U
    if num2 != 0U {
      write_digits(num2)
    }
    buf.write_char(Char::from_int((num % 10U).reinterpret_as_int() + 48))
  }

  write_digits(self)
  buf.to_string()
}

test "UInt::to_string" {
  inspect!(0U, content="0")
  inspect!(17U, content="17")
  inspect!(4294967295U, content="4294967295")
}

///|
pub fn UInt64::to_string(self : UInt64) -> String {
  let buf = StringBuilder::new()
  fn write_digits(num : UInt64) {
    let num2 = num / 10UL
    if num2 != 0UL {
      write_digits(num2)
    }
    buf.write_char(
      Char::from_int((num % 10UL).reinterpret_as_int64().to_int() + 48),
    )
  }

  write_digits(self)
  buf.to_string()
}

///|
/// @coverage.skip 
pub fn op_lt[T : Compare](self_ : T, other : T) -> Bool {
  self_.compare(other).is_neg()
}

///|
/// @coverage.skip 
pub fn op_gt[T : Compare](self_ : T, other : T) -> Bool {
  self_.compare(other).is_pos()
}

///|
/// @coverage.skip 
pub fn op_le[T : Compare](self_ : T, other : T) -> Bool {
  self_.compare(other).is_non_pos()
}

///|
/// @coverage.skip 
pub fn op_ge[T : Compare](self_ : T, other : T) -> Bool {
  self_.compare(other).is_non_neg()
}

///|
/// @coverage.skip 
pub fn op_notequal[T : Eq](x : T, y : T) -> Bool {
  not(x == y)
}

///|
/// A reference to string in host JS.
/// @alert deprecated "Use js-string-builtins api instead"
pub type Js_string

///|
/// Create a JS string from a string in Moonbit by calling intrinsic primitive
pub fn Js_string::new(x : String) -> Js_string {
  x.to_js_string()
}

///|
/// Call FFI to log the JS string
pub fn log(self : Js_string) -> Unit = "js_string" "log"

///|
/// Call FFI to append two JS strings
pub fn op_add(self : Js_string, other : Js_string) -> Js_string = "js_string" "append"

///|
fn unsafe_make_string(length : Int, value : Char) -> String = "$moonbit.unsafe_make_string"

///|
/// Create new string of `length`, where each character is `value`
///
/// ```
/// println(String::make(5,'S')) // Output: "SSSSS"
/// ```
pub fn String::make(length : Int, value : Char) -> String {
  if length < 0 {
    abort("invalid length")
  } else {
    unsafe_make_string(length, value)
  }
}

///|
pub type! InspectError String

///|
pub fn inspect(
  obj : Show,
  ~content : String = "",
  ~loc : SourceLoc = _,
  ~args_loc : ArgsLoc = _
) -> Unit!InspectError {
  let actual = obj.to_string()
  if actual != content {
    let loc = loc.to_string().escape()
    let args_loc = args_loc.to_json().escape()
    let expect = content.escape()
    let actual = obj.to_string().escape()
    raise InspectError(
      "@EXPECT_FAILED {\"loc\": \{loc}, \"args_loc\": \{args_loc}, \"expect\": \{expect}, \"actual\": \{actual}}",
    )
  }
}

///|
// Used by test driver
pub type! SnapshotError String
