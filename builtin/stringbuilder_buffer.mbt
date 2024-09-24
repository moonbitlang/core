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

type StringBuilder Buffer

pub fn StringBuilder::new(~size_hint : Int = 0) -> StringBuilder {
  Buffer::new(~size_hint)
}

pub fn StringBuilder::write_string(self : StringBuilder, str : String) -> Unit {
  self._.write_string(str)
}

pub fn StringBuilder::write_char(self : StringBuilder, ch : Char) -> Unit {
  self._.write_char(ch)
}

pub fn StringBuilder::write_sub_string(
  self : StringBuilder,
  str : String,
  start : Int,
  len : Int
) -> Unit {
  self._.write_sub_string(str, start, len)
}

pub fn StringBuilder::to_string(self : StringBuilder) -> String {
  self._.to_string()
}
