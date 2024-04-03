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

pub fn to_string[A : Debug, B : Debug](self : (A, B)) -> String {
  let buf = Buffer::make(10)
  Debug::debug_write(self, buf)
  buf.to_string()
}

pub fn to_string[A : Debug, B : Debug, C : Debug](self : (A, B, C)) -> String {
  let buf = Buffer::make(10)
  Debug::debug_write(self, buf)
  buf.to_string()
}

pub fn to_string[A : Debug, B : Debug, C : Debug, D : Debug](
  self : (A, B, C, D)
) -> String {
  let buf = Buffer::make(10)
  Debug::debug_write(self, buf)
  buf.to_string()
}

pub fn to_string[A : Debug, B : Debug, C : Debug, D : Debug, E : Debug](
  self : (A, B, C, D, E)
) -> String {
  let buf = Buffer::make(10)
  Debug::debug_write(self, buf)
  buf.to_string()
}
