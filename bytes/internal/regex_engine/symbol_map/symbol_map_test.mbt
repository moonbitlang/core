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
test "dense table respects non-zero lower bound" {
  let symbol_map = @symbol_map.new()
  symbol_map.split(@shared_types.RecharSet::char(11))
  let (table, repr) = symbol_map.finalize(10, 12)
  assert_eq(repr.length(), 3)
  assert_eq(repr[0], 10)
  assert_eq(repr[1], 11)
  assert_eq(repr[2], 12)
  assert_eq(table.map(10), 0)
  assert_eq(table.map(11), 1)
  assert_eq(table.map(12), 2)
}
