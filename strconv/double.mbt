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

/// Convert a string to a 64 bit floating point number.
pub fn parse_double(str : String) -> Result[Double, String] {
  match special_value(str) {
    Some(v) => return Ok(v)
    _ => ()
  }

  let hpd = Decimal::from_string(str)?
  hpd.to_double()
}

/// Parse the special floating point value.
fn special_value(str : String) -> Option[Double] {
  if str.length() == 0 {
    return None
  }
  let mut s = str
  // check sign
  let mut sign = 1
  if s[0] == '+' || s[0] == '-' {
    if s[0] == '-' {
      sign = -1
      s = substring(s, 1, s.length() - 1)
    }
  }
  match s {
    "Inf" | "inf" | "Infinity" | "infinity" => Some(Double::inf(sign))
    "NaN" | "nan" => Some(Double::nan())
    _ => None
  }
}

test "parse_double" {
  let tests : Array[(String, Result[Double, String])] = [
    ("", Err(syntax_err)),
    ("1", Ok(1.0)),
    ("+1", Ok(1.0)),
    ("1x", Err(syntax_err)),
    ("1.1.", Err(syntax_err)),
    ("1e23", Ok(1.0e23)),
    ("1E23", Ok(1.0e23)),
    ("6.62607015e-34", Ok(6.62607015e-34))
  ]
  for i = 0; i < tests.length(); i = i + 1 {
    let t = tests[i]
    @assertion.assert_eq(parse_double(t.0), t.1)?
  }
}
