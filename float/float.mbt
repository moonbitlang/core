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
pub let not_a_number : Float = (0x7FC00000).reinterpret_as_float()

///|
pub let infinity : Float = (0x7F800000).reinterpret_as_float()

///|
pub let neg_infinity : Float = (0xFF800000).reinterpret_as_float()

///|
pub let max_value : Float = (0x7F7FFFFF).reinterpret_as_float()

///|
pub let min_value : Float = (0xFF7FFFFF).reinterpret_as_float()

///|
pub let min_positive : Float = (0x00800000).reinterpret_as_float()

///|
pub fn abs(self : Float) -> Float = "%f32.abs"

///|
pub impl Show for Float with output(self, logger) {
  logger.write_string(self.to_double().to_string())
}

///|
pub fn Float::default() -> Float {
  0.0
}

///|
pub impl Hash for Float with hash(self) {
  self.reinterpret_as_int() |> Hash::hash()
}

///|
pub impl Hash for Float with hash_combine(self, hasher) {
  hasher.combine_float(self)
}
