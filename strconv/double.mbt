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

priv struct FloatInfo {
  mantissa_bits : Int
  exponent_bits : Int
  bias : Int
}

let double_info : FloatInfo = {
  mantissa_bits: 52,
  exponent_bits: 11,
  bias: -1023,
}


struct AdjustedMantissa {
  mantissa : UInt64
  mut power2 : Int
} derive(Eq)

/// TODO: It is only for `double`. For `f32` it is 23, but we have `f32` yet. 
let mantissa_explicit_bits = 52;

/// TODO: It is only for `double`. For `f32` it is 31, but we have `f32` yet.
let sign_index = 63;  

pub fn parse_double(str : String) -> Result[Double, String] {
  if str.length() == 0 {
    return Err(syntax_err)
  }

  // validate its a number
  let (num, rest) = match parse_number(str) {
    Some(r) => r
    None =>
      match parse_inf_nan(str) {
        Some((num, rest)) =>
          if rest > 0 {
            return Err(syntax_err)
          } else {
            return Ok(num)
          }
        None => return Err(syntax_err)
      }
  }
  if rest > 0 {
    return Err(syntax_err)
  }
  match try_fast_path(num) {
    Some(value) => return Ok(value)
    None => ()
  }
  let mut am = compute_float(num.exponent, num.mantissa)
  if num.many_digits && am != compute_float(num.exponent, num.mantissa + new_UInt64_Int64(1L)) {
    am.power2 = -1
  }
  if am.power2 < 0 {
    am = parse_long_mantissa(str)
  }

  let mut word = am.mantissa
  word = word.lor(new_UInt64_Int64(am.power2.to_int64().lsl(mantissa_explicit_bits)))
  if num.negative {
      word = word.lor(new_UInt64_Int64(1L.lsl(sign_index)));
  }
  Ok(word.reinterpret_as_double())
}
fn try_fast_path(num : Number) -> Option[Double] {
  None
}

fn compute_float(q : Int64, w : UInt64) -> AdjustedMantissa {
  { mantissa: new_UInt64_Int64(0L), power2: 0 }
}

fn parse_long_mantissa(s: String) -> AdjustedMantissa {
  { mantissa: new_UInt64_Int64(0L), power2: 0 }
}

