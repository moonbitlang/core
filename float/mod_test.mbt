// Copyright 2025 International Digital Economy Academy
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
fn check(x : Float, y : Float) -> Bool {
  (x - y).abs() < 1.0e-6
}

///|
test "mod" {
  inspect(check((7.5 : Float) % 2.3, 0.6), content="true")
  inspect(check((5.75 : Float) % 5.75, 0), content="true")
  inspect(check((-3.6 : Float) % 1.4, -0.8), content="true")
  inspect(check((15.25 : Float) % 4.5, 1.75), content="true")
  inspect(check((0.7 : Float) % 0.2, 0.1), content="true")
  inspect(check((-8.4 : Float) % 3.2, -2), content="true")
}
