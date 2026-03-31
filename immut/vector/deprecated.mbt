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
/// Physically copy the vector.
/// Since it is an immutable data structure,
/// it is rarely the case that you would need this function.
/// 
#deprecated("We don't copy immutable vector")
#coverage.skip
#alias(clone, deprecated)
pub fn[A] Vector::copy(self : Vector[A]) -> Vector[A] {
  self
}
