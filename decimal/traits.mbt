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
pub impl Eq for Decimal with equal(self, other) {
  self.coefficient == other.coefficient && self.exponent == other.exponent
}

///|
pub impl Compare for Decimal with compare(self, other) {
  let (a, b, _) = align_coefficients(self, other)
  a.compare(b)
}

///|
pub impl Hash for Decimal with hash_combine(self, hasher) {
  hasher.combine(self.coefficient)
  hasher.combine(self.exponent)
}

///|
pub impl ToJson for Decimal with to_json(self : Decimal) -> Json {
  Json::string(self.to_string())
}

///|
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
