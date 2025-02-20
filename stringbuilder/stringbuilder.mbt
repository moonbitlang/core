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
pub typealias T = StringBuilder

///|
pub fn is_empty(b : StringBuilder) -> Bool {
  b.is_empty()
}

///|
pub fn new(size_hint~ : Int = 0) -> StringBuilder {
  StringBuilder::new(size_hint~)
}

///|
pub fn reset(b : StringBuilder) -> Unit {
  b.reset()
}

///|
pub fn to_string(b : StringBuilder) -> String {
  b.to_string()
}

///|
pub fn write_char(b : StringBuilder, c : Char) -> Unit {
  b.write_char(c)
}

///|
pub fn write_object[T : Show](b : StringBuilder, obj : T) -> Unit {
  b.write_object(obj)
}

///|
pub fn write_string(b : StringBuilder, s : String) -> Unit {
  b.write_string(s)
}

///|
pub fn write_substring(
  b : StringBuilder,
  s : String,
  start : Int,
  len : Int
) -> Unit {
  b.write_substring(s, start, len)
}
