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
test "range_fits rejects overflowing ranges" {
  // `offset + len` wraps to a negative number for these, which an additive
  // bounds check would accept.
  inspect(range_fits(2147483647, 1, 4), content="false")
  inspect(range_fits(1, 2147483647, 4), content="false")
  inspect(range_fits(2147483647, 2147483647, 4), content="false")
  inspect(range_fits(-1, 1, 4), content="false")
  inspect(range_fits(5, 0, 4), content="false")
  inspect(range_fits(2, 3, 4), content="false")
  inspect(range_fits(0, 5, 4), content="false")
  inspect(range_fits(0, 4, 4), content="true")
  inspect(range_fits(4, 0, 4), content="true")
  inspect(range_fits(1, 2, 4), content="true")
  inspect(range_fits(0, 0, 0), content="true")
}
