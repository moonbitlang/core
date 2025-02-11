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
test "index_at" {
  let str = "Hello"
  guard let Some(offset) = str.index_at(3)
  inspect!(offset, content="StringIndex(3)")
  guard let Some(offset) = str.index_at(5)
  inspect!(offset, content="StringIndex(5)")
  let offset = str.index_at(6)
  inspect!(offset, content="None")
}

///|
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
  inspect!(str[1:2], content="🤣")
  inspect!(str[1:3], content="🤣🤣")
  inspect!(str[1:-1], content="🤣")
  inspect!(str[1:-2], content="")
  inspect!(str[:-1], content="🤣🤣")
}

///|
test "stringview basic" {
  let str = "Hello🤣🤣🤣"
  let start = 1
  let end = 6
  inspect!(str[start:], content="ello🤣🤣🤣")
  inspect!(str[:end], content="Hello🤣")
  inspect!(str[start:end], content="ello🤣")
  inspect!(str[:], content="Hello🤣🤣🤣")
}

///|
test "stringview basic2" {
  let str = "He🤣🤣🤣llo"
  let start = 1
  let end = 7
  inspect!(str[start:], content="e🤣🤣🤣llo")
  inspect!(str[:end], content="He🤣🤣🤣ll")
  inspect!(str[start:end], content="e🤣🤣🤣ll")
  inspect!(str[:], content="He🤣🤣🤣llo")
}

///|
test "stringview subview" {
  let str = "Hello🤣🤣🤣"
  let start = 1
  let end = 6
  let view = str[start:end]
  inspect!(view[1:], content="llo🤣")
  inspect!(view[1:4], content="llo")
  inspect!(view[:4], content="ello")
  inspect!(view[:], content="ello🤣")
}

///|
test "stringview op_get" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  inspect!(view[0], content="'e'")
  inspect!(view[4], content="'🤣'")
}

///|
test "stringview rev_get" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  inspect!(view.rev_get(0), content="'🤣'")
  inspect!(view.rev_get(4), content="'e'")
}

///|
test "stringview length" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  inspect!(view.length(), content="5")
}

///|
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

///|
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

///|
test "stringview empty" {
  let str = "hello"
  let view = str[0:0]
  inspect!(view.length(), content="0")
}

///|
test "panic out of bounds1" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  let _ = view[5]

}

///|
test "panic out of bounds2" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  let _ = view[6:]

}

///|
test "panic out of bounds3" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  let _ = view[:6]

}

///|
test "panic out of bounds4" {
  let str = "hello"
  let view = str[0:0]
  let _ = view[0]

}

///|
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

///|
test "stringview negative index" {
  let str = "Hello🤣🤣🤣"
  let str_view = str[:]
  let view = str_view[-1:]
  inspect!(view, content="🤣")
  let view = str_view[-2:]
  inspect!(view, content="🤣🤣")
  let view = str_view[-3:]
  inspect!(view, content="🤣🤣🤣")
  let view = str_view[-4:]
  inspect!(view, content="o🤣🤣🤣")
  let view = str_view[:-1]
  inspect!(view, content="Hello🤣🤣")
  let view = str_view[:-2]
  inspect!(view, content="Hello🤣")
  let view = str_view[:-3]
  inspect!(view, content="Hello")
  let view = str_view[:-4]
  inspect!(view, content="Hell")
  let view = str_view[-2:-1]
  inspect!(view, content="🤣")
  let view = str_view[-3:-1]
  inspect!(view, content="🤣🤣")
  let view = str_view[-4:-1]
  inspect!(view, content="o🤣🤣")
  let view = str_view[-4:-2]
  inspect!(view, content="o🤣")
  let view = str_view[-4:-4]
  inspect!(view, content="")
  let view = str_view[-3:-3]
  inspect!(view, content="")
}

///|
test "panic negative index 1" {
  // index_at_rev fails
  let str = "hello"
  let str_view = str[:]
  let _ = str_view[-6:]

}

///|
test "panic negative index 2" {
  // index_at_rev fails
  let str = "hello"
  let str_view = str[:]
  let _ = str_view[:-6]

}

///|
test "panic negative index 3" {
  // index_at_rev returns an index not in bounds of the view
  let str = "hello"
  let str_view = str[1:4]
  let _ = str_view[-4:]

}

///|
test "panic negative index 4" {
  // index_at_rev returns an index not in bounds of the view
  let str = "hello"
  let str_view = str[1:4]
  let _ = str_view[:-4]

}

///|
test "panic negative index 5" {
  // index_at_rev returns an index not in bounds of the view
  let str = "hello"
  let str_view = str[1:4]
  let _ = str_view[4:]

}

///|
test "panic negative index 6" {
  // index_at_rev returns an index not in bounds of the view
  let str = "hello"
  let str_view = str[1:4]
  let _ = str_view[:4]

}

///|
test "panic negative index 7" {
  // start > end
  let str = "hello"
  let str_view = str[1:4]
  let _ = str_view[-1:-2]

}

///|
test "panic negative index 8" {
  // start > end
  let str = "hello"
  let str_view = str[1:4]
  let _ = str_view[-1:1]

}

///|
test "panic negative index 9" {
  // start > end
  let str = "hello"
  let str_view = str[1:4]
  let _ = str_view[2:-2]

}

///|
test "panic rev_get" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  let _ = view.rev_get(5)

}

///|
test "panic rev_get2" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  let _ = view.rev_get(-1)

}

///|
test "stringview iter" {
  let str = "hello🤣🤣🤣"
  let view = str[1:6]
  let iter = view.iter()
  inspect!(iter.count(), content="5")
  inspect!(iter, content="['e', 'l', 'l', 'o', '🤣']")
}

///|
test "stringview negative index" {
  let str = "hello🤣😭😂"
  inspect!(str[-2:-1], content="😭")
  inspect!(str[-3:-1], content="🤣😭")
  inspect!(str[-4:-1], content="o🤣😭")
  inspect!(str[-4:], content="o🤣😭😂")
  inspect!(str[:-2], content="hello🤣")
  inspect!(str[-2:-2], content="")
  inspect!(str[-0:0], content="")
  inspect!(str[-8:], content="hello🤣😭😂")
}

///|
test "panic stringview negative index1" {
  let str = "hello🤣😭😂"
  let _ = str[-9:]

}

///|
test "panic stringview negative index2" {
  let str = "hello🤣😭😂"
  let _ = str[:-9]

}

///|
test "panic stringview negative index3" {
  let str = "hello🤣😭😂"
  let _ = str[-1:-2]

}

///|
test "to_string" {
  let s = "Hello World"
  let view = s[0:5]
  let ss = "\{view} Moonbit"
  inspect!(ss, content="Hello Moonbit")
}

///|
test "length_eq test with surrogate pair" {
  // "🤣" is encoded as a surrogate pair
  let str = "🤣"
  let view = str[:]
  assert_true!(view.length_eq(1))
}

///|
test "length_ge with high surrogate" {
  let str = "🐰" // This emoji is represented using a surrogate pair
  let view = str[0:]
  assert_eq!(view.length_ge(1), true)
  assert_eq!(view.length_ge(2), false)
}

///|
test "panic op_as_view with invalid positive start index" {
  let str = "Hello🤣🤣🤣"
  let view = str[0:6]
  ignore(view[100:])
}

///|
test "panic on accessing negative index" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  ignore(view[-1]) // This should panic due to invalid index
}

///|
test "panic on invalid start index" {
  let str = "Hello"
  ignore(str[10:])
}

///|
test "panic on invalid end index" {
  let str = "Hello"
  ignore(str[0:10])
}

///|
test "panic_view_op_as_view_invalid_end_index" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:7] // "ello🤣"
  ignore(view[0:10]) // This should panic due to invalid end index
}

///|
test "panic length_eq should panic on invalid surrogate pair" {
  // Create a string with an invalid surrogate pair:
  // 0xD800 is a leading surrogate, but followed by a non-trailing surrogate character 'A'
  let str = String::from_array([Char::from_int(0xD800), 'A'])
  let view = str[:]
  // This will trigger abort("invalid surrogate pair") in length_eq
  ignore(view.length_eq(1))
}

///|
test "panic_length_ge invalid surrogate pair" {
  let invalid_surrogate_pair = String::from_array([
    Char::from_int(0xD800), // Leading surrogate
    Char::from_int(0x0041), // Invalid trailing surrogate (just a regular 'A')
  ])
  let view = invalid_surrogate_pair[:]
  // This should abort with "invalid surrogate pair"
  let _ = view.length_ge(1)

}

///|
test "take first character from surrogate pairs" {
  let str = "Hello😀😃"
  let view = str.op_as_view()
  let result = view.iter().take(6).collect().length()
  // 6 characters total: 5 ASCII + 1 emoji
  inspect!(result, content="6")
}
