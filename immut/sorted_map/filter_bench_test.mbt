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
test "bench filter keep all n=100000" (it : @bench.T) {
  let map = @sorted_map.SortedMap(Array::makei(100000, i => (i, i)))
  it.bench(() => it.keep(map.filter((_, _) => true)))
}

///|
test "bench filter keep 99% n=100000" (it : @bench.T) {
  let map = @sorted_map.SortedMap(Array::makei(100000, i => (i, i)))
  it.bench(() => it.keep(map.filter((key, _) => key % 100 != 0)))
}

///|
test "bench filter keep half n=100000" (it : @bench.T) {
  let map = @sorted_map.SortedMap(Array::makei(100000, i => (i, i)))
  it.bench(() => it.keep(map.filter((key, _) => key % 2 == 0)))
}

///|
test "bench filter drop all n=100000" (it : @bench.T) {
  let map = @sorted_map.SortedMap(Array::makei(100000, i => (i, i)))
  it.bench(() => it.keep(map.filter((_, _) => false)))
}

///|
test "bench filter keep all n=31" (it : @bench.T) {
  let map = @sorted_map.SortedMap(Array::makei(31, i => (i, i)))
  it.bench(() => it.keep(map.filter((_, _) => true)))
}

///|
test "bench filter drop all n=31" (it : @bench.T) {
  let map = @sorted_map.SortedMap(Array::makei(31, i => (i, i)))
  it.bench(() => it.keep(map.filter((_, _) => false)))
}
