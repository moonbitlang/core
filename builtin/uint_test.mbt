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
test "UInt::min, UInt::max and UInt::clamp" {
  assert_eq((1 : UInt).min(2), 1)
  assert_eq((2 : UInt).max(1), 2)
  assert_eq((1 : UInt).clamp(min=0, max=2), 1)
  assert_eq((0 : UInt).clamp(min=1, max=2), 1)
  assert_eq((3 : UInt).clamp(min=1, max=2), 2)
}

///|
test "panic UInt::clamp with invalid range" {
  ignore((1 : UInt).clamp(min=2, max=1))
}
