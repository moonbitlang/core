// Copyright 2025 International Digital Economy Academy
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
struct T[A] {
  node : Node[A]
  size : Int
}

///|
priv enum Node[A] {
  Empty
  Leaf(A)
  Branch(A, left~ : Node[A], right~ : Node[A])
}

///|
pub impl[A : ToJson + Compare] ToJson for T[A] with to_json(self : T[A]) {
  // note here iter requires Compare 
  // This requires some investigation 
  // CR: this syntax feels less intuitive
  let output : Array[Json] = []
  for item in self {
    output.push(item.to_json())
  }
  Json::array(output)
}
