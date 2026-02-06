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
test "decode" {
  inspect(
    try! @base64.decode("Zg=="),
    content=(
      #|b"f"
    ),
  )
  inspect(
    try! @base64.decode("Zm8="),
    content=(
      #|b"fo"
    ),
  )
  inspect(
    try! @base64.decode("Zm9v"),
    content=(
      #|b"foo"
    ),
  )
  inspect(
    try! @base64.decode("Zg"),
    content=(
      #|b"f"
    ),
  )
  inspect(
    try! @base64.decode("Zm8"),
    content=(
      #|b"fo"
    ),
  )
}

///|
test "decode with whitespace" {
  inspect(
    try! @base64.decode("Z m 9 v", ignore_whitespace=true),
    content=(
      #|b"foo"
    ),
  )
}

///|
test "decode malformed" {
  let f = str => {
    try {
      let _ = @base64.decode(str)
      false
    } catch {
      Malformed(_) => true
    }
  }
  assert_true(f("Zh=="))
  assert_true(f("Zm9="))
  assert_true(f("Zg="))
  assert_true(f("Zg$="))
}

///|
test "decode lossy" {
  inspect(
    @base64.decode_lossy("Zm9v$$$"),
    content=(
      #|b"foo"
    ),
  )
  inspect(
    @base64.decode_lossy("Zm9 v"),
    content=(
      #|b"fo"
    ),
  )
  inspect(
    @base64.decode_lossy("Z m 9 v", ignore_whitespace=true),
    content=(
      #|b"foo"
    ),
  )
}
