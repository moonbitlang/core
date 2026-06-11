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
pub impl[K : @debug.Debug] @debug.Debug for Set[K] with fn to_repr(self) {
  @debug.Repr::opaque_(
    "Set",
    @debug.Repr::array(self.to_array().map(x => @debug.to_repr(x))),
  )
}

///|
test "Debug for Set" {
  let s : Set[Int] = from_array([1, 2, 3])
  @debug.debug_inspect(s, content="<Set: [1, 2, 3]>")
}
