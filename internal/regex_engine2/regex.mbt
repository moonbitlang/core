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
priv enum TaggedPattern {
  Chr(RecharSet)
  Seq(Array[TaggedPattern])
  Alt(Array[TaggedPattern])
  Rep(Quantifier, TaggedPattern)
  Cap(Int, TaggedPattern)
  Assert(Assertion)
}

///|
priv enum TaggedNode {
  Chr(RecharSet, Int)
  Split(Array[Int])
  Tag(Int, Int)
  Assert(Assertion, Int)
  Accept
}

///|
priv struct TaggedThread {
  pc : Int
  // -1 is unset; other values name registers, never input offsets.
  tags : ReadOnlyArray[Int]
} derive(Eq, Hash)

///|
priv struct TaggedKey {
  prev : Category
  threads : ReadOnlyArray[TaggedThread]
} derive(Eq, Hash)

///|
struct Regex {
  groups : ReadOnlyArray[String?]
  nodes : ReadOnlyArray[TaggedNode]
  start : Int
  symbols : @symbol_map.Table
  repr : ReadOnlyArray[Rechar]
  categories : ReadOnlyArray[Category]
  starts : Array[(Category, Int)]
  cache : @hashmap.HashMap[TaggedKey, Int]
  states : Array[TaggedKey]
  // State rows include one EOF column. -1 means an uncomputed edge;
  // nonnegative targets are row bases, and -index-2 denotes a terminal state.
  mut next : FixedArray[Int]
  // Each edge writes the cursor to this physical register (zero is a sink).
  mut actions : FixedArray[Int]
  mut registers : FixedArray[Int]
  mut max_registers : Int
  seen : FixedArray[Int]
  mut generation : Int
}

///|
/// Return the capture names for this compiled regex.
pub fn Regex::group_names(self : Regex) -> ReadOnlyArray[String?] {
  self.groups
}
