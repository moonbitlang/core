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
  guard let Some(offset) = str.index_at(3)
  inspect!(offset, content="StringIndex(3)")
  guard let Some(offset) = str.index_at(5)
  inspect!(offset, content="StringIndex(5)")
  let offset = str.index_at(6)
  inspect!(offset, content="None")
}

test "index_at with surrogate pairs" {
  let str = "🤣🤣🤣"
  guard let Some(offset) = str.index_at(1)
  inspect!(offset, content="StringIndex(2)")
  guard let Some(offset) = str.index_at(2)
  inspect!(offset, content="StringIndex(4)")
  guard let Some(offset) = str.index_at(3)
  inspect!(offset, content="StringIndex(6)")
  let offset = str.index_at(4)
  inspect!(offset, content="None")
}

test "stringview basic" {
  let str = "Hello🤣🤣🤣"
  let start = 1
  let end = 6
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
  let start = 1
  let end = 7
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
  let start = 1
  let end = 6
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
  let view = str[1:6]
  inspect!(view[0], content="'e'")
  inspect!(view[4], content="'🤣'")
}

test "stringview rev_get" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  inspect!(view.rev_get(0), content="'🤣'")
  inspect!(view.rev_get(4), content="'e'")
}

test "stringview length" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  inspect!(view.length(), content="5")
}

test "stingview length_eq" {
  let str = "hello"
  let view = str[1:4]
  inspect!(view.length_eq(0), content="false")
  inspect!(view.length_eq(1), content="false")
  inspect!(view.length_eq(2), content="false")
  inspect!(view.length_eq(3), content="true")
  inspect!(view.length_eq(4), content="false")
  inspect!(view.length_eq(5), content="false")
}

test "stingview length_ge" {
  let str = "hello"
  let view = str[1:4]
  inspect!(view.length_ge(0), content="true")
  inspect!(view.length_ge(1), content="true")
  inspect!(view.length_ge(2), content="true")
  inspect!(view.length_ge(3), content="true")
  inspect!(view.length_ge(4), content="false")
  inspect!(view.length_ge(5), content="false")
}

test "stringview empty" {
  let str = "hello"
  let view = str[0:0]
  inspect!(view.length(), content="0")
}

test "panic out of bounds1" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  let _ = view[5]

}

test "panic out of bounds2" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  let _ = view[6:]

}

test "panic out of bounds3" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  let _ = view[:6]

}

test "panic out of bounds4" {
  let str = "hello"
  let view = str[0:0]
  let _ = view[0]

}

test "index_at_rev" {
  let str = "🤣🤣🤣"
  guard let Some(offset) = str.index_at_rev(0)
  inspect!(offset, content="StringIndex(6)")
  guard let Some(offset) = str.index_at_rev(1)
  inspect!(offset, content="StringIndex(4)")
  guard let Some(offset) = str.index_at_rev(2)
  inspect!(offset, content="StringIndex(2)")
  guard let Some(offset) = str.index_at_rev(3)
  inspect!(offset, content="StringIndex(0)")
  let offset = str.index_at_rev(4)
  inspect!(offset, content="None")
  guard let Some(offset) = str.index_at_rev(1)
  guard let Some(offset) = str.index_at_rev(1, end=offset)
  inspect!(offset, content="StringIndex(2)")
}

test "stringview negative index" {
  let str = "Hello🤣🤣🤣"
  let str_view = str[:]
  let view = str_view[-1:]
  inspect!(
    view,
    content=
      #|"🤣"
    ,
  )
  let view = str_view[-2:]
  inspect!(
    view,
    content=
      #|"🤣🤣"
    ,
  )
  let view = str_view[-3:]
  inspect!(
    view,
    content=
      #|"🤣🤣🤣"
    ,
  )
  let view = str_view[-4:]
  inspect!(
    view,
    content=
      #|"o🤣🤣🤣"
    ,
  )
  let view = str_view[:-1]
  inspect!(
    view,
    content=
      #|"Hello🤣🤣"
    ,
  )
  let view = str_view[:-2]
  inspect!(
    view,
    content=
      #|"Hello🤣"
    ,
  )
  let view = str_view[:-3]
  inspect!(
    view,
    content=
      #|"Hello"
    ,
  )
  let view = str_view[:-4]
  inspect!(
    view,
    content=
      #|"Hell"
    ,
  )
  let view = str_view[-2:-1]
  inspect!(
    view,
    content=
      #|"🤣"
    ,
  )
  let view = str_view[-3:-1]
  inspect!(
    view,
    content=
      #|"🤣🤣"
    ,
  )
  let view = str_view[-4:-1]
  inspect!(
    view,
    content=
      #|"o🤣🤣"
    ,
  )
  let view = str_view[-4:-2]
  inspect!(
    view,
    content=
      #|"o🤣"
    ,
  )
  let view = str_view[-4:-4]
  inspect!(
    view,
    content=
      #|""
    ,
  )
  let view = str_view[-3:-3]
  inspect!(
    view,
    content=
      #|""
    ,
  )
}

test "panic negative index 1" {
  // index_at_rev fails
  let str = "hello"
  let str_view = str[:]
  let _ = str_view[-6:]

}

test "panic negative index 2" {
  // index_at_rev fails
  let str = "hello"
  let str_view = str[:]
  let _ = str_view[:-6]

}

test "panic negative index 3" {
  // index_at_rev returns an index not in bounds of the view
  let str = "hello"
  let str_view = str[1:4]
  let _ = str_view[-4:]

}

test "panic negative index 4" {
  // index_at_rev returns an index not in bounds of the view
  let str = "hello"
  let str_view = str[1:4]
  let _ = str_view[:-4]

}

test "panic negative index 5" {
  // index_at_rev returns an index not in bounds of the view
  let str = "hello"
  let str_view = str[1:4]
  let _ = str_view[4:]

}

test "panic negative index 6" {
  // index_at_rev returns an index not in bounds of the view
  let str = "hello"
  let str_view = str[1:4]
  let _ = str_view[:4]

}

test "panic negative index 7" {
  // start > end
  let str = "hello"
  let str_view = str[1:4]
  let _ = str_view[-1:-2]

}

test "panic negative index 8" {
  // start > end
  let str = "hello"
  let str_view = str[1:4]
  let _ = str_view[-1:1]

}

test "panic negative index 9" {
  // start > end
  let str = "hello"
  let str_view = str[1:4]
  let _ = str_view[2:-2]

}

test "panic rev_get" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  let _ = view.rev_get(5)

}

test "panic rev_get2" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  let _ = view.rev_get(-1)

}

test "stringview iter" {
  let str = "hello🤣🤣🤣"
  let view = str[1:6]
  let iter = view.iter()
  inspect!(iter.count(), content="5")
  inspect!(iter, content="['e', 'l', 'l', 'o', '🤣']")
}
