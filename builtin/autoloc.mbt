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

pub type SourceLoc

pub fn SourceLoc::to_string(self : SourceLoc) -> String = "%loc_to_string"

pub fn SourceLoc::debug_write(self : SourceLoc, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}

pub type ArgsLoc Array[SourceLoc?]

pub fn ArgsLoc::to_string(self : ArgsLoc) -> String {
  self.0.to_string()
}

pub fn ArgsLoc::to_json(self : ArgsLoc) -> String {
  let buf = Buffer::new(size_hint=10)
  buf.write_char('[')
  for i = 0; i < self.0.length(); i = i + 1 {
    if i != 0 {
      buf.write_string(", ")
    }
    let item = self.0[i]
    match item {
      None => buf.write_string("null")
      Some(loc) => loc.to_string().debug_write(buf)
    }
  }
  buf.write_char(']')
  buf.to_string()
}
