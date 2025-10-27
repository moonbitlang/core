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
pub impl Shl for UInt16 with shl(self : UInt16, that : Int) -> UInt16 {
  (self.to_int() << that).to_uint16()
}

///|
pub impl Shr for UInt16 with shr(self : UInt16, that : Int) -> UInt16 {
  (self.to_int() >> that).to_uint16()
}

///|
pub impl BitOr for UInt16 with lor(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() | that.to_int()).to_uint16()
}

///|
pub impl BitAnd for UInt16 with land(self : UInt16, that : UInt16) -> UInt16 {
  (self.to_int() & that.to_int()).to_uint16()
}
