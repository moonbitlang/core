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

///|
/// Calculates the natural logarithm (base e) of the input.
///
/// Parameters:
///
/// - `input` : The floating-point number for which to calculate the natural
///   logarithm.
///
/// Returns the natural logarithm of the input.
///
/// Examples:
///
/// ```
/// assert_eq!(ln(1.0), 0.0)
/// assert_eq!(ln(0.5), -0.6931471805599453)
/// ```
pub fn ln(input : Double) -> Double {
  input.ln()
}

///|
/// Calculates the base-2 logarithm of the input number.
///
/// Parameters:
///
/// - `input` : The floating-point number for which the logarithm is to be
///   calculated.
///
/// Returns the base-2 logarithm of the input number.
///
/// Example:
///
/// ```
/// assert_eq!(log2(8.0), 3.0)
/// ```
pub fn log2(input : Double) -> Double {
  input.log2()
}

///|
/// Calculates the base-10 logarithm of the input number.
///
/// Parameters:
///
/// - `input` : The floating-point number for which to calculate the logarithm.
///
/// Returns the base-10 logarithm of the input number.
///
/// Example:
///
/// ```
/// assert_eq!(log10(100.0), 2.0)
/// ```
pub fn log10(input : Double) -> Double {
  input.log10()
}
