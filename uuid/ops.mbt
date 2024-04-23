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

pub fn op_equal(self : UUID, other : UUID) -> Bool {
  self.hi == other.hi && self.lo == other.lo
}

pub fn compare(self : UUID, other : UUID) -> Int {
  match self.hi.compare(other.hi) {
    0 => self.lo.compare(other.lo)
    x => x
  }
}

pub fn hash(self : UUID) -> Int {
  self.lo.hash().lxor(self.hi.hash())
}

test "ops" {
  let hex = "72212911-64d1-c441-e87d-de89b955ea34"
  let u1 = from_hex(hex)?
  let u1x = from_hex(hex)?
  let u2 = from_hex("8e325b13-2bf1-d7f6-d2b0-c85a371c1878")?
  inspect(u1 == u1x, content="true")?
  inspect(u1.compare(u2), content="1")?
  inspect(u2.compare(u1), content="-1")?
  inspect(u1.compare(u1x), content="0")?
  inspect(u1.hash() == u1x.hash(), content="true")?
}
