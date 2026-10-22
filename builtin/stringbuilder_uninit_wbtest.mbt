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
#cfg(not(target="js"))
test "StringBuilder uninitialized storage exposes only the written prefix" {
  let builder = StringBuilder(size_hint=2)
  builder.write_string("ab")
  builder.write_string("cd")
  let full = builder.to_string()
  inspect(full, content="abcd")

  // The full-capacity conversion may share the backing buffer. Reset must
  // detach before the next write, while a partial conversion must only expose
  // the initialized prefix.
  builder.reset()
  builder.write_char('x')
  inspect(builder.to_string(), content="x")
  builder.reset()
  builder.write_char('🤣')
  inspect(builder.to_string(), content="🤣")
  inspect(full, content="abcd")
}

///|
#cfg(not(target="js"))
test "StringBuilder uninitialized storage preserves returned strings" {
  let builder = StringBuilder(size_hint=3)
  builder.write_string("a😀")
  let first = builder.to_string()
  let again = builder.to_string()
  builder.write_view(first)
  let second = builder.to_string()
  builder.reset()
  builder.reset()
  builder.write_string("x")
  let partial = builder.to_string()
  builder.reset()
  builder.write_string("abcdefg")
  inspect(first, content="a😀")
  inspect(again, content="a😀")
  inspect(second, content="a😀a😀")
  inspect(partial, content="x")
  inspect(builder.to_string(), content="abcdefg")
}
