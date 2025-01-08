// Copyright 2024 International Digital Economy Academy
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

test "offset_by" {
  let str = "Hello"
  let offset = CharOffset::offset_by(str, 3)
  inspect!(offset, content="Some(CharOffset(3))")
  let offset = CharOffset::offset_by(str, 5)
  inspect!(offset, content="None")
}

test "offset_by with surrogate pairs" {
  let str = "🤣🤣🤣"
  let offset = CharOffset::offset_by(str, 1)
  inspect!(offset, content="Some(CharOffset(2))")
  let offset = CharOffset::offset_by(str, 2)
  inspect!(offset, content="Some(CharOffset(4))")
  let offset = CharOffset::offset_by(str, 3)
  inspect!(offset, content="None")
}

test "charsview basic" {
  let str = "Hello🤣🤣🤣"
  guard let Some(start) = CharOffset::offset_by(str, 1)
  guard let Some(end) = CharOffset::offset_by(str, 6)
  inspect!(
    str[start:],
    content=
      #|"ello🤣🤣🤣"
    ,
  )
  inspect!(
    str[:end],
    content=
      #|"Hello🤣"
    ,
  )
  inspect!(
    str[start:end],
    content=
      #|"ello🤣"
    ,
  )
  inspect!(
    str[:],
    content=
      #|"Hello🤣🤣🤣"
    ,
  )
}

test "charsview basic2" {
  let str = "He🤣🤣🤣llo"
  guard let Some(start) = CharOffset::offset_by(str, 1)
  guard let Some(end) = CharOffset::offset_by(str, 7)
  inspect!(
    str[start:],
    content=
      #|"e🤣🤣🤣llo"
    ,
  )
  inspect!(
    str[:end],
    content=
      #|"He🤣🤣🤣ll"
    ,
  )
  inspect!(
    str[start:end],
    content=
      #|"e🤣🤣🤣ll"
    ,
  )
  inspect!(
    str[:],
    content=
      #|"He🤣🤣🤣llo"
    ,
  )
}

test "charsview subview" {
  let str = "Hello🤣🤣🤣"
  guard let Some(start) = CharOffset::offset_by(str, 1)
  guard let Some(end) = CharOffset::offset_by(str, 6)
  let view = str[start:end]
  inspect!(
    view[1:],
    content=
      #|"llo🤣"
    ,
  )
  inspect!(
    view[1:4],
    content=
      #|"llo"
    ,
  )
  inspect!(
    view[:4],
    content=
      #|"ello"
    ,
  )
  inspect!(
    view[:],
    content=
      #|"ello🤣"
    ,
  )
}

test "charsview op_get" {
  let str = "Hello🤣🤣🤣"
  guard let Some(start) = CharOffset::offset_by(str, 1)
  guard let Some(end) = CharOffset::offset_by(str, 6)
  let view = str[start:end]
  inspect!(view[0], content="'e'")
  inspect!(view[4], content="'🤣'")
}
