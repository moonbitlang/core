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
/// Debug-only object-template writer.
///
/// This type is intentionally minimal: it supports object-template fields, so
/// `@debug.debug_object <? { "name": value }` can log debug values in debug
/// builds while compiling to a no-op in release builds.
#warnings("-struct_never_constructed")
struct DebugObject {
  buffer : StringBuilder
  mut first : Bool
}

///|
/// Starts a debug object template.
///
/// This resets the internal buffer before object fields are written.
pub fn DebugObject::write_object_begin(self : DebugObject) -> Unit {
  self.buffer.reset()
  self.first = true
}

///|
/// Ends a debug object template.
///
/// This flushes the accumulated object fields.
pub fn DebugObject::write_object_end(self : DebugObject) -> Unit {
  println(self.buffer.to_string())
  self.buffer.reset()
  self.first = true
}

///|
/// Writes one debug object-template field.
///
/// The field value must implement `Debug`.
pub fn[T : Debug] DebugObject::write_object_field(
  self : DebugObject,
  name : String,
  value : T,
) -> Unit {
  if self.first {
    self.first = false
  } else {
    self.buffer.write_string(", ")
  }
  self.buffer.write_string(name)
  self.buffer.write_string(" = ")
  self.buffer.write_string(to_string(value))
}
