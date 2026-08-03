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
/// Two `Decimal` values are equal iff they have the same canonical
/// `(coefficient, exponent)`. Because all public constructors
/// canonicalize, this is also semantic equality: `1.5`, `1.50`, and
/// `1.500e0` are all `==`.
pub impl Eq for Decimal with equal(self, other) {
  self.coefficient == other.coefficient && self.exponent == other.exponent
}

///|
/// Total ordering by numeric value. Sign, magnitude, and fractional part
/// are all respected.
///
/// Two values with the same exponent are compared by coefficient. When
/// exponents differ, a fast magnitude check decides the order without
/// scaling whenever the values' decimal magnitudes are clearly apart;
/// otherwise the smaller-exponent operand's coefficient is multiplied
/// by `10^(exponent_diff)` and the coefficients are compared directly.
///
/// The fast path is what keeps `compare` from aborting on inputs like
/// `dec("1e2147483647").compare(dec("1e-2147483648"))`: the exponent
/// difference there overflows `Int` and would blow up if the function
/// tried to scale before checking magnitudes.
pub impl Compare for Decimal with compare(self, other) {
  // Identical canonical → equal.
  if self.exponent == other.exponent {
    return self.coefficient.compare(other.coefficient)
  }
  // Zero vs zero / zero vs non-zero.
  let self_zero = self.coefficient.is_zero()
  let other_zero = other.coefficient.is_zero()
  if self_zero && other_zero {
    return 0
  }
  if self_zero {
    return -other.coefficient.compare(zero_bigint)
  }
  if other_zero {
    return self.coefficient.compare(zero_bigint)
  }
  // Sign decides when signs differ.
  let self_sign = if self.coefficient < zero_bigint { -1 } else { 1 }
  let other_sign = if other.coefficient < zero_bigint { -1 } else { 1 }
  if self_sign != other_sign {
    return self_sign
  }
  // Both non-zero, same sign. Bracket each value's decimal magnitude
  // (position of the most-significant digit relative to the decimal
  // point) using the BigInt bit length. log10(2) ≈ 0.301, so:
  //   digits_lower(bits) = floor(bits / 4) + 1   (slight underestimate)
  //   digits_upper(bits) = floor(bits / 3) + 1   (slight overestimate)
  // magnitude = digits + exponent.  All math in Int64 to dodge the Int
  // range that triggered the original bug.
  let self_bits = bigint_abs(self.coefficient).bit_length().to_int64()
  let other_bits = bigint_abs(other.coefficient).bit_length().to_int64()
  let self_e = self.exponent.to_int64()
  let other_e = other.exponent.to_int64()
  let self_mag_low = self_bits / 4L + 1L + self_e
  let self_mag_high = self_bits / 3L + 1L + self_e
  let other_mag_low = other_bits / 4L + 1L + other_e
  let other_mag_high = other_bits / 3L + 1L + other_e
  if self_mag_low > other_mag_high {
    return self_sign
  }
  if other_mag_low > self_mag_high {
    return -self_sign
  }
  // Magnitudes overlap: the exponent difference is bounded by the
  // narrower of the two bit-length brackets, so it fits in Int and
  // pow10 is feasible.
  let diff = self_e - other_e
  if diff > 0L {
    let scaled = self.coefficient * pow10(diff.to_int())
    scaled.compare(other.coefficient)
  } else {
    let scaled = other.coefficient * pow10((-diff).to_int())
    self.coefficient.compare(scaled)
  }
}

///|
/// Hash uses the canonical `(coefficient, exponent)`. Equal values hash
/// equal (canonicalization guarantees a unique representation).
pub impl Hash for Decimal with hash_combine(self, hasher) {
  hasher.combine(self.coefficient)
  hasher.combine(self.exponent)
}

///|
/// JSON encoding is the canonical decimal string. Encoding as a string
/// (rather than a JSON number) preserves precision across JSON
/// implementations that represent numbers as IEEE 754 doubles.
pub impl ToJson for Decimal with to_json(self : Decimal) -> Json {
  Json::string(self.to_string())
}

///|
/// JSON decoding accepts a string. Numeric JSON is rejected on purpose:
/// JSON numbers have no defined precision, and silently coercing them
/// would defeat the point of using `Decimal`.
///
/// Raises `JsonDecodeError` if the JSON value is not a string, or if the
/// string is not a valid decimal literal (per `Decimal::from_string`).
pub impl @json.FromJson for Decimal with from_json(json, path) {
  guard json is String(s) else {
    raise @json.JsonDecodeError(
      (path, "Decimal::from_json: expected decimal in string representation"),
    )
  }
  Decimal::from_string(s) catch {
    _ =>
      raise @json.JsonDecodeError(
        (path, "Decimal::from_json: invalid decimal string"),
      )
  }
}
