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

test "panic alphabet function coverage" {
  // Test cases to cover all branches in the alphabet function
  @assertion.assert_eq(alphabet(0), "0")!
  @assertion.assert_eq(alphabet(1), "1")!
  @assertion.assert_eq(alphabet(2), "2")!
  @assertion.assert_eq(alphabet(3), "3")!
  @assertion.assert_eq(alphabet(4), "4")!
  @assertion.assert_eq(alphabet(5), "5")!
  @assertion.assert_eq(alphabet(6), "6")!
  @assertion.assert_eq(alphabet(7), "7")!
  @assertion.assert_eq(alphabet(8), "8")!
  @assertion.assert_eq(alphabet(9), "9")!
  @assertion.assert_eq(alphabet(10), "A")!
  @assertion.assert_eq(alphabet(11), "B")!
  @assertion.assert_eq(alphabet(12), "C")!
  @assertion.assert_eq(alphabet(13), "D")!
  @assertion.assert_eq(alphabet(14), "E")!
  @assertion.assert_eq(alphabet(15), "F")!
  // Test for the panic case
  alphabet(16) |> ignore
}
