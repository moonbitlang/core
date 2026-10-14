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
test "forward iterators resume across leaves and stay exhausted" {
  for size in [0, 1, 2, 3, 7, 16, 31, 64, 1024] {
    let entries = Array::makei(size, i => (i * 2, "value/\{i}"))
    let map = @sorted_map.from_array(entries)
    let iter = map.iter()
    let keys = map.keys()
    let values = map.values()
    for entry in entries {
      @test.assert_eq(iter.next(), Some(entry))
      @test.assert_eq(keys.next(), Some(entry.0))
      @test.assert_eq(values.next(), Some(entry.1))
    }
    for _ in 0..<3 {
      @test.assert_eq(iter.next(), None)
      @test.assert_eq(keys.next(), None)
      @test.assert_eq(values.next(), None)
    }
    @test.assert_eq(map.to_array(), entries)
  }
}

///|
test "forward iterators preserve values already pending on their stack" {
  let map = @sorted_map.from_array([(2, "two"), (1, "one"), (3, "three")])
  let iter = map.iter()
  let values = map.values()
  @test.assert_eq(iter.next(), Some((1, "one")))
  @test.assert_eq(values.next(), Some("one"))
  map.set(2, "updated")
  @test.assert_eq(iter.next(), Some((2, "two")))
  @test.assert_eq(values.next(), Some("two"))
  @test.assert_eq(iter.next(), Some((3, "three")))
  @test.assert_eq(values.next(), Some("three"))
}
