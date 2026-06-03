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
struct LexscanBuf {
  mut buffer : ReadOnlyArray[Char]
  mut base : Int
  mut curr : Int
  mut backup_buffer : Array[Char]
  mut backup_base : Int
  mut eof_reached : Bool
  refill_fn : async () -> ReadOnlyArray[Char]
}

///|
pub fn LexscanBuf::from_function(
  refill_fn : async () -> ReadOnlyArray[Char],
) -> LexscanBuf {
  {
    buffer: [],
    base: 0,
    curr: 0,
    backup_buffer: [],
    backup_base: -1,
    eof_reached: false,
    refill_fn,
  }
}

///|
pub fn LexscanBuf::get_char(self : LexscanBuf, index : Int) -> Int {
  if index < self.base || index >= self.base + self.buffer.length() {
    if self.eof_reached {
      return -1
    }
    panic()
  }
  self.buffer[index - self.base].to_int()
}

///|
pub fn LexscanBuf::get_stringview(
  self : LexscanBuf,
  start : Int,
  end : Int,
) -> StringView {
  let chars = self.backup_buffer[start - self.backup_base:end - self.backup_base]
  String::from_array(chars)
}

///|
pub fn LexscanBuf::eof_reached(self : LexscanBuf) -> Bool {
  self.eof_reached
}

///|
pub fn LexscanBuf::buffer_end(self : LexscanBuf) -> Int {
  self.base + self.buffer.length()
}

///|
pub async fn LexscanBuf::refill(self : LexscanBuf) -> Unit {
  let buffer = (self.refill_fn)()
  if self.backup_base >= 0 {
    self.backup_buffer.append(buffer)
  }
  self.base += self.buffer.length()
  self.buffer = buffer
  if buffer is [] {
    self.eof_reached = true
  }
}

///|
pub fn LexscanBuf::get_cursor(self : LexscanBuf) -> Int {
  self.curr
}

///|
pub fn LexscanBuf::advance(self : LexscanBuf, amount : Int) -> Unit {
  self.curr += amount
}

///|
pub fn LexscanBuf::set_backup(self : LexscanBuf) -> Unit {
  self.backup_base = self.base
  self.backup_buffer = self.buffer[:].to_owned()
}

///|
pub fn LexscanBuf::clear_backup(self : LexscanBuf) -> Unit {
  self.backup_base = -1
  self.backup_buffer = []
}
