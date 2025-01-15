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

// TODO:
// 
// - Format functions.
// - Support hexadecimal floating point number.
// - Implements Eisel-Lemire algorithm to speed up floating point parsing.

///|
pub(open) trait FromStr {
  from_string(String) -> Self!StrConvError
}

///|
pub impl FromStr for Bool with from_string(str) { parse_bool!(str) }

///|
pub impl FromStr for Int with from_string(str) { parse_int!(str) }

///|
pub impl FromStr for Int64 with from_string(str) { parse_int64!(str) }

///|
pub impl FromStr for UInt with from_string(str) { parse_uint!(str) }

///|
pub impl FromStr for UInt64 with from_string(str) { parse_uint64!(str) }

///|
pub impl FromStr for Double with from_string(str) { parse_double!(str) }

///|
pub fn parse[A : FromStr](str : String) -> A!StrConvError {
  A::from_string!(str)
}

test "parse" {
  let b : Bool = try {
    parse!("true")
  } catch {
    _ => panic()
  }
  assert_eq!(b, true)
  let i : Int = try {
    parse!("12345")
  } catch {
    _ => panic()
  }
  assert_eq!(i, 12345)
  let i64 : Int64 = try {
    parse!("9223372036854775807")
  } catch {
    _ => panic()
  }
  assert_eq!(i64, 9223372036854775807L)
  let ui : UInt = try {
    parse!("4294967295")
  } catch {
    _ => panic()
  }
  assert_eq!(ui, 4294967295)
  let ui64 : UInt64 = try {
    parse!("18446744073709551615")
  } catch {
    _ => panic()
  }
  assert_eq!(ui64, 18446744073709551615UL)
  let d : Double = try {
    parse!("1234.56789")
  } catch {
    _ => panic()
  }
  assert_eq!(d, 1234.56789)
}
