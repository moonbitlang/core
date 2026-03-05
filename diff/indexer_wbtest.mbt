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
test {
  let a = ['a', 'b', 'c', 'd', 'e', 'f', 'a'].map(x => String::make(3, x))
  let b = ['a', 'b', 'x', 'y', 'e', 'f'].map(x => String::make(3, x))
  assert_false(physical_equal(a[0], b[0]))
  assert_false(physical_equal(a[6], b[0]))
  assert_false(physical_equal(a[0], a[6]))
  assert_false(physical_equal(a[1], b[1]))
  assert_false(physical_equal(a[4], b[4]))
  inspect(
    make_indexer(
      a.mut_view(start=0, end=a.length()),
      b.mut_view(start=0, end=b.length()),
    ),
    content="[0, 1, 4, 5, 6]",
  )
  // after call make_indexer, equal items are physically equal
  assert_true(physical_equal(a[0], b[0]))
  assert_true(physical_equal(a[6], b[0]))
  assert_true(physical_equal(a[0], a[6]))
  assert_true(physical_equal(a[1], b[1]))
  assert_true(physical_equal(a[4], b[4]))
}
