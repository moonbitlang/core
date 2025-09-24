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
fn Char::to_hex(char : Char) -> String {
  let code = char.to_int()
  match code {
    0..=0xFF => code.to_byte().to_hex()
    _..=0xFFFF => (code >> 8).to_byte().to_hex() + code.to_byte().to_hex()
    _ =>
      (code >> 16).to_byte().to_hex() +
      (code >> 8).to_byte().to_hex() +
      code.to_byte().to_hex()
  }
}

///|
test "Char::to_hex" {
  // Test various characters
  inspect(Char::to_hex('A'), content="41")
  inspect(Char::to_hex('a'), content="61")
  inspect(Char::to_hex('0'), content="30")
  inspect(Char::to_hex('\n'), content="0a")
  inspect(Char::to_hex('\u{0}'), content="00")
  inspect(Char::to_hex('\u{FF}'), content="ff")
  inspect(Char::to_hex('\u{100}'), content="0100")
  inspect(Char::to_hex('\u{1000}'), content="1000")
  inspect(Char::to_hex('😀'), content="01f600")
}
