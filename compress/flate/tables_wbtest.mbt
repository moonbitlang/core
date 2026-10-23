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
test "distance symbols agree with the linear mapping for every legal distance" {
  for distance in 1..<=WINDOW_SIZE {
    let expected = for symbol = 0 {
      guard symbol + 1 < MAX_NUM_DIST && dist_base[symbol + 1] <= distance else {
        break symbol
      }
      continue symbol + 1
    }
    @test.assert_eq(dist_index(distance), expected)
  }
}
