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

test "index_at" {
  let str = "Hello"
  let offset = str.index_at(3)
  inspect!(offset, content="Some(StringIndex(3))")
  let offset = str.index_at(5)
  inspect!(offset, content="None")
}

test "index_at with surrogate pairs" {
  let str = "🤣🤣🤣"
  let offset = str.index_at(1)
  inspect!(offset, content="Some(StringIndex(2))")
  let offset = str.index_at(2)
  inspect!(offset, content="Some(StringIndex(4))")
  let offset = str.index_at(3)
  inspect!(offset, content="None")
}

test "stringview basic" {
  let str = "Hello🤣🤣🤣"
  guard let Some(start) = str.index_at(1)
  guard let Some(end) = str.index_at(6)
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

test "stringview basic2" {
  let str = "He🤣🤣🤣llo"
  guard let Some(start) = str.index_at(1)
  guard let Some(end) = str.index_at(7)
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

test "stringview subview" {
  let str = "Hello🤣🤣🤣"
  guard let Some(start) = str.index_at(1)
  guard let Some(end) = str.index_at(6)
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

test "stringview op_get" {
  let str = "Hello🤣🤣🤣"
  guard let Some(start) = str.index_at(1)
  guard let Some(end) = str.index_at(6)
  let view = str[start:end]
  inspect!(view[0], content="'e'")
  inspect!(view[4], content="'🤣'")
}

test "stringview length" {
  let str = "Hello🤣🤣🤣"
  guard let Some(start) = str.index_at(1)
  guard let Some(end) = str.index_at(6)
  let view = str[start:end]
  inspect!(view.length(), content="5")
}

test "stringview empty" {
  let str = "hello"
  guard let Some(start) = str.index_at(0)
  guard let Some(end) = str.index_at(0)
  let view = str[start:end]
  inspect!(view.length(), content="0")
}

test "panic out of bounds1" {
  let str = "Hello🤣🤣🤣"
  guard let Some(start) = str.index_at(1)
  guard let Some(end) = str.index_at(6)
  let view = str[start:end]
  let _ = view[5]

}

test "panic out of bounds2" {
  let str = "Hello🤣🤣🤣"
  guard let Some(start) = str.index_at(1)
  guard let Some(end) = str.index_at(6)
  let view = str[start:end]
  let _ = view[6:]

}

test "panic out of bounds3" {
  let str = "Hello🤣🤣🤣"
  guard let Some(start) = str.index_at(1)
  guard let Some(end) = str.index_at(6)
  let view = str[start:end]
  let _ = view[:6]

}

test "panic out of bounds4" {
  let str = "hello"
  guard let Some(start) = str.index_at(0)
  guard let Some(end) = str.index_at(0)
  let view = str[start:end]
  let _ = view[0]

}
