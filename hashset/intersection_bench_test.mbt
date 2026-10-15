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
test "bench intersection Int large/small overlap 100000/100" (it : @bench.T) {
  let left = @hashset.HashSet(Array::makei(100000, i => i))
  let right = @hashset.HashSet(Array::makei(100, i => i))
  it.bench(() => it.keep(left.intersection(right)))
}

///|
test "bench intersection Int large/small disjoint 100000/100" (it : @bench.T) {
  let left = @hashset.HashSet(Array::makei(100000, i => i))
  let right = @hashset.HashSet(Array::makei(100, i => 100000 + i))
  it.bench(() => it.keep(left.intersection(right)))
}

///|
test "bench intersection Int small/large overlap 100/100000" (it : @bench.T) {
  let left = @hashset.HashSet(Array::makei(100, i => i))
  let right = @hashset.HashSet(Array::makei(100000, i => i))
  it.bench(() => it.keep(left.intersection(right)))
}

///|
test "bench intersection Int equal tables half overlap 10000/10000" (
  it : @bench.T,
) {
  let left = @hashset.HashSet(Array::makei(10000, i => i))
  let right = @hashset.HashSet(Array::makei(10000, i => 5000 + i))
  it.bench(() => it.keep(left.intersection(right)))
}

///|
test "bench intersection Int small tables half overlap 8/8" (it : @bench.T) {
  let left = @hashset.HashSet(Array::makei(8, i => i))
  let right = @hashset.HashSet(Array::makei(8, i => 4 + i))
  it.bench(() => it.keep(left.intersection(right)))
}

///|
test "bench intersection Int empty right 100000/0" (it : @bench.T) {
  let left = @hashset.HashSet(Array::makei(100000, i => i))
  let right = @hashset.HashSet(([] : Array[Int32]))
  it.bench(() => it.keep(left.intersection(right)))
}

///|
test "bench intersection String large/small overlap 100000/100" (it : @bench.T) {
  let left = @hashset.HashSet(Array::makei(100000, i => "key-\{i}-suffix"))
  let right = @hashset.HashSet(Array::makei(100, i => "key-\{i}-suffix"))
  it.bench(() => it.keep(left.intersection(right)))
}

///|
test "bench intersection sparse left table 100/100" (it : @bench.T) {
  let left = @hashset.HashSet(Array::makei(100000, i => i))
  for i in 100..<100000 {
    left.remove(i)
  }
  let right = @hashset.HashSet(Array::makei(100, i => 50 + i))
  it.bench(() => it.keep(left.intersection(right)))
}
