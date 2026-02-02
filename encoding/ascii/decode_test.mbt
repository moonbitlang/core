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
test "decoding ASCII bytes" {
  let text = b"MoonBit"
  inspect(@ascii.decode(text), content="MoonBit")
}

///|
test "decoding ASCII invalid bytes" {
  let bytes = b"ok\xffmore"
  try {
    let _ = @ascii.decode(bytes)
    panic()
  } catch {
    Malformed(e) =>
      inspect(
        e,
        content=(
          #|b"\xffmore"
        ),
      )
  }
}

///|
test "decode_lossy replaces invalid bytes" {
  let bytes = b"ok\xffmore"
  inspect(@ascii.decode_lossy(bytes), content="ok�more")
}
