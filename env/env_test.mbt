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
test {
  let args = @env.args()
  assert_true!(args.length() != 0)
}

///|
test "now returns reasonable timestamp" {
  let timestamp = @env.now()
  assert_true!(timestamp > 0) // 1970-01-01 00:00:00 UTC
  assert_true!(timestamp < 96406502400000UL) // 5025-01-01 00:00:00 UTC
}
