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
/// Renders the decimal in plain (non-scientific) form.
///
/// The output reflects the canonical representation, so trailing zeros
/// after the decimal point are **not** preserved. For example:
///
/// ```text
/// from_string("1.500")    -> "1.5"
/// from_string("12.300")   -> "12.3"
/// from_string("1e3")      -> "1000"
/// from_string("1e-3")     -> "0.001"
/// from_int(0)             -> "0"
/// ```
///
/// Round-tripping through `from_string`/`to_string` always yields the
/// canonical form. If you need a fixed-scale string (e.g. always two
/// fractional digits for currency display), pad the canonical form
/// yourself or build a formatter on top.
pub fn Decimal::to_string(self : Decimal) -> String {
  if self.coefficient.is_zero() {
    return "0"
  }
  let negative = self.coefficient < zero_bigint
  let digits = bigint_abs(self.coefficient).to_string()
  let builder = StringBuilder::new(size_hint=digits.length() + 8)
  if negative {
    builder.write_char('-')
  }
  if self.exponent >= 0 {
    builder.write_string(digits)
    for _ in 0..<self.exponent {
      builder.write_char('0')
    }
  } else {
    let point = digits.length().to_int64() + self.exponent.to_int64()
    if point > 0L {
      let point = exponent_from_int64(point)
      for i in 0..<point {
        builder.write_char(digits.unsafe_get(i).unsafe_to_char())
      }
      builder.write_char('.')
      for i in point..<digits.length() {
        builder.write_char(digits.unsafe_get(i).unsafe_to_char())
      }
    } else {
      builder.write_string("0.")
      for _ in 0..<exponent_from_int64(-point) {
        builder.write_char('0')
      }
      builder.write_string(digits)
    }
  }
  builder.to_string()
}

///|
/// `Show` produces the same canonical form as `to_string`.
pub impl Show for Decimal with output(self, logger) {
  logger.write_string(self.to_string())
}
