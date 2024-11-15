// Copyright 2024 International Digital Economy Academy
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
struct H {
  x : Int
  y : Int
} derive(@quickcheck.Arbitrary, Show)

test {
  let state = @splitmix.RandomState::default()
  let size = 10
  let v : H = @quickcheck.gen(state~, size~)
  inspect!(v, content="{x: 0, y: 0}")
  let state = state.split()
  let v : H = @quickcheck.gen(state~, size~)
  inspect!(v, content="{x: -1, y: -2}")
  let state = state.split()
  let v : H = @quickcheck.gen(state~, size~)
  inspect!(v, content="{x: 7, y: 2}")
}
