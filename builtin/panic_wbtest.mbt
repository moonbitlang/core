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
  inspect!(alphabet(0), content="0")
  inspect!(alphabet(1), content="1")
  inspect!(alphabet(2), content="2")
  inspect!(alphabet(3), content="3")
  inspect!(alphabet(4), content="4")
  inspect!(alphabet(5), content="5")
  inspect!(alphabet(6), content="6")
  inspect!(alphabet(7), content="7")
  inspect!(alphabet(8), content="8")
  inspect!(alphabet(9), content="9")
  inspect!(alphabet(10), content="A")
  inspect!(alphabet(11), content="B")
  inspect!(alphabet(12), content="C")
  inspect!(alphabet(13), content="D")
  inspect!(alphabet(14), content="E")
  inspect!(alphabet(15), content="F")
  // Test for the panic case
  alphabet(16) |> ignore
}

test "panic unwrap" {
  (None : Unit?).unwrap()
}
