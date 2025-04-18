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
  let offset = str.index_at(3)
  inspect!(offset, content="Some(StringIndex(3))")
  let offset = str.index_at(5)
  inspect!(offset, content="Some(StringIndex(5))")
  let offset = str.index_at(6)
  inspect!(offset, content="None")
}

///|
test "index_at with surrogate pairs" {
  let str = "🤣🤣🤣"
  let offset = str.index_at(1)
  inspect!(offset, content="Some(StringIndex(2))")
  let offset = str.index_at(2)
  inspect!(offset, content="Some(StringIndex(4))")
  let offset = str.index_at(3)
  inspect!(offset, content="Some(StringIndex(6))")
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
  inspect!(view[0], content="e")
  inspect!(view[4], content="🤣")
}

///|
test "stringview rev_get" {
  let str = "Hello🤣🤣🤣"
  let view = str[1:6]
  inspect!(view.rev_get(0), content="🤣")
  inspect!(view.rev_get(4), content="e")
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
  inspect!(view.char_length_eq(0), content="false")
  inspect!(view.char_length_eq(1), content="false")
  inspect!(view.char_length_eq(2), content="false")
  inspect!(view.char_length_eq(3), content="true")
  inspect!(view.char_length_eq(4), content="false")
  inspect!(view.char_length_eq(5), content="false")
}

///|
test "stingview length_ge" {
  let str = "hello"
  let view = str[1:4]
  inspect!(view.char_length_ge(0), content="true")
  inspect!(view.char_length_ge(1), content="true")
  inspect!(view.char_length_ge(2), content="true")
  inspect!(view.char_length_ge(3), content="true")
  inspect!(view.char_length_ge(4), content="false")
  inspect!(view.char_length_ge(5), content="false")
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
  let offset = str.index_at_rev(0)
  inspect!(offset, content="Some(StringIndex(6))")
  let offset = str.index_at_rev(1)
  inspect!(offset, content="Some(StringIndex(4))")
  let offset = str.index_at_rev(2)
  inspect!(offset, content="Some(StringIndex(2))")
  let offset = str.index_at_rev(3)
  inspect!(offset, content="Some(StringIndex(0))")
  let offset = str.index_at_rev(4)
  inspect!(offset, content="None")
  let offset = str.index_at_rev(1).unwrap()
  let offset = str.index_at_rev(1, end=offset)
  inspect!(offset, content="Some(StringIndex(2))")
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
test "stringview rev_iter" {
  let str = "hello🤣🤣🤣"
  let view = str[1:6]
  let iter = view.rev_iter()
  inspect!(iter.count(), content="5")
  inspect!(iter, content="['🤣', 'o', 'l', 'l', 'e']")
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
  assert_true!(view.char_length_eq(1))
}

///|
test "length_ge with high surrogate" {
  let str = "🐰" // This emoji is represented using a surrogate pair
  let view = str[0:]
  assert_eq!(view.char_length_ge(1), true)
  assert_eq!(view.char_length_ge(2), false)
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
  ignore(view.char_length_eq(1))
}

///|
test "panic_length_ge invalid surrogate pair" {
  let invalid_surrogate_pair = String::from_array([
    Char::from_int(0xD800), // Leading surrogate
    Char::from_int(0x0041), // Invalid trailing surrogate (just a regular 'A')
  ])
  let view = invalid_surrogate_pair[:]
  // This should abort with "invalid surrogate pair"
  let _ = view.char_length_ge(1)

}

///|
test "take first character from surrogate pairs" {
  let str = "Hello😀😃"
  let view = str.op_as_view()
  let result = view.iter().take(6).collect().length()
  // 6 characters total: 5 ASCII + 1 emoji
  inspect!(result, content="6")
}

///|
test "index_of_nth_char" {
  let str = "aa😭b😂cc"
  let view = str.view(start_offset=1, end_offset=8)
  inspect!(view, content="a😭b😂c")
  inspect!(view.offset_of_nth_char(0), content="Some(0)")
  inspect!(view.offset_of_nth_char(1), content="Some(1)")
  inspect!(view.offset_of_nth_char(2), content="Some(3)")
  inspect!(view.offset_of_nth_char(3), content="Some(4)")
  inspect!(view.offset_of_nth_char(4), content="Some(6)")
  inspect!(view.offset_of_nth_char(5), content="None")
  inspect!(view.offset_of_nth_char(-1), content="Some(6)")
  inspect!(view.offset_of_nth_char(-2), content="Some(4)")
  inspect!(view.offset_of_nth_char(-3), content="Some(3)")
  inspect!(view.offset_of_nth_char(-4), content="Some(1)")
  inspect!(view.offset_of_nth_char(-5), content="Some(0)")
  inspect!(view.offset_of_nth_char(-6), content="None")
}

///|
test "char_at" {
  let str = "aa😭b😂cc"
  let view = str.view(start_offset=1, end_offset=8)
  inspect!(view.char_at(0), content="a")
  inspect!(view.char_at(1), content="😭")
  inspect!(view.char_at(3), content="b")
  inspect!(view.char_at(4), content="😂")
  inspect!(view.char_at(6), content="c")
}

///|
test "charcode_at" {
  let str = "aa😭b😂cc"
  let view = str.view(start_offset=1, end_offset=8)
  inspect!(view.charcode_at(0), content="97")
  inspect!(view.charcode_at(1), content="55357")
  inspect!(view.charcode_at(2), content="56877")
  inspect!(view.charcode_at(3), content="98")
  inspect!(view.charcode_at(4), content="55357")
  inspect!(view.charcode_at(5), content="56834")
  inspect!(view.charcode_at(6), content="99")
}

///|
test "char_length" {
  let str = "aa😭b😂cc"
  let view = str.view(start_offset=1, end_offset=8)
  inspect!(view.char_length(), content="5")
}

///|
test "utf16 indexed view" {
  let str = "aa😭b😂cc"
  let v0 = str.view()
  inspect!(v0, content="aa😭b😂cc")
  inspect!(v0.char_length(), content="7")
  let v1 = str.view(start_offset=1, end_offset=8)
  inspect!(v1, content="a😭b😂c")
  inspect!(v1.char_length(), content="5")
  let v2 = str.view(start_offset=1)
  inspect!(v2, content="a😭b😂cc")
  inspect!(v2.char_length(), content="6")
  let v3 = str.view(end_offset=4)
  inspect!(v3, content="aa😭")
  inspect!(v3.char_length(), content="3")
  let v4 = str.view(start_offset=1, end_offset=1)
  inspect!(v4, content="")
  inspect!(v4.char_length(), content="0")
  let v5 = str.view(end_offset=0)
  inspect!(v5, content="")
  inspect!(v5.char_length(), content="0")
  let v6 = str.view(start_offset=str.length())
  inspect!(v6, content="")
  inspect!(v6.char_length(), content="0")
  let v7 = str.view(start_offset=str.length(), end_offset=str.length())
  inspect!(v7, content="")
  inspect!(v7.char_length(), content="0")
}

///|
test "op_equal" {
  let str = "012301230123"
  inspect!(str.view() == str.view(), content="true")
  inspect!(str.view() == str.view(start_offset=1), content="false")
  inspect!(
    str.view(start_offset=0, end_offset=4) ==
    str.view(start_offset=4, end_offset=8),
    content="true",
  )
  inspect!(
    str.view(start_offset=0, end_offset=4) ==
    str.view(start_offset=8, end_offset=12),
    content="true",
  )
  inspect!(
    str.view(start_offset=0, end_offset=3) ==
    str.view(start_offset=4, end_offset=7),
    content="true",
  )
  inspect!(
    str.view(start_offset=0, end_offset=3) ==
    str.view(start_offset=0, end_offset=4),
    content="false",
  )

  // Test with surrogate pairs
  let emoji_str = "🤣abc🤣def"
  inspect!(
    emoji_str.view(start_offset=0, end_offset=2) ==
    emoji_str.view(start_offset=5, end_offset=7),
    content="true",
  )
  inspect!(
    emoji_str.view(start_offset=2, end_offset=5) ==
    emoji_str.view(start_offset=7, end_offset=10),
    content="false",
  )
  inspect!(
    emoji_str.view(start_offset=0, end_offset=5) ==
    emoji_str.view(start_offset=5, end_offset=10),
    content="false",
  )

  // Test empty views
  inspect!(
    str.view(start_offset=0, end_offset=0) ==
    str.view(start_offset=4, end_offset=4),
    content="true",
  )
  inspect!(
    str.view(start_offset=0, end_offset=0) ==
    str.view(start_offset=0, end_offset=1),
    content="false",
  )

  // Test views from different strings
  let str1 = "bcabc"
  let str2 = "abcabc"
  inspect!(str1.view() == str2.view(), content="false")
  inspect!(str1.view() == str2.view(start_offset=1), content="true")
}

///|
test "stringview compare" {
  let str = "abcabc"

  // Test equal views
  inspect!(
    str
    .view(start_offset=0, end_offset=3)
    .compare(str.view(start_offset=3, end_offset=6)),
    content="0",
  )

  // Test lexicographically smaller view
  inspect!(
    str
    .view(start_offset=0, end_offset=3)
    .compare(str.view(start_offset=2, end_offset=5)),
    content="-1",
  )

  // Test lexicographically larger view
  inspect!(
    str
    .view(start_offset=1, end_offset=4)
    .compare(str.view(start_offset=3, end_offset=6)),
    content="1",
  )

  // Test different length views
  inspect!(
    str
    .view(start_offset=0, end_offset=3)
    .compare(str.view(start_offset=0, end_offset=4)),
    content="-1",
  )
  inspect!(
    str
    .view(start_offset=1, end_offset=5)
    .compare(str.view(start_offset=2, end_offset=5)),
    content="1",
  )

  // Test with surrogate pairs
  let emoji_str = "🤣abc🤣def"
  inspect!(
    emoji_str
    .view(start_offset=0, end_offset=5)
    .compare(emoji_str.view(start_offset=5, end_offset=10)),
    content="-1",
  )

  // Test empty views
  inspect!(
    str
    .view(start_offset=0, end_offset=0)
    .compare(str.view(start_offset=4, end_offset=4)),
    content="0",
  )

  // Test views from different strings with same content
  let str1 = "bcabc"
  let str2 = "abcabc"
  inspect!(str1.view().compare(str2.view(start_offset=1)), content="0")
}

///|
test "view of view" {
  let v1 = "00abc😭def😂ghi11".view(start_offset=2, end_offset=15)
  let v2 = v1.view(start_offset=3, end_offset=6)
  inspect!(v2, content="😭d")
  let v3 = v2.view(start_offset=2, end_offset=3)
  inspect!(v3, content="d")
  let v4 = v1.view(start_offset=2, end_offset=6)
  inspect!(v4, content="c😭d")
  let v6 = v1.view(start_offset=5, end_offset=5)
  inspect!(v6, content="")
  let v7 = v1.view()
  inspect!(v7, content="abc😭def😂ghi")
  let v8 = v1.view(start_offset=3, end_offset=10)
  inspect!(v8, content="😭def😂")
}

///|
test "iter2" {
  let str = "aa😭b😂cc"
  let view = str.view(start_offset=1, end_offset=8)
  inspect!(
    view.iter2().iter().collect(),
    content="[(0, 'a'), (1, '😭'), (2, 'b'), (3, '😂'), (4, 'c')]",
  )
}

///|
test "from_array" {
  let v = View::from_array(['a', '😭', 'b', '😂', 'c'])
  inspect!(v, content="a😭b😂c")
}

///|
test "from_iter" {
  let v = View::from_iter(['a', '😭', 'b', '😂', 'c'].iter())
  inspect!(v, content="a😭b😂c")
}

///|
test "make" {
  let v = View::make(5, 'a')
  inspect!(v, content="aaaaa")
}

///|
test "to_json" {
  let v = "hello"[1:4].view()
  inspect!(
    v.to_json(),
    content=
      #|String("ell")
    ,
  )
}
