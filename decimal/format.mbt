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
/// Converts a decimal to its canonical non-exponential decimal representation.
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
pub impl Show for Decimal with output(self, logger) {
  logger.write_string(self.to_string())
}
