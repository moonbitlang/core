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
test "repr" {
  inspect(Repr(1), content="1")
  inspect(Repr("x"), content="\"x\"")
  inspect(Repr(true), content="true")
  inspect(Repr(false), content="false")
  inspect(Repr(1.0), content="1")
  inspect(Repr('a'), content="'a'")
  inspect(
    Repr((1, "x", '\n', ['a'])),
    content=(
      #|(1, "x", '\n', ['a'])
    ),
  )
}
