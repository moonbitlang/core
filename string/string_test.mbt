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
test "String::from_array" {
  inspect!(@string.from_array(['1', '2', '3', '4', '5']), content="12345")
}

///|
test "String::from_iter" {
  inspect!(@string.from_iter(['1', '2', '3', '4', '5'].iter()), content="12345")
}

///|
test "String::concat" {
  inspect!(@string.concat(["123", "456"]), content="123456")
  inspect!(
    @string.concat(["aaa", "bbb", "ccc"], separator=" "),
    content="aaa bbb ccc",
  )
  inspect!(@string.concat([], separator=" "), content="")
}

///|
test "default" {
  inspect!(@string.default())
}

///|
test "compare" {
  assert_eq!(0, "".compare(""))
  assert_eq!(-1, "".compare("abc"))
  assert_eq!(1, "abc".compare(""))
  assert_eq!(-1, "abcd".compare("abce"))
  assert_eq!(1, "abce".compare("abcd"))
  assert_eq!(-1, "c".compare("ab"))
  assert_eq!(1, "ab".compare("c"))
}

///|
test "to_bytes" {
  assert_eq!("中文".to_bytes().to_unchecked_string(), "中文")
  assert_eq!("asdf".to_bytes().to_unchecked_string(), "asdf")
  assert_eq!("🤣🤣".to_bytes().to_unchecked_string(), "🤣🤣")
  assert_eq!("🤔".to_bytes().to_unchecked_string(), "🤔")
}

///|
test "Show::output" {
  fn repr(s : String) {
    let buf = StringBuilder::new(size_hint=0)
    s |> Show::output(buf)
    buf.to_string()
  }

  assert_eq!(repr("a"), "\"a\"")
  assert_eq!(repr("'"), "\"'\"")
  assert_eq!(repr("\""), "\"\\\"\"")
  assert_eq!(repr("\\"), "\"\\\\\"")
  assert_eq!(repr("\n"), "\"\\n\"")
  assert_eq!(repr("\r"), "\"\\r\"")
  assert_eq!(repr("\b"), "\"\\b\"")
  assert_eq!(repr("\t"), "\"\\t\"")
  assert_eq!(repr("\x00"), "\"\\x00\"")
  assert_eq!(repr("abc'\"def\\"), "\"abc'\\\"def\\\\\"")
}

///|
test "to_array" {
  let a = "你好！mbt😀".to_array()
  inspect!(a[0], content="你")
  inspect!(a[1], content="好")
  inspect!(a[2], content="！")
  inspect!(a[3], content="m")
  inspect!(a[4], content="b")
  inspect!(a[5], content="t")
  inspect!(a[6], content="😀")
}

///|
test "chars" {
  let mut str = ""
  "A😊𠮷BA😊𠮷B"
  .iter()
  .each(fn(c) { str = str + c.to_int().to_string() + "\n" })
  inspect!(
    str,
    content=
      #|65
      #|128522
      #|134071
      #|66
      #|65
      #|128522
      #|134071
      #|66
      #|
    ,
  )
  inspect!(
    "A😊𠮷BA😊𠮷B".iter().take(2).collect(),
    content="['A', '😊']",
  )
  inspect!(
    "A😊𠮷BA😊𠮷B".iter().take(4).collect(),
    content="['A', '😊', '𠮷', 'B']",
  )
}

///|
test "rev_iter" {
  let mut str = ""
  "A😊𠮷BA😊𠮷B"
  .rev_iter()
  .each(fn(c) { str = str + c.to_int().to_string() + "\n" })
  inspect!(
    str,
    content=
      #|66
      #|134071
      #|128522
      #|65
      #|66
      #|134071
      #|128522
      #|65
      #|
    ,
  )
  inspect!(
    "A😊𠮷BA😊𠮷B".rev_iter().take(2).collect(),
    content="['B', '𠮷']",
  )
  inspect!(
    "A😊𠮷BA😊𠮷B".rev_iter().take(4).collect(),
    content="['B', '𠮷', '😊', 'A']",
  )
}

///|
test "iter2" {
  let mut str = ""
  "A😊𠮷BA😊𠮷B"
  .iter2()
  .each(fn(i, c) { str = str + "\{i}: \{c.to_int()} \n" })
  inspect!(
    str,
    content=
      #|0: 65 
      #|1: 128522 
      #|2: 134071 
      #|3: 66 
      #|4: 65 
      #|5: 128522 
      #|6: 134071 
      #|7: 66 
      #|
    ,
  )
}

// test here to avlid cyclic dependency between assertion and builtin
///|
test "Buffer::to_bytes" {
  let buffer = StringBuilder::new(size_hint=16)
  buffer.write_string("中文")
  assert_eq!(buffer.to_string(), "中文")
}

///|
test "trim_start" {
  inspect!("aaabcd".trim_start("a"), content="bcd")
  inspect!("aaabcd".trim_start(" "), content="aaabcd")
  inspect!("aaabcd".trim_start(""), content="aaabcd")
  inspect!("  abc".trim_start(" "), content="abc")
  inspect!(
    "哇你好月兔你好哇".trim_start("你好哇"),
    content="月兔你好哇",
  )
  inspect!("😍😍😭😡😡".trim_start("😍"), content="😭😡😡")
}

///|
test "contains" {
  @json.inspect!("abc".contains("a"), content=true)
  @json.inspect!("中文".contains("文"), content=true)
  @json.inspect!("中文".contains("中"), content=true)
  @json.inspect!("中文".contains("a"), content=false)
}

///|
test "trim_end" {
  inspect!("abcddd".trim_end("d"), content="abc")
  inspect!("abcddd".trim_end(" "), content="abcddd")
  inspect!("abcddd".trim_end(""), content="abcddd")
  inspect!("abc  ".trim_end(" "), content="abc")
  inspect!(
    "哇你好月兔你好哇".trim_end("你好哇"),
    content="哇你好月兔",
  )
  inspect!("😍😍😭😡😡".trim_end("😡"), content="😍😍😭")
}

///|
test "trim" {
  inspect!("xxxabcxxx".trim("x"), content="abc")
  inspect!("xxxabcxxx".trim(""), content="xxxabcxxx")
  inspect!("哇你好月兔你好哇".trim("你好哇"), content="月兔")
  inspect!("\n\r\t abc \n\r\t".trim(" \n\r\t"), content="abc")
  inspect!("=-wow-=".trim("-="), content="wow")
  inspect!("😍😍😭😡😡".trim("😍😡"), content="😭")
}

///|
test "trim_space" {
  inspect!(" abc ".trim_space(), content="abc")
  inspect!("abc ".trim_space(), content="abc")
  inspect!(" abc".trim_space(), content="abc")
  inspect!("\nabc\n".trim_space(), content="abc")
  inspect!("\tabc\t".trim_space(), content="abc")
  inspect!("\rabc\r".trim_space(), content="abc")
  inspect!("abc".trim_space(), content="abc")
  inspect!("".trim_space(), content="")
  inspect!("  ".trim_space(), content="")
  inspect!("\n\n".trim_space(), content="")
  inspect!("\t\t".trim_space(), content="")
  inspect!("\r\r".trim_space(), content="")
}

///|
test "is_empty" {
  inspect!("".is_empty(), content="true")
  inspect!(" ".is_empty(), content="false")
  inspect!("\n".is_empty(), content="false")
  inspect!("\r".is_empty(), content="false")
  inspect!("\t".is_empty(), content="false")
  inspect!("a".is_empty(), content="false")
}

///|
test "is_blank" {
  inspect!("".is_blank(), content="true")
  inspect!(" ".is_blank(), content="true")
  inspect!("\n".is_blank(), content="true")
  inspect!("\r".is_blank(), content="true")
  inspect!("\t".is_blank(), content="true")
  inspect!("a".is_blank(), content="false")
}

///|
test "index_of" {
  inspect!("abc".index_of("a"), content="0")
  inspect!("abc".index_of("b"), content="1")
  inspect!("abc".index_of("c"), content="2")
  inspect!("abc".index_of("ab"), content="0")
  inspect!("abc".index_of("bc"), content="1")
  inspect!("abc".index_of(""), content="0")
  inspect!("abc".index_of("d"), content="-1")
  inspect!("abc".index_of("abcd"), content="-1")
  inspect!("你好月兔".index_of("你"), content="0")
  inspect!("你好月兔".index_of("好"), content="1")
  inspect!("你好月兔".index_of("月"), content="2")
  inspect!("你好月兔".index_of("兔"), content="3")
  inspect!("你好月兔".index_of("日"), content="-1")
  inspect!("😍😭😡".index_of("😍"), content="0")
  inspect!("😍😭😡".index_of("😭"), content="2")
  inspect!("😍😭😡".index_of("😡"), content="4")
  inspect!("😍😭😡".index_of("😎"), content="-1")
  inspect!("".index_of("a"), content="-1")
  inspect!("".index_of(""), content="0")
  inspect!("abc".index_of("b", from=-1), content="1")
  inspect!("abc".index_of("b", from=0), content="1")
  inspect!("abc".index_of("b", from=1), content="1")
  inspect!("abc".index_of("b", from=2), content="-1")
  inspect!("abc".index_of("b", from=3), content="-1")
  inspect!("abc".index_of("b", from=100), content="-1")
}

///|
test "String::index_of empty strings" {
  // Empty string cases
  assert_eq!("".index_of(""), 0)
  assert_eq!("abc".index_of(""), 0)
  assert_eq!("".index_of("a"), -1)
}

///|
test "String::index_of basic matching" {
  // Basic substring matching
  assert_eq!("abc".index_of("a"), 0)
  assert_eq!("abc".index_of("b"), 1)
  assert_eq!("abc".index_of("c"), 2)
  assert_eq!("abc".index_of("ab"), 0)
  assert_eq!("abc".index_of("bc"), 1)
  assert_eq!("abc".index_of("abc"), 0)
  assert_eq!("abc".index_of("d"), -1)
  assert_eq!("abc".index_of("abcd"), -1)
}

///|
test "String::index_of with from parameter" {
  // Testing from parameter
  assert_eq!("abcabc".index_of("a", from=1), 3)
  assert_eq!("abcabc".index_of("a", from=4), -1)
  assert_eq!("abcabc".index_of("bc", from=2), 4)
  assert_eq!("abc".index_of("", from=1), 1)
  assert_eq!("abc".index_of("", from=3), 3)
  assert_eq!("abc".index_of("", from=4), 3) // Bounded to length
}

///|
test "String::index_of with negative from" {
  // Testing negative from parameter
  assert_eq!("abc".index_of("a", from=-1), 0)
  assert_eq!("abc".index_of("b", from=-2), 1)
}

///|
test "String::index_of overlapping patterns" {
  // Testing overlapping patterns
  assert_eq!("aaa".index_of("aa"), 0)
  assert_eq!("aaa".index_of("aa", from=1), 1)
}

///|
test "last_index_of" {
  inspect!("abc".last_index_of("a"), content="0")
  inspect!("abc".last_index_of("b"), content="1")
  inspect!("abc".last_index_of("c"), content="2")
  inspect!("abc".last_index_of("d"), content="-1")
  inspect!("abc".last_index_of(""), content="3")
  inspect!("abcabc".last_index_of("ab"), content="3")
  inspect!("abcabc".last_index_of("ca"), content="2")
  inspect!("abcabc".last_index_of("cb"), content="-1")
  inspect!("abcabc".last_index_of("d"), content="-1")
  inspect!("abcabc".last_index_of(""), content="6")
  inspect!("你好月兔你好月兔".last_index_of("你"), content="4")
  inspect!("你好月兔你好月兔".last_index_of("好"), content="5")
  inspect!("你好月兔你好月兔".last_index_of("月"), content="6")
  inspect!("你好月兔你好月兔".last_index_of("兔"), content="7")
  inspect!("你好月兔你好月兔".last_index_of("日"), content="-1")
  inspect!("😍😭😡😍😭😡".last_index_of("😍"), content="6")
  inspect!("😍😭😡😍😭😡".last_index_of("😭"), content="8")
  inspect!("😍😭😡😍😭😡".last_index_of("😡"), content="10")
  inspect!("😍😭😡😍😭😡".last_index_of("😎"), content="-1")
  inspect!("".last_index_of("a"), content="-1")
  inspect!("".last_index_of(""), content="0")
  inspect!("abc".last_index_of("b", from=-1), content="-1")
  inspect!("abc".last_index_of("b", from=0), content="-1")
  inspect!("abc".last_index_of("b", from=1), content="-1")
  inspect!("abc".last_index_of("b", from=2), content="1")
  inspect!("abc".last_index_of("b", from=3), content="1")
  inspect!("abc".last_index_of("b", from=100), content="1")
}

///|
test "starts_with" {
  inspect!("abc".starts_with("a"), content="true")
  inspect!("abc".starts_with("ab"), content="true")
  inspect!("abc".starts_with("abc"), content="true")
  inspect!("abc".starts_with("abcd"), content="false")
  inspect!("abc".starts_with("b"), content="false")
  inspect!("abc".starts_with(""), content="true")
  inspect!("你好月兔".starts_with("你好"), content="true")
  inspect!("你好月兔".starts_with("月兔"), content="false")
  inspect!("😍😭😡".starts_with("😍"), content="true")
  inspect!("😍😭😡".starts_with("😭"), content="false")
  inspect!("".starts_with(""), content="true")
  inspect!("".starts_with("a"), content="false")
}

///|
test "ends_with" {
  inspect!("abc".ends_with("c"), content="true")
  inspect!("abc".ends_with("bc"), content="true")
  inspect!("abc".ends_with("abc"), content="true")
  inspect!("abc".ends_with("d"), content="false")
  inspect!("abc".ends_with("ab"), content="false")
  inspect!("abc".ends_with("abcd"), content="false")
  inspect!("abc".ends_with(""), content="true")
  inspect!("你好月兔".ends_with("你好"), content="false")
  inspect!("你好月兔".ends_with("月兔"), content="true")
  inspect!("😍😭😡".ends_with("😭"), content="false")
  inspect!("😍😭😡".ends_with("😡"), content="true")
  inspect!("".ends_with(""), content="true")
  inspect!("".ends_with("a"), content="false")
}

///|
test "split" {
  inspect!(
    "a,b,c,d,e".split(","),
    content=
      #|["a", "b", "c", "d", "e"]
    ,
  )
  inspect!(
    "abcde".split(""),
    content=
      #|["a", "b", "c", "d", "e"]
    ,
  )
  inspect!(
    "a b c d e".split(" "),
    content=
      #|["a", "b", "c", "d", "e"]
    ,
  )
  inspect!(
    "abcde".split("x"),
    content=
      #|["abcde"]
    ,
  )
  inspect!("".split(""), content="[]")
  inspect!("".split("x"), content="[]")
  inspect!(
    "你 wow 好 wow 月 wow 兔".split(" wow "),
    content=
      #|["你", "好", "月", "兔"]
    ,
  )
  inspect!(
    "👍😍😭👍😍😭👍😍😭👍".split("😍😭"),
    content=
      #|["👍", "👍", "👍", "👍"]
    ,
  )
}

///|
test "replace" {
  inspect!("abcabc".replace(old="b", new="x"), content="axcabc")
  inspect!("abcabc".replace(old="", new=","), content=",abcabc")
  inspect!("a b c".replace(old=" ", new=","), content="a,b c")
  inspect!("abcabc".replace(old="x", new="a"), content="abcabc")
  inspect!(
    "你好月兔".replace(old="月兔", new="Moonbit"),
    content="你好Moonbit",
  )
  inspect!("👍😍😭".replace(old="😍😭", new=""), content="👍")
}

///|
test "replace_all" {
  inspect!("abcabc".replace_all(old="b", new="x"), content="axcaxc")
  inspect!("abcabc".replace_all(old="", new=","), content=",a,b,c,a,b,c,")
  inspect!("a b c".replace_all(old=" ", new=","), content="a,b,c")
  inspect!("".replace_all(old="", new="x"), content="x")
  inspect!(
    "你好月兔，月兔你好".replace_all(old="月兔", new="Moonbit"),
    content="你好Moonbit，Moonbit你好",
  )
  inspect!(
    "👍😍😭👍😍😭👍😍😭👍".replace_all(
      old="😍😭",
      new="",
    ),
    content="👍👍👍👍",
  )
}

///|
test "reverse" {
  inspect!("hello".rev(), content="olleh")
  inspect!("Nothing".rev(), content="gnihtoN")
  inspect!("< >".rev(), content="> <")
  inspect!("👍😍😭".rev(), content="😭😍👍")
}

///|
test "to_lower" {
  inspect!("ABCXYZ".to_lower(), content="abcxyz")
  inspect!("aBcXyZ".to_lower(), content="abcxyz")
  inspect!("".to_lower(), content="")
  inspect!(" ".to_lower(), content=" ")
  inspect!("月兔".to_lower(), content="月兔")
}

///|
test "to_upper" {
  inspect!("abcxyz".to_upper(), content="ABCXYZ")
  inspect!("AbCxYz".to_upper(), content="ABCXYZ")
  inspect!("".to_upper(), content="")
  inspect!(" ".to_upper(), content=" ")
  inspect!("月兔".to_upper(), content="月兔")
}

///|
test "split" {
  inspect!(
    "a b c d e".split(" "),
    content=
      #|["a", "b", "c", "d", "e"]
    ,
  )
  inspect!(
    "abcde".split("x"),
    content=
      #|["abcde"]
    ,
  )
  inspect!("".split(""), content="[]")
  inspect!("".split("x"), content="[]")
  inspect!(
    "你 wow 好 wow 月 wow 兔".split(" wow "),
    content=
      #|["你", "好", "月", "兔"]
    ,
  )
  inspect!(
    "👍😍😭👍😍😭👍😍😭👍".split("😍😭"),
    content=
      #|["👍", "👍", "👍", "👍"]
    ,
  )
  // Additional test cases
  inspect!(
    "a,b,c,d,e".split(","),
    content=
      #|["a", "b", "c", "d", "e"]
    ,
  )
  inspect!(
    "a,,b,,c".split(","),
    content=
      #|["a", "", "b", "", "c"]
    ,
  )
  inspect!(
    "a,,b,,c".split(",,"),
    content=
      #|["a", "b", "c"]
    ,
  )
  inspect!(
    "a b c d e".split(""),
    content=
      #|["a", " ", "b", " ", "c", " ", "d", " ", "e"]
    ,
  )
  inspect!(
    "a b c d e".split(" "),
    content=
      #|["a", "b", "c", "d", "e"]
    ,
  )
}

///|
test "String::fold" {
  let s = "this is a long string"
  inspect!(s.fold(init=0, fn(acc, c) { acc + c.to_int() }), content="1980")
  inspect!(
    s.fold(init=@list.Nil, @list.add) |> @list.rev(),
    content="@list.of(['t', 'h', 'i', 's', ' ', 'i', 's', ' ', 'a', ' ', 'l', 'o', 'n', 'g', ' ', 's', 't', 'r', 'i', 'n', 'g'])",
  )
  inspect!(
    s.rev_fold(init=@list.Nil, @list.add),
    content="@list.of(['t', 'h', 'i', 's', ' ', 'i', 's', ' ', 'a', ' ', 'l', 'o', 'n', 'g', ' ', 's', 't', 'r', 'i', 'n', 'g'])",
  )
}

///|
test "String::repeat" {
  inspect!("abc".repeat(3), content="abcabcabc")
  inspect!("".repeat(3), content="")
  inspect!("a".repeat(0), content="")
  inspect!("a".repeat(1), content="a")
  inspect!("a".repeat(2), content="aa")
  inspect!("a".repeat(3), content="aaa")
  inspect!("a".repeat(4), content="aaaa")
  inspect!("a".repeat(5), content="aaaaa")
}

///|
test "pad_left" {
  inspect!("2".pad_start(3, '0'), content="002")
  inspect!("22".pad_start(2, '0'), content="22")
  inspect!("5".pad_start(4, 'x'), content="xxx5")
}

///|
test "pad_right" {
  inspect!("2".pad_end(3, 'x'), content="2xx")
  inspect!("22".pad_end(2, '0'), content="22")
  inspect!("5".pad_end(4, 'x'), content="5xxx")
}

///|
test "panic rev_get1" {
  let str = "Hello🤣🤣🤣"
  let _ = str.rev_get(-1)

}

///|
test "panic rev_get2" {
  let str = "Hello🤣🤣🤣"
  let _ = str.rev_get(8)

}

///|
test "length_ge" {
  let str = "Hello🤣🤣🤣"
  assert_true!(str.length_ge(0))
  assert_true!(str.length_ge(8))
  assert_false!(str.length_ge(9))
}

///|
test "length_eq" {
  let str = "Hello🤣🤣🤣"
  assert_true!(str.length_eq(8))
  assert_false!(str.length_eq(9))
}

///|
test "string pattern matching" {
  enum Token {
    True
    False
    Other
  } derive(Show)
  fn process_string(s : String) {
    match s {
      [.. "true", ..] => True
      [.. "false", ..] => False
      _ => Other
    }
  }

  inspect!(process_string("truexx"), content="True")
  // more tests
  inspect!(process_string("false xx"), content="False")
  inspect!(process_string("true"), content="True")
  inspect!(process_string(""), content="Other")
}

///|
test "offset_of_nth_char" {
  let s = "a😭b😂c"
  inspect!(s.offset_of_nth_char(0), content="Some(0)")
  inspect!(s.offset_of_nth_char(1), content="Some(1)")
  inspect!(s.offset_of_nth_char(2), content="Some(3)")
  inspect!(s.offset_of_nth_char(3), content="Some(4)")
  inspect!(s.offset_of_nth_char(4), content="Some(6)")
  inspect!(s.offset_of_nth_char(5), content="None")
  inspect!(s.offset_of_nth_char(-1), content="Some(6)")
  inspect!(s.offset_of_nth_char(-2), content="Some(4)")
  inspect!(s.offset_of_nth_char(-3), content="Some(3)")
  inspect!(s.offset_of_nth_char(-4), content="Some(1)")
  inspect!(s.offset_of_nth_char(-5), content="Some(0)")
  inspect!(s.offset_of_nth_char(-6), content="None")
}

///|
test "offset_of_nth_char range" {
  let s = "a😭b😂c"
  inspect!(
    s.offset_of_nth_char(0, start_offset=1, end_offset=6),
    content="Some(1)",
  )
  inspect!(
    s.offset_of_nth_char(1, start_offset=1, end_offset=6),
    content="Some(3)",
  )
  inspect!(
    s.offset_of_nth_char(2, start_offset=1, end_offset=6),
    content="Some(4)",
  )
  inspect!(
    s.offset_of_nth_char(3, start_offset=1, end_offset=6),
    content="None",
  )
  inspect!(
    s.offset_of_nth_char(4, start_offset=1, end_offset=6),
    content="None",
  )
  inspect!(
    s.offset_of_nth_char(-1, start_offset=1, end_offset=6),
    content="Some(4)",
  )
  inspect!(
    s.offset_of_nth_char(-2, start_offset=1, end_offset=6),
    content="Some(3)",
  )
  inspect!(
    s.offset_of_nth_char(-3, start_offset=1, end_offset=6),
    content="Some(1)",
  )
  inspect!(
    s.offset_of_nth_char(-4, start_offset=1, end_offset=6),
    content="None",
  )
  inspect!(
    s.offset_of_nth_char(-5, start_offset=1, end_offset=6),
    content="None",
  )
}

///|
test "offset_of_nth_char property" {
  let s = "a😭b😂c"
  let n = s.codepoint_length()
  for i in 0..<n {
    let index = s.offset_of_nth_char(i).unwrap()
    assert_eq!(s.unsafe_char_at(index), s.iter().nth(i).unwrap())
  }
}

///|
test "offset_of_nth_char property negative" {
  let s = "a😭b😂c"
  let n = s.codepoint_length()
  for i in 1..=n {
    let index = s.offset_of_nth_char(-i).unwrap()
    assert_eq!(s.unsafe_char_at(index), s.rev_iter().nth(i - 1).unwrap())
  }
}
