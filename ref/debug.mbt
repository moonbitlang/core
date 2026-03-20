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
pub impl[T : Debug] Debug for Ref[T] with to_repr(self) {
  Repr::opaque_("Ref", @debug.to_repr(self.val))
}

///|
#deprecated("use `to_repr(a)` instead", skip_current_package=true)
pub fn[T : Debug] Ref::to_repr(self : Ref[T]) -> Repr {
  @debug.to_repr(self)
}

///|
test "Debug for Ref" {
  let r : Ref[Int] = new(1)
  @debug.debug_inspect(r, content="<Ref: 1>")
}
