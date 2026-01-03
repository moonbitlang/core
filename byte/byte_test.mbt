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
test "byte to uint" {
  inspect(b'\xFF'.to_uint(), content="255")
  inspect(b'\x00'.to_uint(), content="0")
}

///|
test "int to byte" {
  inspect((-255).to_byte(), content="b'\\x01'")
  inspect((-0).to_byte(), content="b'\\x00'")
  inspect((-1).to_byte(), content="b'\\xFF'")
  inspect((-256).to_byte(), content="b'\\x00'")
  inspect((-257).to_byte(), content="b'\\xFF'")
  inspect((-65535).to_byte(), content="b'\\x01'")
}

///|
test "grouped test for boundary cases" {
  inspect(b'\x00'.to_uint64(), content="0")
  inspect(b'\xFF'.to_uint64(), content="255")
}

///|
test "grouped test for random cases" {
  inspect(b'\x10'.to_uint64(), content="16")
  inspect(b'\x2A'.to_uint64(), content="42")
  inspect(b'\x7F'.to_uint64(), content="127")
  inspect(b'\x80'.to_uint64(), content="128")
  inspect(b'\xAA'.to_uint64(), content="170")
  inspect(b'\x55'.to_uint64(), content="85")
}

///|
test "additional random cases" {
  inspect(b'\x3C'.to_uint64(), content="60")
  inspect(b'\x64'.to_uint64(), content="100")
  inspect(b'\x99'.to_uint64(), content="153")
}

///|
test "popcnt max_value" {
  let b = b'\xFF'
  inspect(b.popcnt(), content="8")
}

///|
test "popcnt min_value" {
  let b = b'\x00'
  inspect(b.popcnt(), content="0")
}

///|
test "popcnt random cases" {
  inspect(b'\x00'.popcnt(), content="0")
  inspect(b'\x01'.popcnt(), content="1")
  inspect(b'\x03'.popcnt(), content="2")
  inspect(b'\x05'.popcnt(), content="2")
  inspect(b'\x0F'.popcnt(), content="4")
  inspect(b'\x4F'.popcnt(), content="5")
  inspect(b'\x3F'.popcnt(), content="6")
  inspect(b'\x7F'.popcnt(), content="7")
  inspect(b'\x5F'.popcnt(), content="6")
  inspect(b'\xFF'.popcnt(), content="8")
}
