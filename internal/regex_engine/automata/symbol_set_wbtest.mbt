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
test "symbol set membership and its boundaries" {
  let s = SymbolSet::of(
    @shared_types.RecharSet::char_range(2, 3) + @shared_types.RecharSet::char(7),
  )
  assert_true(s.0.length() == 8)
  let cases = [
    (-1, false),
    (0, false),
    (1, false),
    (2, true),
    (3, true),
    (4, false),
    (7, true),
    (8, false),
    (0x7FFFFFFF, false),
    (-0x80000000, false),
  ]
  for case in cases {
    let (c, expect) = case
    assert_true(s.contains(c) == expect)
  }
}

///|
test "empty sets never become Chr nodes" {
  let ctx = Context()
  assert_true(e_cset(ctx~, @shared_types.RecharSet::empty()).def is Alt([]))
}

///|
test "panic symbol set rejects negative symbols" {
  SymbolSet::of(@shared_types.RecharSet::char_range(-1, 3)) |> ignore
}
