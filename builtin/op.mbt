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
#coverage.skip
pub fn[T : Compare] op_lt(self_ : T, other : T) -> Bool {
  self_.compare(other).is_neg()
}

///|
#coverage.skip
pub fn[T : Compare] op_gt(self_ : T, other : T) -> Bool {
  self_.compare(other).is_pos()
}

///|
#coverage.skip
pub fn[T : Compare] op_le(self_ : T, other : T) -> Bool {
  self_.compare(other).is_non_pos()
}

///|
#coverage.skip
pub fn[T : Compare] op_ge(self_ : T, other : T) -> Bool {
  self_.compare(other).is_non_neg()
}

///|
#coverage.skip
pub fn[T : Eq] op_notequal(x : T, y : T) -> Bool {
  not(x == y)
}
