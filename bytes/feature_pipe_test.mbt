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
test "feature pipe" {
  let b : Bytes = "hello"
  let mut u = Bytes::new(b.length())
  let v = b
    |> tap(x => u = x)
    |> _.length() // test _.length()
    |> _.to_int64() // test _.to_int()
  inspect(v, content="5")
  inspect(
    b,
    content=(
      #|b"hello"
    ),
  )
  inspect(
    u,
    content=(
      #|b"hello"
    ),
  )
}
