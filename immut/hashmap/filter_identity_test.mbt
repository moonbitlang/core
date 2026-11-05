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
test "filter keeping every entry returns the receiver" {
  let empty : @hashmap.HashMap[Int32, Int32] = @hashmap.new()
  inspect(physical_equal(empty.filter((_, _) => true), empty), content="true")
  // a single `Flat` node
  let one = @hashmap.singleton(1, 1)
  inspect(physical_equal(one.filter((_, _) => true), one), content="true")
  // nested `Branch` nodes
  let ints = @hashmap.HashMap(Array::makei(1000, i => (i, i)))
  inspect(physical_equal(ints.filter((_, _) => true), ints), content="true")
  // a collision `Leaf` at maximum depth, under single-child branches
  let leaf = @hashmap.HashMap(Array::makei(5, i => (ZeroHashKey(i), i)))
  inspect(physical_equal(leaf.filter((_, _) => true), leaf), content="true")
  // collision `Leaf`s below `Branch` nodes
  let mid = @hashmap.HashMap(Array::makei(12, i => (MidDepthKey(i), i)))
  inspect(physical_equal(mid.filter((_, _) => true), mid), content="true")
}

///|
test "filter dropping an entry builds a new map" {
  let ints = @hashmap.HashMap(Array::makei(1000, i => (i, i)))
  let no_500 = ints.filter((k, _) => k != 500)
  inspect(physical_equal(no_500, ints), content="false")
  inspect(no_500.length(), content="999")
  inspect(no_500.contains(500), content="false")
  let leaf = @hashmap.HashMap(Array::makei(5, i => (ZeroHashKey(i), i)))
  // drop an entry from anywhere in the collision bucket
  for drop in 0..<5 {
    let filtered = leaf.filter((k, _) => k.0 != drop)
    @test.assert_eq(physical_equal(filtered, leaf), false)
    @test.assert_eq(filtered.length(), 4)
    @test.assert_eq(filtered.contains(ZeroHashKey(drop)), false)
  }
  let mid = @hashmap.HashMap(Array::makei(12, i => (MidDepthKey(i), i)))
  let filtered = mid.filter((k, _) => k.0 != 5)
  inspect(physical_equal(filtered, mid), content="false")
  inspect(filtered.length(), content="11")
  inspect(filtered.contains(MidDepthKey(5)), content="false")
}
