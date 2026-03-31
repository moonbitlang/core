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
using @debug {trait Debug, type Repr}

///|
pub impl[A : Debug] Debug for Vector[A] with to_repr(self) {
  Repr::opaque_(
    "Vector",
    Repr::array(self.to_array().map(x => @debug.to_repr(x))),
  )
}

///|
#deprecated("use `to_repr(a)` instead", skip_current_package=true)
pub fn[A : Debug] Vector::to_repr(self : Vector[A]) -> Repr {
  @debug.to_repr(self)
}

///|
test "Debug for Vector" {
  let xs : Vector[Int] = from_array([1, 2, 3])
  @debug.debug_inspect(xs, content="<Vector: [1, 2, 3]>")
}
