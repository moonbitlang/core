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
test "V128 decode handles a view and scalar tail" {
  let bytes = b"!0123456789ABCDEF?"
  inspect(decode_v128(bytes[1:]), content="0123456789ABCDEF?")
}

///|
test "V128 decode reports the first non-ASCII byte in a block" {
  let bytes = b"0123456789ABC\xffDEF"
  try {
    let _ = decode_v128(bytes)
    panic()
  } catch {
    Malformed(rest) =>
      inspect(
        rest,
        content=(
          #|b"\xffDEF"
        ),
      )
  }
}
