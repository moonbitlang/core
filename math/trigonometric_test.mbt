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
test "atan function test" {
  inspect!(@math.atan(0.0), content="0")
  inspect!(@math.atan(1.0), content="0.7853981633974483")
  inspect!(@math.atan(-1.0), content="-0.7853981633974483")
}

///|
test "asin function" {
  inspect!(@math.asin(0.0), content="0")
  inspect!(@math.asin(-1.0), content="-1.5707963267948966")
  inspect!(@math.asin(1.0), content="1.5707963267948966")
}

///|
test "atan2 for polar coordinates" {
  // Test atan2(1, 1) which gives the angle 45 degrees = π/4
  inspect!(@math.atan2(1.0, 1.0), content="0.7853981633974483")

  // Test atan2(0, 1) which gives the angle 0 degrees = 0
  inspect!(@math.atan2(0.0, 1.0), content="0")

  // Test atan2(1, 0) which gives the angle 90 degrees = π/2
  inspect!(@math.atan2(1.0, 0.0), content="1.5707963267948966")
}

///|
test "cos function test" {
  inspect!(@math.cos(0.0), content="1")
}

///|
test "tan(x) works correctly" {
  inspect!(@math.tan(0.0), content="0")
}
