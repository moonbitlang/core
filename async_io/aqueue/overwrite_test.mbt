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
async test "discard oldest basic" {
  let q = @async_io.Queue(kind=DiscardOldest(2))
  for i in 1..<=3 {
    q.put(i)
  }
  let result = []
  while q.try_get() is Some(x) {
    result.push(x)
  }
  json_inspect(result, content=[2, 3])
}

///|
async test "discard oldest try_put" {
  let q = @async_io.Queue(kind=DiscardOldest(2))
  inspect(q.try_put(1), content="true")
  inspect(q.try_put(2), content="true")
  inspect(q.try_put(3), content="false")
  // the last put should not have any effect
  let result = []
  while q.try_get() is Some(x) {
    result.push(x)
  }
  json_inspect(result, content=[1, 2])
}

///|
async test "discard latest basic" {
  let q = @async_io.Queue(kind=DiscardLatest(2))
  for i in 1..<=3 {
    q.put(i)
  }
  let result = []
  while q.try_get() is Some(x) {
    result.push(x)
  }
  json_inspect(result, content=[1, 2])
}

///|
async test "discard latest try_put" {
  let q = @async_io.Queue(kind=DiscardLatest(2))
  inspect(q.try_put(1), content="true")
  inspect(q.try_put(2), content="true")
  inspect(q.try_put(3), content="false")
  // the last put should not have any effect
  let result = []
  while q.try_get() is Some(x) {
    result.push(x)
  }
  json_inspect(result, content=[1, 2])
}

///|
async test "discard oldest zero buffered" {
  let q = @async_io.Queue(kind=DiscardOldest(0))
  // all `put` should have no effect
  inspect(q.try_put(1), content="false")
  inspect(q.try_put(2), content="false")
  let result = []
  while q.try_get() is Some(x) {
    result.push(x)
  }
  json_inspect(result, content=[])
}

///|
async test "discard latest zero buffered" {
  let q = @async_io.Queue(kind=DiscardLatest(0))
  // all `put` should have no effect
  inspect(q.try_put(1), content="false")
  inspect(q.try_put(2), content="false")
  let result = []
  while q.try_get() is Some(x) {
    result.push(x)
  }
  json_inspect(result, content=[])
}
