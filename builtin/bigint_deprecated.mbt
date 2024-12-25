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
/// @alert deprecated "Use infix bitwise operator `>>` instead"
/// @coverage.skip
pub fn asr(self : BigInt, n : Int) -> BigInt {
  self >> n
}

///|
/// Left shift a bigint
/// The sign of the result is the same as the sign of the input.
/// Only the absolute value is shifted.
/// 
/// @alert deprecated "Use infix bitwise operator `<<` instead"
/// @coverage.skip
pub fn shl(self : BigInt, n : Int) -> BigInt {
  self << n
}

///|
/// Left shift a bigint
/// The sign of the result is the same as the sign of the input.
/// Only the absolute value is shifted.
/// 
/// @alert deprecated "Use infix bitwise operator `<<` instead"
/// @coverage.skip
pub fn lsl(self : BigInt, n : Int) -> BigInt {
  self << n
}

///|
/// Right shift a bigint
/// The sign of the result is the same as the sign of the input.
/// Only the absolute value is shifted.
/// 
/// @alert deprecated "Use infix bitwise operator `>>` instead"
/// @coverage.skip
pub fn shr(self : BigInt, n : Int) -> BigInt {
  self >> n
}
