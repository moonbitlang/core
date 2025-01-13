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

test "String::escape" {
  inspect!(
    "abc,def".escape(),
    content=
      #|"abc,def"
    ,
  )
  inspect!(
    "\n\t\\".escape(),
    content=
      #|"\n\t\\"
    ,
  )
  inspect!(
    "\"'".escape(),
    content=
      #|"\"'"
    ,
  )
  inspect!(
    "\x00\x01\x20\x21".escape(),
    content=
      #|"\x00\x01 !"
    ,
  )
}

test "substring" {
  assert_eq!("abc".substring(), "abc")
  assert_eq!("abc".substring(start=1), "bc")
  assert_eq!("abc".substring(end=2), "ab")
  assert_eq!("abc".substring(start=1, end=2), "b")
}

test "panic rev_get1" {
  let str = "Hello🤣🤣🤣"
  let _ = str.rev_get(-1)

}

test "panic rev_get2" {
  let str = "Hello🤣🤣🤣"
  let _ = str.rev_get(8)

}

test "panic codepoint_at1" {
  let str = "Hello🤣🤣🤣"
  let _ = str.codepoint_at(8)

}

test "panic codepoint_at2" {
  let str = "Hello🤣🤣🤣"
  let _ = str.codepoint_at(-1)

}
