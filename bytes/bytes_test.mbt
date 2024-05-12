// Copyright 2024 International Digital Economy Academy
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

test "from_array" {
  let b = Bytes::[65, 0, 66, 0, 67, 0]
  inspect(b.to_string(), content="ABC")?
}

test "hash" {
  let b1 = Bytes::[
    65, 0, 66, 0, 67, 0, 68, 0, 69, 0, 70, 0, 71, 0, 72, 0, 73, 0,
  ]
  let b2 = Bytes::[
    65, 0, 66, 0, 67, 0, 68, 0, 69, 0, 70, 0, 71, 0, 72, 0, 74, 0,
  ]
  inspect(b1.hash(), content="273427599")?
  inspect(b2.hash(), content="2013728637")?
  inspect(b1.hash() == b1.hash(), content="true")?
  inspect(b2.hash() == b2.hash(), content="true")?
  inspect(b1.hash() == b2.hash(), content="false")?
}
