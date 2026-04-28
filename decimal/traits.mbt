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
/// are all respected. Compares by aligning to a common exponent and
/// comparing coefficients.
pub impl Compare for Decimal with compare(self, other) {
  let (a, b, _) = align_coefficients(self, other)
  a.compare(b)
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
