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

pub fn debug_write[X : Debug, Y : Debug](self : (X, Y), buf : Buffer) -> Unit {
  buf.write_char('(')
  self.0.debug_write(buf)
  buf.write_string(", ")
  self.1.debug_write(buf)
  buf.write_char(')')
}

pub fn debug_write[X : Debug, Y : Debug, Z : Debug](
  self : (X, Y, Z),
  buf : Buffer
) -> Unit {
  buf.write_char('(')
  self.0.debug_write(buf)
  buf.write_string(", ")
  self.1.debug_write(buf)
  buf.write_string(", ")
  self.2.debug_write(buf)
  buf.write_char(')')
}

pub fn debug_write[X : Debug, Y : Debug, Z : Debug, W : Debug](
  self : (X, Y, Z, W),
  buf : Buffer
) -> Unit {
  buf.write_char('(')
  self.0.debug_write(buf)
  buf.write_string(", ")
  self.1.debug_write(buf)
  buf.write_string(", ")
  self.2.debug_write(buf)
  buf.write_string(", ")
  self.3.debug_write(buf)
  buf.write_char(')')
}

pub fn debug_write[X1 : Debug, X2 : Debug, X3 : Debug, X4 : Debug, X5 : Debug](
  self : (X1, X2, X3, X4, X5),
  buf : Buffer
) -> Unit {
  buf.write_char('(')
  self.0.debug_write(buf)
  buf.write_string(", ")
  self.1.debug_write(buf)
  buf.write_string(", ")
  self.2.debug_write(buf)
  buf.write_string(", ")
  self.3.debug_write(buf)
  buf.write_string(", ")
  self.4.debug_write(buf)
  buf.write_char(')')
}
