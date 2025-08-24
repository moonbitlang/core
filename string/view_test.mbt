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
test "stringview basic" {
  let str = "Hello🤣🤣🤣"
  let start_offset = 1
  let end_offset = str.offset_of_nth_char(6).unwrap()
  inspect(str.view(start_offset~), content="ello🤣🤣🤣")
  inspect(str.view(end_offset~), content="Hello🤣")
  inspect(str.view(start_offset~, end_offset~), content="ello🤣")
  inspect(str.view(), content="Hello🤣🤣🤣")
}

///|
test "stringview basic2" {
  let str = "He🤣🤣🤣llo"
  let start = 1
  let end = 10
  inspect(str.view(start_offset=start), content="e🤣🤣🤣llo")
  inspect(str.view(end_offset=end), content="He🤣🤣🤣ll")
  inspect(
    str.view(start_offset=start, end_offset=end),
    content="e🤣🤣🤣ll",
  )
  inspect(str.view(), content="He🤣🤣🤣llo")
}

///|
test "stringview subview" {
  let str = "Hello🤣🤣🤣"
  let start = 1
  let end = 7
  let view = str.view(start_offset=start, end_offset=end)
  inspect(view.view(start_offset=1), content="llo🤣")
  inspect(view.view(start_offset=1, end_offset=4), content="llo")
  inspect(view.view(end_offset=4), content="ello")
  inspect(view.view(), content="ello🤣")
}

///|
test "stringview op_get" {
  let str = "Hello🤣🤣🤣"
  let view = str.view(start_offset=1, end_offset=7)
  inspect(view.iter().nth(4).unwrap(), content="🤣")
  inspect(view.iter().nth(4).unwrap(), content="🤣")
}

///|
test "stringview rev_get" {
  let str = "Hello🤣🤣🤣"
  let view = str.view(start_offset=1, end_offset=7)
  inspect(view.rev_iter().nth(0).unwrap(), content="🤣")
  inspect(view.rev_iter().nth(4).unwrap(), content="e")
}

///|
test "stringview data" {
  let str = "Hello🤣🤣🤣"
  let view = str.view(start_offset=1, end_offset=7)
  inspect(view.data(), content="Hello🤣🤣🤣")
}

///|
test "stringview start_offset" {
  let str = "Hello🤣🤣🤣"
  let view = str.view(start_offset=1, end_offset=7)
  inspect(view.start_offset(), content="1")
}

///|
test "stringview length" {
  let str = "Hello🤣🤣🤣"
  let view = str.view(start_offset=1, end_offset=7)
  inspect(view.length(), content="6")
}

///|
test "stingview length_eq" {
  let str = "hello"
  let view = str.view(start_offset=1, end_offset=4)
  inspect(view.char_length_eq(0), content="false")
  inspect(view.char_length_eq(1), content="false")
  inspect(view.char_length_eq(2), content="false")
  inspect(view.char_length_eq(3), content="true")
  inspect(view.char_length_eq(4), content="false")
  inspect(view.char_length_eq(5), content="false")
}

///|
test "stingview length_ge" {
  let str = "hello"
  let view = str.view(start_offset=1, end_offset=4)
  inspect(view.char_length_ge(0), content="true")
  inspect(view.char_length_ge(1), content="true")
  inspect(view.char_length_ge(2), content="true")
  inspect(view.char_length_ge(3), content="true")
  inspect(view.char_length_ge(4), content="false")
  inspect(view.char_length_ge(5), content="false")
}

///|
test "stringview empty" {
  let str = "hello"
  let view = str.view(start_offset=0, end_offset=0)
  inspect(view.length(), content="0")
}

///|
test "panic out of bounds1" {
  let str = "Hello🤣🤣🤣"
  let view = str.view(start_offset=1, end_offset=7)
  let _ = view.iter().nth(5).unwrap()

}

///|
test "panic out of bounds2" {
  let str = "Hello🤣🤣🤣"
  let view = str.view(start_offset=1, end_offset=7)
  let _ = view.view(start_offset=7)

}

///|
test "panic out of bounds3" {
  let str = "Hello🤣🤣🤣"
  let view = str.view(start_offset=1, end_offset=7)
  let _ = view.view(end_offset=7)

}

///|
test "panic out of bounds4" {
  let str = "hello"
  let view = str.view(start_offset=0, end_offset=0)
  let _ = view.iter().nth(0).unwrap()

}

///|
// test "index_at_rev" {
//   let str = "🤣🤣🤣"
//   let offset = str.index_at_rev(0)
//   inspect(offset, content="Some(StringIndex(6))")
//   let offset = str.index_at_rev(1)
//   inspect(offset, content="Some(StringIndex(4))")
//   let offset = str.index_at_rev(2)
//   inspect(offset, content="Some(StringIndex(2))")
//   let offset = str.index_at_rev(3)
//   inspect(offset, content="Some(StringIndex(0))")
//   let offset = str.index_at_rev(4)
//   inspect(offset, content="None")
//   let offset = str.index_at_rev(1).unwrap()
//   let offset = str.index_at_rev(1, end=offset)
//   inspect(offset, content="Some(StringIndex(2))")
// }

///|
// test "stringview negative index" {
//   let str = "Hello🤣🤣🤣"
//   let str_view = str[:]
//   let view = str_view[-1:]
//   inspect(view, content="🤣")
//   let view = str_view[-2:]
//   inspect(view, content="🤣🤣")
//   let view = str_view[-3:]
//   inspect(view, content="🤣🤣🤣")
//   let view = str_view[-4:]
//   inspect(view, content="o🤣🤣🤣")
//   let view = str_view[:-1]
//   inspect(view, content="Hello🤣🤣")
//   let view = str_view[:-2]
//   inspect(view, content="Hello🤣")
//   let view = str_view[:-3]
//   inspect(view, content="Hello")
//   let view = str_view[:-4]
//   inspect(view, content="Hell")
//   let view = str_view[-2:-1]
//   inspect(view, content="🤣")
//   let view = str_view[-3:-1]
//   inspect(view, content="🤣🤣")
//   let view = str_view[-4:-1]
//   inspect(view, content="o🤣🤣")
//   let view = str_view[-4:-2]
//   inspect(view, content="o🤣")
//   let view = str_view[-4:-4]
//   inspect(view, content="")
//   let view = str_view[-3:-3]
//   inspect(view, content="")
// }

///|
test "panic negative index 1" {
  // index_at_rev fails
  let str = "hello"
  let str_view = str[:]
  let _ = str_view.view(start_offset=-6)

}

///|
test "panic negative index 2" {
  // index_at_rev fails
  let str = "hello"
  let str_view = str.view()
  let _ = str_view.view(end_offset=-6)

}

///|
test "panic negative index 3" {
  // index_at_rev returns an index not in bounds of the view
  let str = "hello"
  let str_view = str.view(start_offset=1, end_offset=4)
  let _ = str_view.view(start_offset=-4)

}

///|
test "panic negative index 4" {
  // index_at_rev returns an index not in bounds of the view
  let str = "hello"
  let str_view = str.view(start_offset=1, end_offset=4)
  let _ = str_view.view(end_offset=4)

}

///|
test "panic negative index 5" {
  // index_at_rev returns an index not in bounds of the view
  let str = "hello"
  let str_view = str.view(start_offset=1, end_offset=4)
  let _ = str_view.view(start_offset=4)

}

///|
test "panic negative index 6" {
  // index_at_rev returns an index not in bounds of the view
  let str = "hello"
  let str_view = str.view(start_offset=1, end_offset=4)
  let _ = str_view.view(end_offset=4)

}

///|
test "panic negative index 7" {
  // start > end
  let str = "hello"
  let str_view = str.view(start_offset=1, end_offset=4)
  let _ = str_view.view(start_offset=-1, end_offset=-2)

}

///|
test "panic negative index 8" {
  // start > end
  let str = "hello"
  let str_view = str.view(start_offset=1, end_offset=4)
  let _ = str_view.view(start_offset=-1, end_offset=1)

}

///|
test "panic negative index 9" {
  // start > end
  let str = "hello"
  let str_view = str.view(start_offset=1, end_offset=4)
  let _ = str_view.view(start_offset=2, end_offset=-2)

}

///|
// test "panic rev_get2" {
//   let str = "Hello🤣🤣🤣"
//   let view = str[1:6]
//   let _ = view.rev_iter().nth(-1).unwrap()

// }

///|
test "stringview iter" {
  let str = "hello🤣🤣🤣"
  let view = str.view(start_offset=1, end_offset=7)
  let iter = view.iter()
  inspect(iter.count(), content="5")
  inspect(iter, content="['e', 'l', 'l', 'o', '🤣']")
}

///|
test "stringview rev_iter" {
  let str = "hello🤣🤣🤣"
  let view = str.view(start_offset=1, end_offset=7)
  let iter = view.rev_iter()
  inspect(iter.count(), content="5")
  inspect(iter, content="['🤣', 'o', 'l', 'l', 'e']")
}

///|
test "panic stringview negative index1" {
  let str = "hello🤣😭😂"
  let _ = str.view(start_offset=-9)

}

///|
test "panic stringview negative index2" {
  let str = "hello🤣😭😂"
  let _ = str.view(end_offset=-9)

}

///|
test "panic stringview negative index3" {
  let str = "hello🤣😭😂"
  let _ = str.view(start_offset=-1, end_offset=-2)

}

///|
test "to_string" {
  let s = "Hello World"
  let view = s.view(start_offset=0, end_offset=5)
  let ss = "\{view} Moonbit"
  inspect(ss, content="Hello Moonbit")
}

///|
test "length_eq test with surrogate pair" {
  // "🤣" is encoded as a surrogate pair
  let str = "🤣"
  let view = str[:]
  assert_true(view.char_length_eq(1))
}

///|
test "length_ge with high surrogate" {
  let str = "🐰" // This emoji is represented using a surrogate pair
  let view = str.view(start_offset=0)
  assert_eq(view.char_length_ge(1), true)
  assert_eq(view.char_length_ge(2), false)
}

///|
test "panic op_as_view with invalid positive start index" {
  let str = "Hello🤣🤣🤣"
  let view = str.view()
  ignore(view.view(start_offset=100))
}

///|
test "panic on accessing negative index" {
  let str = "Hello🤣🤣🤣"
  let view = str.view()
  ignore(view.view(start_offset=-1)) // This should panic due to invalid index
}

///|
test "panic on invalid start index" {
  let str = "Hello"
  ignore(str.view(start_offset=10))
}

///|
test "panic on invalid end index" {
  let str = "Hello"
  ignore(str.view(start_offset=0, end_offset=10))
}

///|
test "panic length_eq should panic on invalid surrogate pair" {
  // Create a string with an invalid surrogate pair:
  // 0xD800 is a leading surrogate, but followed by a non-trailing surrogate character 'A'
  let str = String::from_array([(0xD800).unsafe_to_char(), 'A'])
  let view = str[:]
  // This will trigger abort("invalid surrogate pair") in length_eq
  ignore(view.char_length_eq(1))
}

///|
test "panic_length_ge invalid surrogate pair" {
  let invalid_surrogate_pair = String::from_array([
    (0xD800).unsafe_to_char(), // Leading surrogate
    (0x0041).unsafe_to_char(), // Invalid trailing surrogate (just a regular 'A')
  ])
  let view = invalid_surrogate_pair[:]
  // This should abort with "invalid surrogate pair"
  let _ = view.char_length_ge(1)

}

///|
test "take first character from surrogate pairs" {
  let str = "Hello😀😃"
  let view = str.view()
  let result = view.iter().take(6).collect().length()
  // 6 characters total: 5 ASCII + 1 emoji
  inspect(result, content="6")
}

///|
test "index_of_nth_char" {
  let str = "aa😭b😂cc"
  let view = str.view(start_offset=1, end_offset=8)
  inspect(view, content="a😭b😂c")
  inspect(view.offset_of_nth_char(0), content="Some(0)")
  inspect(view.offset_of_nth_char(1), content="Some(1)")
  inspect(view.offset_of_nth_char(2), content="Some(3)")
  inspect(view.offset_of_nth_char(3), content="Some(4)")
  inspect(view.offset_of_nth_char(4), content="Some(6)")
  inspect(view.offset_of_nth_char(5), content="None")
  inspect(view.offset_of_nth_char(-1), content="Some(6)")
  inspect(view.offset_of_nth_char(-2), content="Some(4)")
  inspect(view.offset_of_nth_char(-3), content="Some(3)")
  inspect(view.offset_of_nth_char(-4), content="Some(1)")
  inspect(view.offset_of_nth_char(-5), content="Some(0)")
  inspect(view.offset_of_nth_char(-6), content="None")
}

///|
test "char_length" {
  let str = "aa😭b😂cc"
  let view = str.view(start_offset=1, end_offset=8)
  inspect(view.char_length(), content="5")
}

///|
test "utf16 indexed view" {
  let str = "aa😭b😂cc"
  let v0 = str.view()
  inspect(v0, content="aa😭b😂cc")
  inspect(v0.char_length(), content="7")
  let v1 = str.view(start_offset=1, end_offset=8)
  inspect(v1, content="a😭b😂c")
  inspect(v1.char_length(), content="5")
  let v2 = str.view(start_offset=1)
  inspect(v2, content="a😭b😂cc")
  inspect(v2.char_length(), content="6")
  let v3 = str.view(end_offset=4)
  inspect(v3, content="aa😭")
  inspect(v3.char_length(), content="3")
  let v4 = str.view(start_offset=1, end_offset=1)
  inspect(v4, content="")
  inspect(v4.char_length(), content="0")
  let v5 = str.view(end_offset=0)
  inspect(v5, content="")
  inspect(v5.char_length(), content="0")
  let v6 = str.view(start_offset=str.length())
  inspect(v6, content="")
  inspect(v6.char_length(), content="0")
  let v7 = str.view(start_offset=str.length(), end_offset=str.length())
  inspect(v7, content="")
  inspect(v7.char_length(), content="0")
}

///|
test "op_equal" {
  let str = "012301230123"
  inspect(str.view() == str.view(), content="true")
  inspect(str.view() == str.view(start_offset=1), content="false")
  inspect(
    str.view(start_offset=0, end_offset=4) ==
    str.view(start_offset=4, end_offset=8),
    content="true",
  )
  inspect(
    str.view(start_offset=0, end_offset=4) ==
    str.view(start_offset=8, end_offset=12),
    content="true",
  )
  inspect(
    str.view(start_offset=0, end_offset=3) ==
    str.view(start_offset=4, end_offset=7),
    content="true",
  )
  inspect(
    str.view(start_offset=0, end_offset=3) ==
    str.view(start_offset=0, end_offset=4),
    content="false",
  )

  // Test with surrogate pairs
  let emoji_str = "🤣abc🤣def"
  inspect(
    emoji_str.view(start_offset=0, end_offset=2) ==
    emoji_str.view(start_offset=5, end_offset=7),
    content="true",
  )
  inspect(
    emoji_str.view(start_offset=2, end_offset=5) ==
    emoji_str.view(start_offset=7, end_offset=10),
    content="false",
  )
  inspect(
    emoji_str.view(start_offset=0, end_offset=5) ==
    emoji_str.view(start_offset=5, end_offset=10),
    content="false",
  )

  // Test empty views
  inspect(
    str.view(start_offset=0, end_offset=0) ==
    str.view(start_offset=4, end_offset=4),
    content="true",
  )
  inspect(
    str.view(start_offset=0, end_offset=0) ==
    str.view(start_offset=0, end_offset=1),
    content="false",
  )

  // Test views from different strings
  let str1 = "bcabc"
  let str2 = "abcabc"
  inspect(str1.view() == str2.view(), content="false")
  inspect(str1.view() == str2.view(start_offset=1), content="true")
}

///|
test "stringview compare" {
  let str = "abcabc"

  // Test equal views
  inspect(
    str
    .view(start_offset=0, end_offset=3)
    .compare(str.view(start_offset=3, end_offset=6)),
    content="0",
  )

  // Test lexicographically smaller view
  inspect(
    str
    .view(start_offset=0, end_offset=3)
    .compare(str.view(start_offset=2, end_offset=5)),
    content="-1",
  )

  // Test lexicographically larger view
  inspect(
    str
    .view(start_offset=1, end_offset=4)
    .compare(str.view(start_offset=3, end_offset=6)),
    content="1",
  )

  // Test different length views
  inspect(
    str
    .view(start_offset=0, end_offset=3)
    .compare(str.view(start_offset=0, end_offset=4)),
    content="-1",
  )
  inspect(
    str
    .view(start_offset=1, end_offset=5)
    .compare(str.view(start_offset=2, end_offset=5)),
    content="1",
  )

  // Test with surrogate pairs
  let emoji_str = "🤣abc🤣def"
  inspect(
    emoji_str
    .view(start_offset=0, end_offset=5)
    .compare(emoji_str.view(start_offset=5, end_offset=10)),
    content="-1",
  )

  // Test empty views
  inspect(
    str
    .view(start_offset=0, end_offset=0)
    .compare(str.view(start_offset=4, end_offset=4)),
    content="0",
  )

  // Test views from different strings with same content
  let str1 = "bcabc"
  let str2 = "abcabc"
  inspect(str1.view().compare(str2.view(start_offset=1)), content="0")
}

///|
test "view of view" {
  let v1 = "00abc😭def😂ghi11".view(start_offset=2, end_offset=15)
  let v2 = v1.view(start_offset=3, end_offset=6)
  inspect(v2, content="😭d")
  let v3 = v2.view(start_offset=2, end_offset=3)
  inspect(v3, content="d")
  let v4 = v1.view(start_offset=2, end_offset=6)
  inspect(v4, content="c😭d")
  let v6 = v1.view(start_offset=5, end_offset=5)
  inspect(v6, content="")
  let v7 = v1.view()
  inspect(v7, content="abc😭def😂ghi")
  let v8 = v1.view(start_offset=3, end_offset=10)
  inspect(v8, content="😭def😂")
}

///|
test "iter2" {
  let str = "aa😭b😂cc"
  let view = str.view(start_offset=1, end_offset=8)
  inspect(
    view.iter2().iter().collect(),
    content="[(0, 'a'), (1, '😭'), (2, 'b'), (3, '😂'), (4, 'c')]",
  )
}

///|
test "from_array" {
  let v = View::from_array(['a', '😭', 'b', '😂', 'c'])
  inspect(v, content="a😭b😂c")
}

///|
test "from_iter" {
  let v = View::from_iter(['a', '😭', 'b', '😂', 'c'].iter())
  inspect(v, content="a😭b😂c")
}

///|
test "make" {
  let v = View::make(5, 'a')
  inspect(v, content="aaaaa")
}

///|
test "to_json" {
  let v = "hello".view(start_offset=1, end_offset=4)
  inspect(
    v.to_json(),
    content=(
      #|String("ell")
    ),
  )
}

///|
test "hash" {
  let a = "abc"
  let b = "def"
  let c = "abc"
  assert_eq(a.hash(), c.hash())
  assert_not_eq(a.hash(), b.hash())
}

///|
/// This test checks the invariance that the hash of a string and its view are the same.
/// 
/// This is necessary because we may want to use a string view as a key in a hash map,
/// and we need to ensure that the hash remains consistent with the original string.
test "string view hash invariant" {
  let strings : Array[String] = @quickcheck.samples(20)
  for s in strings {
    let view = s[:]
    assert_eq(s.hash(), view.hash())
  }
}

///|
test "View::replace" {
  inspect("hello"[:].replace(old="o", new="a"), content="hella")
  inspect("hello"[:].replace(old="world", new="x"), content="hello")
  inspect("abc"[:].replace(old="", new="x"), content="xabc")
}

///|
test "View::repeat" {
  inspect("ab"[:].repeat(1), content="ab")
  inspect("ab"[:].repeat(0), content="")
  inspect("ab"[:].repeat(-2), content="")
}

///|
test "View::split take" {
  inspect(
    "a,b,c,d"[:].split(",").take(2).map(View::to_string).collect(),
    content=(
      #|["a", "b"]
    ),
  )
}

///|
test "String::op_as_view basic usage" {
  let str = "Hello🤣World"

  // Basic usage - positive indices
  let view1 = str[0:5]
  inspect(view1, content="Hello")

  // Negative indexing from end
  let view2 = str[-5:]
  inspect(view2, content="World")

  // Full string view
  let view3 = str[:]
  inspect(view3, content="Hello🤣World")

  // Start from middle
  let view4 = str[5:]
  inspect(view4, content="🤣World")

  // End before middle
  let view5 = str[:5]
  inspect(view5, content="Hello")
}

///|
test "String::op_as_view error cases" {
  let str = "Hello🤣World"

  // InvalidIndex - splits surrogate pair
  let view1 = try? str[:6]
  inspect(view1, content="Err(InvalidIndex)")

  // IndexOutOfBounds - beyond string length
  let view2 = try? str[0:20]
  inspect(view2, content="Err(IndexOutOfBounds)")

  // IndexOutOfBounds - negative index too large
  let view3 = try? str[-20:]
  inspect(view3, content="Err(IndexOutOfBounds)")

  // IndexOutOfBounds - start > end
  let view4 = try? str[5:3]
  inspect(view4, content="Err(IndexOutOfBounds)")

  // InvalidIndex - start on trailing surrogate
  let view5 = try? str[6:8]
  inspect(view5, content="Err(InvalidIndex)")
}

///|
test "String::op_as_view with surrogate pairs" {
  let str = "Hello🤣😭😂World"

  // View containing complete emoji
  let view1 = str[5:7]
  inspect(view1, content="🤣")

  // View containing multiple emojis
  let view2 = str[5:11]
  inspect(view2, content="🤣😭😂")

  // View from middle of emoji sequence
  let view3 = str[7:9]
  inspect(view3, content="😭")

  // Invalid - splits first emoji
  let view4 = try? str[5:6]
  inspect(view4, content="Err(InvalidIndex)")

  // Invalid - splits second emoji
  let view5 = try? str[7:8]
  inspect(view5, content="Err(InvalidIndex)")
}

///|
test "View::op_as_view basic usage" {
  let str = "Hello🤣World"[1:-1] // "ello🤣Worl"

  // Basic subview creation
  let view1 = str[0:6]
  inspect(view1, content="ello🤣")

  // Negative indexing within view
  let view2 = str[-2:]
  inspect(view2, content="rl")

  // Full view
  let view3 = str[:]
  inspect(view3, content="ello🤣Worl")

  // Start from middle
  let view4 = str[4:]
  inspect(view4, content="🤣Worl")

  // End before middle
  let view5 = str[:4]
  inspect(view5, content="ello")
}

///|
test "View::op_as_view error cases" {
  let str = "Hello🤣World"[1:-1] // "ello🤣Worl"

  // IndexOutOfBounds - beyond view range
  let view1 = try? str[0:15]
  inspect(view1, content="Err(IndexOutOfBounds)")

  // IndexOutOfBounds - negative index too large
  let view2 = try? str[-20:]
  inspect(view2, content="Err(IndexOutOfBounds)")

  // IndexOutOfBounds - start > end
  let view3 = try? str[5:3]
  inspect(view3, content="Err(IndexOutOfBounds)")

  // InvalidIndex - splits surrogate pair
  let view4 = try? str[:5]
  inspect(view4, content="Err(InvalidIndex)")

  // IndexOutOfBounds - start beyond view
  let view5 = try? str[11:]
  inspect(view5, content="Err(IndexOutOfBounds)")
}

///|
test "View::op_as_view with surrogate pairs" {
  let str = "Hello🤣😭😂World"[1:-1] // "ello🤣😭😂Worl"

  // View containing complete emoji
  let view1 = str[4:6]
  inspect(view1, content="🤣")

  // View containing multiple emojis
  let view2 = str[4:10]
  inspect(view2, content="🤣😭😂")

  // View from middle of emoji sequence
  let view3 = str[6:8]
  inspect(view3, content="😭")

  // Invalid - splits first emoji
  let view4 = try? str[4:5]
  inspect(view4, content="Err(InvalidIndex)")

  // Invalid - splits second emoji
  let view5 = try? str[6:7]
  inspect(view5, content="Err(InvalidIndex)")
}

///|
test "nested View::op_as_view operations" {
  let str = "Hello🤣World"

  // Create first view
  let view1 = str[1:-1] // "ello🤣Worl"
  inspect(view1, content="ello🤣Worl")

  // Create subview from first view
  let view2 = view1[2:6] // "lo🤣"
  inspect(view2, content="lo🤣")

  // Create subview from second view
  let view3 = view2[2:] // "🤣"
  inspect(view3, content="🤣")

  // Create subview with negative indexing
  let view4 = view1[-4:-1] // "Wor"
  inspect(view4, content="Wor")
}

///|
test "View::op_as_view edge cases" {
  let str = "Hello🤣World"

  // Empty view at start
  let view1 = str[0:0]
  inspect(view1, content="")

  // Empty view at end
  let view2 = str[str.length():str.length()]
  inspect(view2, content="")

  // Single character view
  let view3 = str[0:1]
  inspect(view3, content="H")

  // Single emoji view
  let view4 = str[5:7]
  inspect(view4, content="🤣")

  // View with only ASCII characters
  let view5 = str[0:5]
  inspect(view5, content="Hello")
}

///|
test "View::op_as_view with complex Unicode" {
  let str = "Hello🤣😭😂🌍World"

  // View with multiple emojis
  let view1 = str[5:13]
  inspect(view1, content="🤣😭😂🌍")

  // View with mixed content
  let view2 = str[4:14]
  inspect(view2, content="o🤣😭😂🌍W")

  // View ending with emoji
  let view3 = str[-7:]
  inspect(view3, content="🌍World")

  // View starting with emoji
  let view4 = str[5:]
  inspect(view4, content="🤣😭😂🌍World")

  // Invalid - splits emoji
  let view5 = try? str[5:6]
  inspect(view5, content="Err(InvalidIndex)")
}

///|
test "View::op_as_view performance characteristics" {
  let str = "Hello🤣World"

  // Test that operations are O(1) - multiple operations
  let view1 = str[1:-1]
  let view2 = view1[1:-1]
  let view3 = view2[1:-1]
  let view4 = view3[1:-1]
  inspect(view4, content="o🤣W")

  // Test with longer string
  let long_str = "Hello🤣WorldHello🤣WorldHello🤣World"
  let long_view1 = long_str[5:15]
  let long_view2 = long_view1[2:8]
  inspect(long_view2, content="WorldH")
}

///|
test "View::op_as_view with empty and single character strings" {
  let empty_str = ""

  // Empty string operations
  let view1 = empty_str[:]
  inspect(view1, content="")
  let view2 = empty_str[0:0]
  inspect(view2, content="")

  // Single character string
  let single_str = "A"
  let view3 = single_str[:]
  inspect(view3, content="A")
  let view4 = single_str[0:1]
  inspect(view4, content="A")
  let view5 = single_str[0:0]
  inspect(view5, content="")
}

///|
test "View::op_as_view boundary validation" {
  let str = "Hello🤣World"

  // Test boundary conditions
  let view1 = str[0:str.length()]
  inspect(view1, content="Hello🤣World")
  let view2 = str[str.length():str.length()]
  inspect(view2, content="")

  // Test negative boundary conditions
  let view3 = str[-str.length():]
  inspect(view3, content="Hello🤣World")
  let view4 = str[-1:]
  inspect(view4, content="d")

  // Test invalid boundaries
  let view5 = try? str[str.length() + 1:]
  inspect(view5, content="Err(IndexOutOfBounds)")
  let view6 = try? str[-str.length() - 1:]
  inspect(view6, content="Err(IndexOutOfBounds)")
}

///|
test "StringView add" {
  let str = "Hello🤣World"
  let view1 = str[0:5]
  let view2 = str[5:]
  inspect(view1 + view2, content="Hello🤣World")

  // more tests
  let view3 = str[0:5]
  let view4 = str[5:]
  inspect(view3 + view4, content="Hello🤣World")
  let view5 = str[0:5]
  let view6 = str[5:]
  inspect(view5 + view6, content="Hello🤣World")
  let view7 = str[0:5]
  let view8 = str[5:]
  inspect(view7 + view8, content="Hello🤣World")
}

// Added test to ensure View::op_get abort is covered
// Accessing an index beyond the view length should panic
// and cover the "Index out of bounds" branch in View::op_get.
///|
test "panic view op_get out of bounds" {
  let str = "Hello"
  let view = str.view(start_offset=0, end_offset=5)
  view[5] |> ignore
}

// Added test to cover start index pointing to trailing surrogate
// in View::op_as_view. Using a view that begins partway through a string
// and attempting to create a subview starting on the trailing surrogate
// of an emoji should raise `InvalidIndex`.
///|
test "View::op_as_view start on trailing surrogate" {
  let base = "Hello🤣😭😂World"
  let view = base[1:-1] // "ello🤣😭😂Worl"
  let result = try? view[5:]
  inspect(result, content="Err(InvalidIndex)")
}
