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

/// A big integer represented as an array of Int.
/// 
/// Design explained: 
/// - Why use an array of Int with a len field instead of a Vec[Int]? 
///   - It follows the principle of least dependency in MoonBit's core.
///   - At the moment (04/30/2024), @vec is implemented as a resizable array. 
///     In our case, we always do one-off array allocation for each BigInt.
/// - Why keep a separate len field instead of using limbs.length()?
///   - Since we always do only once array allocation for each BigInt, we
///     often need to estimate the number of limbs needed before allocating.
///     Using len allows us to accommodate leading zeros.
///
/// Invariants:
/// - len > 0
/// - forall i in 0..len-1, 0 <= limbs[i] < radix
/// - limbs[len-1] > 0
/// - forall i in len..limbs.length(), limbs[i] == 0
struct BigInt {
  mut limbs : Array[Int] // Note: do not use limbs.length(), use len instead because of leading zeros
  mut sign : Sign // true for positive, false for negative
  mut len : Int
} 

priv enum Sign {
  Positive
  Negative
} derive(Show, Eq)
