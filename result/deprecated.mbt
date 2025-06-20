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
#deprecated("use try? instead")
#coverage.skip
pub fn[T, E : Error] wrap0(f~ : () -> T raise E) -> Result[T, E] {
  try f() |> Ok catch {
    e => Err(e)
  }
}

///|
#deprecated("use try? instead")
#coverage.skip
pub fn[T, A, E : Error] wrap1(f~ : (A) -> T raise E, a : A) -> Result[T, E] {
  try f(a) |> Ok catch {
    e => Err(e)
  }
}

///|
#deprecated("use try? instead")
#coverage.skip
pub fn[T, A, B, E : Error] wrap2(
  f~ : (A, B) -> T raise E,
  a : A,
  b : B
) -> Result[T, E] {
  try f(a, b) |> Ok catch {
    e => Err(e)
  }
}
