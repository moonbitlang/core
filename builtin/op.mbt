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
#coverage.skip
#deprecated
#doc(hidden)
pub fn[T : Compare] op_lt(self_ : T, other : T) -> Bool {
  Compare::op_lt(self_, other)
}

///|
#coverage.skip
#deprecated
#doc(hidden)
pub fn[T : Compare] op_gt(self_ : T, other : T) -> Bool {
  Compare::op_gt(self_, other)
}

///|
#coverage.skip
#deprecated
#doc(hidden)
pub fn[T : Compare] op_le(self_ : T, other : T) -> Bool {
  Compare::op_le(self_, other)
}

///|
#coverage.skip
#deprecated
#doc(hidden)
pub fn[T : Compare] op_ge(self_ : T, other : T) -> Bool {
  Compare::op_ge(self_, other)
}

///|
#coverage.skip
pub fn[T : Eq] op_notequal(x : T, y : T) -> Bool {
  !(x == y)
}
