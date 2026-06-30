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
pub impl[K : @debug.Debug, V : @debug.Debug] @debug.Debug for HashMap[K, V] with fn to_repr(
  self,
) {
  @debug.Repr::opaque_(
    "HashMap",
    @debug.Repr::map(
      [
        for k, v in self => (@debug.to_repr(k), @debug.to_repr(v))
      ],
    ),
  )
}

///|
#deprecated("use `to_repr(a)` instead", skip_current_package=true)
pub fn[K : @debug.Debug, V : @debug.Debug] HashMap::to_repr(
  self : HashMap[K, V],
) -> @debug.Repr {
  @debug.to_repr(self)
}

///|
test "Debug for HashMap" {
  let hm : HashMap[Int, String] = HashMap([(2, "b")])
  @debug.debug_inspect(
    hm,
    content=(
      #|<HashMap: { 2: "b" }>
    ),
  )
}
