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
test "WASIp1 string table follows pointers, including empty and shared entries" {
  let buffer = b"a\x00b\x00\x00"
  let base = wasi_buffer_address(buffer)
  inspect(
    decode_wasi_strings([base + 2, base, base + 4, base + 2], buffer).join("|"),
    content="b|a||b",
  )
  inspect(decode_wasi_strings([], b"").length(), content="0")
}

///|
test "WASIp1 strings preserve Unicode, BOM and the old sentinel" {
  let buffer = @utf8.encode(
    "\u{FEFF}中文😀\u0000ffi_end_of_/string_array\u0000",
  )
  let base = wasi_buffer_address(buffer)
  let sentinel_offset = @utf8.encode("\u{FEFF}中文😀").length() + 1
  let strings = decode_wasi_strings([base, base + sentinel_offset], buffer)
  inspect(strings[0] == "\u{FEFF}中文😀", content="true")
  inspect(strings[1], content="ffi_end_of_/string_array")
}

///|
test "WASIp1 strings replace malformed UTF-8" {
  let buffer = b"\xFFa\x00"
  inspect(
    decode_wasi_strings([wasi_buffer_address(buffer)], buffer)[0],
    content="�a",
  )
}

///|
test "panic WASIp1 string pointer before buffer" {
  let buffer = b"\x00"
  ignore(decode_wasi_strings([wasi_buffer_address(buffer) - 1], buffer))
}

///|
test "panic WASIp1 string pointer past buffer" {
  let buffer = b"\x00"
  ignore(decode_wasi_strings([wasi_buffer_address(buffer) + 1], buffer))
}

///|
test "panic WASIp1 string without terminator" {
  let buffer = b"a"
  ignore(decode_wasi_strings([wasi_buffer_address(buffer)], buffer))
}
