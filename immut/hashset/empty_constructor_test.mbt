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
fn[A] empty_pair() -> (@hashset.HashSet[A], @hashset.HashSet[A]) {
  (@hashset.HashSet::empty(), @hashset.empty())
}

///|
test "empty constructors do not require trait bounds" {
  let (by_method, by_function) : (
    @hashset.HashSet[Int32],
    @hashset.HashSet[Int32],
  ) = empty_pair()
  debug_inspect(
    (by_method.length(), by_function.is_empty()),
    content="(0, true)",
  )
}

///|
#warnings("-deprecated")
test "legacy new constructors still produce empty collections" {
  let by_method : @hashset.HashSet[Int32] = @hashset.HashSet::new()
  let by_function : @hashset.HashSet[Int32] = @hashset.new()
  debug_inspect(
    (by_method.length(), by_function.is_empty()),
    content="(0, true)",
  )
}
