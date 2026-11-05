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
test "HashMap::is_empty" {
  let empty : @hashmap.HashMap[Int32, Int32] = @hashmap.new()
  inspect(empty.is_empty(), content="true")
  let one = empty.add(1, 1)
  inspect(one.is_empty(), content="false")
  inspect(one.remove(1).is_empty(), content="true")
  inspect(one.filter((_, _) => false).is_empty(), content="true")
  inspect(@hashmap.HashMap([(1, 1), (2, 2)]).is_empty(), content="false")
}
