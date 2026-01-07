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
test "String::from_array" {
  inspect(String::from_array(['1', '2', '3', '4', '5']), content="12345")
}

///|
test "String::from_iter" {
  inspect(String::from_iter(['1', '2', '3', '4', '5'].iter()), content="12345")
}

///|
test "default" {
  inspect(String::default())
}

///|
test "compare" {
  assert_eq(0, "".compare(""))
  assert_eq(-1, "".compare("abc"))
  assert_eq(1, "abc".compare(""))
  assert_eq(-1, "abcd".compare("abce"))
  assert_eq(1, "abce".compare("abcd"))
  assert_eq(-1, "c".compare("ab"))
  assert_eq(1, "ab".compare("c"))
}

///|
test "lexical_compare" {
  // Test equal strings
  inspect("abc".lexical_compare("abc"), content="0")
  inspect("".lexical_compare(""), content="0")

  // Test lexicographically less than
  inspect("abc".lexical_compare("abd"), content="-1")
  inspect("ab".lexical_compare("abc"), content="-1")
  inspect("".lexical_compare("a"), content="-1")

  // Test lexicographically greater than
  inspect("abd".lexical_compare("abc"), content="1")
  inspect("abc".lexical_compare("ab"), content="1")
  inspect("a".lexical_compare(""), content="1")

  // Test different lengths with same prefix - Java behavior
  // In lexicographical comparison, "ab" < "abc" (shorter string is less when it's a prefix)
  inspect("ab".lexical_compare("abc"), content="-1")
  inspect("abc".lexical_compare("ab"), content="1")

  // Test case sensitivity
  inspect("ABC".lexical_compare("abc"), content="-1") // uppercase letters have lower code points
  inspect("abc".lexical_compare("ABC"), content="1")

  // Test with numbers
  inspect("123".lexical_compare("124"), content="-1")
  inspect("124".lexical_compare("123"), content="1")
  inspect("9".lexical_compare("10"), content="1") // '9' > '1' in lexicographical order

  // Test with surrogate pairs (emoji)
  inspect("🤣".lexical_compare("😭"), content="1")
  inspect("😭".lexical_compare("🤣"), content="-1")
  inspect("🤣".lexical_compare("🤣"), content="0")

  // Test mixed ASCII and emoji
  inspect("a🤣".lexical_compare("a😭"), content="1")
  inspect("abc🤣".lexical_compare("abc"), content="1")
  inspect("abc".lexical_compare("abc🤣"), content="-1")

  // Test comparing common prefixes with different suffixes
  inspect("testing".lexical_compare("tested"), content="1")
  inspect("tested".lexical_compare("testing"), content="-1")

  // Test comparison with special characters
  inspect("hello!".lexical_compare("hello?"), content="-1") // '!' < '?'
  inspect("hello world".lexical_compare("hello-world"), content="-1") // ' ' < '-'

  // Test with whitespace
  inspect(" abc".lexical_compare("abc"), content="-1") // space < 'a'
  inspect("abc ".lexical_compare("abc"), content="1")

  // Test longer strings
  inspect("abcdefghijklm".lexical_compare("abcdefghijkln"), content="-1")
  inspect("abcdefghijkln".lexical_compare("abcdefghijklm"), content="1")

  // Test strings that differ only at the end
  inspect("prefix_a".lexical_compare("prefix_b"), content="-1")
  inspect("prefix_b".lexical_compare("prefix_a"), content="1")
}

///|
test "Show::output" {
  fn repr(s : String) {
    let buf = StringBuilder::new(size_hint=0)
    s |> Show::output(buf)
    buf.to_string()
  }

  assert_eq(repr("a"), "\"a\"")
  assert_eq(repr("'"), "\"'\"")
  assert_eq(repr("\""), "\"\\\"\"")
  assert_eq(repr("\\"), "\"\\\\\"")
  assert_eq(repr("\n"), "\"\\n\"")
  assert_eq(repr("\r"), "\"\\r\"")
  assert_eq(repr("\b"), "\"\\b\"")
  assert_eq(repr("\t"), "\"\\t\"")
  inspect(
    repr("\u{00}"),
    content=(
      #|"\u{00}"
    ),
  )
  inspect(
    repr("\u0000"),
    content=(
      #|"\u{00}"
    ),
  )
  assert_eq(repr("abc'\"def\\"), "\"abc'\\\"def\\\\\"")
}

///|
test "to_array" {
  let a = "你好！mbt😀".to_array()
  inspect(a[0], content="你")
  inspect(a[1], content="好")
  inspect(a[2], content="！")
  inspect(a[3], content="m")
  inspect(a[4], content="b")
  inspect(a[5], content="t")
  inspect(a[6], content="😀")
}

///|
test "chars" {
  let mut str = ""
  "A😊𠮷BA😊𠮷B"
  .iter()
  .each(c => str = str + c.to_int().to_string() + "\n")
  inspect(
    str,
    content=(
      #|65
      #|128522
      #|134071
      #|66
      #|65
      #|128522
      #|134071
      #|66
      #|
    ),
  )
  inspect(
    "A😊𠮷BA😊𠮷B".iter().take(2).collect(),
    content="['A', '😊']",
  )
  inspect(
    "A😊𠮷BA😊𠮷B".iter().take(4).collect(),
    content="['A', '😊', '𠮷', 'B']",
  )
}

///|
test "rev_iter" {
  let mut str = ""
  "A😊𠮷BA😊𠮷B"
  .rev_iter()
  .each(c => str = str + c.to_int().to_string() + "\n")
  inspect(
    str,
    content=(
      #|66
      #|134071
      #|128522
      #|65
      #|66
      #|134071
      #|128522
      #|65
      #|
    ),
  )
  inspect(
    "A😊𠮷BA😊𠮷B".rev_iter().take(2).collect(),
    content="['B', '𠮷']",
  )
  inspect(
    "A😊𠮷BA😊𠮷B".rev_iter().take(4).collect(),
    content="['B', '𠮷', '😊', 'A']",
  )
}

///|
test "iter2" {
  let mut str = ""
  "A😊𠮷BA😊𠮷B"
  .iter2()
  .each((i, c) => str = str + "\{i}: \{c.to_int()} \n")
  inspect(
    str,
    content=(
      #|0: 65 
      #|1: 128522 
      #|2: 134071 
      #|3: 66 
      #|4: 65 
      #|5: 128522 
      #|6: 134071 
      #|7: 66 
      #|
    ),
  )
}

// test here to avlid cyclic dependency between assertion and builtin

///|
test "Buffer::to_bytes" {
  let buffer = StringBuilder::new(size_hint=16)
  buffer.write_string("中文")
  assert_eq(buffer.to_string(), "中文")
}

///|
test "trim_start" {
  inspect("aaabcd".trim_start(chars="a"), content="bcd")
  inspect("aaabcd".trim_start(chars=" "), content="aaabcd")
  inspect("aaabcd".trim_start(chars=""), content="aaabcd")
  inspect("  abc".trim_start(chars=" "), content="abc")
  inspect(
    "哇你好月兔你好哇".trim_start(chars="你好哇"),
    content="月兔你好哇",
  )
  inspect(
    "😍😍😭😡😡".trim_start(chars="😍"),
    content="😭😡😡",
  )
}

///|
test "contains" {
  @json.inspect("abc".contains("a"), content=true)
  @json.inspect("中文".contains("文"), content=true)
  @json.inspect("中文".contains("中"), content=true)
  @json.inspect("中文".contains("a"), content=false)
}

///|
test "trim_end" {
  inspect("abcddd".trim_end(chars="d"), content="abc")
  inspect("abcddd".trim_end(chars=" "), content="abcddd")
  inspect("abcddd".trim_end(chars=""), content="abcddd")
  inspect("abc  ".trim_end(chars=" "), content="abc")
  inspect(
    "哇你好月兔你好哇".trim_end(chars="你好哇"),
    content="哇你好月兔",
  )
  inspect("😍😍😭😡😡".trim_end(chars="😡"), content="😍😍😭")
}

///|
test "trim" {
  inspect("xxxabcxxx".trim(chars="x"), content="abc")
  inspect("xxxabcxxx".trim(chars=""), content="xxxabcxxx")
  inspect("哇你好月兔你好哇".trim(chars="你好哇"), content="月兔")
  inspect("\n\r\t abc \n\r\t".trim(chars=" \n\r\t"), content="abc")
  inspect("=-wow-=".trim(chars="-="), content="wow")
  inspect("😍😍😭😡😡".trim(chars="😍😡"), content="😭")
}

///|
test "trim whitespace" {
  inspect(" abc ".trim(), content="abc")
  inspect("abc ".trim(), content="abc")
  inspect(" abc".trim(), content="abc")
  inspect("\nabc\n".trim(), content="abc")
  inspect("\tabc\t".trim(), content="abc")
  inspect("\rabc\r".trim(), content="abc")
  inspect("abc".trim(), content="abc")
  inspect("".trim(), content="")
  inspect("  ".trim(), content="")
  inspect("\n\n".trim(), content="")
  inspect("\t\t".trim(), content="")
  inspect("\r\r".trim(), content="")
}

///|
test "is_empty" {
  inspect("".is_empty(), content="true")
  inspect(" ".is_empty(), content="false")
  inspect("\n".is_empty(), content="false")
  inspect("\r".is_empty(), content="false")
  inspect("\t".is_empty(), content="false")
  inspect("a".is_empty(), content="false")
}

///|
test "is_blank" {
  inspect("".is_blank(), content="true")
  inspect(" ".is_blank(), content="true")
  inspect("\n".is_blank(), content="true")
  inspect("\r".is_blank(), content="true")
  inspect("\t".is_blank(), content="true")
  inspect("a".is_blank(), content="false")
}

///|
test "index_of" {
  inspect("abc".find("a"), content="Some(0)")
  inspect("abc".find("b"), content="Some(1)")
  inspect("abc".find("c"), content="Some(2)")
  inspect("abc".find("ab"), content="Some(0)")
  inspect("abc".find("bc"), content="Some(1)")
  inspect("abc".find(""), content="Some(0)")
  inspect("abc".find("d"), content="None")
  inspect("abc".find("abcd"), content="None")
  inspect("你好月兔".find("你"), content="Some(0)")
  inspect("你好月兔".find("好"), content="Some(1)")
  inspect("你好月兔".find("月"), content="Some(2)")
  inspect("你好月兔".find("兔"), content="Some(3)")
  inspect("你好月兔".find("日"), content="None")
  inspect("😍😭😡".find("😍"), content="Some(0)")
  inspect("😍😭😡".find("😭"), content="Some(2)")
  inspect("😍😭😡".find("😡"), content="Some(4)")
  inspect("😍😭😡".find("😎"), content="None")
  inspect("".find("a"), content="None")
  inspect("".find(""), content="Some(0)")
}

///|
test "String::index_of empty strings" {
  // Empty string cases
  inspect("".find(""), content="Some(0)")
  inspect("abc".find(""), content="Some(0)")
  inspect("".find("a"), content="None")
}

///|
test "String::index_of basic matching" {
  // Basic substring matching
  inspect("abc".find("a"), content="Some(0)")
  inspect("abc".find("b"), content="Some(1)")
  inspect("abc".find("c"), content="Some(2)")
  inspect("abc".find("ab"), content="Some(0)")
  inspect("abc".find("bc"), content="Some(1)")
  inspect("abc".find("abc"), content="Some(0)")
  inspect("abc".find("d"), content="None")
  inspect("abc".find("abcd"), content="None")
}

///|
test "String::index_of overlapping patterns" {
  // Testing overlapping patterns
  inspect("aaa".find("aa"), content="Some(0)")
  inspect("aaa"[1:].find("aa"), content="Some(0)")
}

///|
test "last_index_of" {
  inspect("abc".rev_find("a"), content="Some(0)")
  inspect("abc".rev_find("b"), content="Some(1)")
  inspect("abc".rev_find("c"), content="Some(2)")
  inspect("abc".rev_find("d"), content="None")
  inspect("abc".rev_find(""), content="Some(3)")
  inspect("abcabc".rev_find("ab"), content="Some(3)")
  inspect("abcabc".rev_find("ca"), content="Some(2)")
  inspect("abcabc".rev_find("cb"), content="None")
  inspect("abcabc".rev_find("d"), content="None")
  inspect("abcabc".rev_find(""), content="Some(6)")
  inspect("你好月兔你好月兔".rev_find("你"), content="Some(4)")
  inspect("你好月兔你好月兔".rev_find("好"), content="Some(5)")
  inspect("你好月兔你好月兔".rev_find("月"), content="Some(6)")
  inspect("你好月兔你好月兔".rev_find("兔"), content="Some(7)")
  inspect("你好月兔你好月兔".rev_find("日"), content="None")
  inspect("😍😭😡😍😭😡".rev_find("😍"), content="Some(6)")
  inspect("😍😭😡😍😭😡".rev_find("😭"), content="Some(8)")
  inspect("😍😭😡😍😭😡".rev_find("😡"), content="Some(10)")
  inspect("😍😭😡😍😭😡".rev_find("😎"), content="None")
  inspect("".rev_find("a"), content="None")
  inspect("".rev_find(""), content="Some(0)")
}

///|
test "has_prefix" {
  inspect("abc".has_prefix("a"), content="true")
  inspect("abc".has_prefix("ab"), content="true")
  inspect("abc".has_prefix("abc"), content="true")
  inspect("abc".has_prefix("abcd"), content="false")
  inspect("abc".has_prefix("b"), content="false")
  inspect("abc".has_prefix(""), content="true")
  inspect("你好月兔".has_prefix("你好"), content="true")
  inspect("你好月兔".has_prefix("月兔"), content="false")
  inspect("😍😭😡".has_prefix("😍"), content="true")
  inspect("😍😭😡".has_prefix("😭"), content="false")
  inspect("".has_prefix(""), content="true")
  inspect("".has_prefix("a"), content="false")
}

///|
test "has_suffix" {
  inspect("abc".has_suffix("c"), content="true")
  inspect("abc".has_suffix("bc"), content="true")
  inspect("abc".has_suffix("abc"), content="true")
  inspect("abc".has_suffix("d"), content="false")
  inspect("abc".has_suffix("ab"), content="false")
  inspect("abc".has_suffix("abcd"), content="false")
  inspect("abc".has_suffix(""), content="true")
  inspect("你好月兔".has_suffix("你好"), content="false")
  inspect("你好月兔".has_suffix("月兔"), content="true")
  inspect("😍😭😡".has_suffix("😭"), content="false")
  inspect("😍😭😡".has_suffix("😡"), content="true")
  inspect("".has_suffix(""), content="true")
  inspect("".has_suffix("a"), content="false")
}

///|
test "replace" {
  inspect("abcabc".replace(old="b", new="x"), content="axcabc")
  inspect("abcabc".replace(old="", new=","), content=",abcabc")
  inspect("a b c".replace(old=" ", new=","), content="a,b c")
  inspect("abcabc".replace(old="x", new="a"), content="abcabc")
  inspect(
    "你好月兔".replace(old="月兔", new="Moonbit"),
    content="你好Moonbit",
  )
  inspect("👍😍😭".replace(old="😍😭", new=""), content="👍")
}

///|
test "replace_all" {
  inspect("abcabc".replace_all(old="b", new="x"), content="axcaxc")
  inspect("abcabc".replace_all(old="", new=","), content=",a,b,c,a,b,c,")
  inspect("a b c".replace_all(old=" ", new=","), content="a,b,c")
  inspect("".replace_all(old="", new="x"), content="x")
  inspect(
    "你好月兔，月兔你好".replace_all(old="月兔", new="Moonbit"),
    content="你好Moonbit，Moonbit你好",
  )
  inspect(
    "👍😍😭👍😍😭👍😍😭👍".replace_all(
      old="😍😭",
      new="",
    ),
    content="👍👍👍👍",
  )
}

///|
test "reverse" {
  inspect("hello".rev(), content="olleh")
  inspect("Nothing".rev(), content="gnihtoN")
  inspect("< >".rev(), content="> <")
  inspect("👍😍😭".rev(), content="😭😍👍")
}

///|
test "to_lower" {
  inspect("ABCXYZ".to_lower(), content="abcxyz")
  inspect("aBcXyZ".to_lower(), content="abcxyz")
  inspect("".to_lower(), content="")
  inspect(" ".to_lower(), content=" ")
  inspect("月兔".to_lower(), content="月兔")
}

///|
test "to_upper" {
  inspect("abcxyz".to_upper(), content="ABCXYZ")
  inspect("AbCxYz".to_upper(), content="ABCXYZ")
  inspect("".to_upper(), content="")
  inspect(" ".to_upper(), content=" ")
  inspect("月兔".to_upper(), content="月兔")
}

///|
test "split" {
  inspect(
    "a b c d e".split(" "),
    content=(
      #|["a", "b", "c", "d", "e"]
    ),
  )
  inspect(
    "abcde".split("x"),
    content=(
      #|["abcde"]
    ),
  )
  inspect("".split(""), content="[]")
  inspect(
    "".split("x"),
    content=(
      #|[""]
    ),
  )
  inspect(
    "你 wow 好 wow 月 wow 兔".split(" wow "),
    content=(
      #|["你", "好", "月", "兔"]
    ),
  )
  inspect(
    "👍😍😭👍😍😭👍😍😭👍".split("😍😭"),
    content=(
      #|["👍", "👍", "👍", "👍"]
    ),
  )
  // Additional test cases
  inspect(
    "a,b,c,d,e".split(","),
    content=(
      #|["a", "b", "c", "d", "e"]
    ),
  )
  inspect(
    "a,,b,,c".split(","),
    content=(
      #|["a", "", "b", "", "c"]
    ),
  )
  inspect(
    "a,,b,,c".split(",,"),
    content=(
      #|["a", "b", "c"]
    ),
  )
  inspect(
    "a b c d e".split(""),
    content=(
      #|["a", " ", "b", " ", "c", " ", "d", " ", "e"]
    ),
  )
  inspect(
    "a,b,c,d,e".split(","),
    content=(
      #|["a", "b", "c", "d", "e"]
    ),
  )
  inspect(
    "abcde".split(""),
    content=(
      #|["a", "b", "c", "d", "e"]
    ),
  )
  inspect(
    "a b c d e".split(" "),
    content=(
      #|["a", "b", "c", "d", "e"]
    ),
  )
  inspect(
    "abcde".split("x"),
    content=(
      #|["abcde"]
    ),
  )
  inspect("".split(""), content="[]")
  inspect(
    "".split("x"),
    content=(
      #|[""]
    ),
  )
}

///|
test "String::fold" {
  let s = "this is a long string"
  inspect(s.fold(init=0, (acc, c) => acc + c.to_int()), content="1980")
  inspect(
    s.fold(init=@list.empty(), _.prepend(_)).rev(),
    content="@list.from_array(['t', 'h', 'i', 's', ' ', 'i', 's', ' ', 'a', ' ', 'l', 'o', 'n', 'g', ' ', 's', 't', 'r', 'i', 'n', 'g'])",
  )
  inspect(
    s.rev_fold(init=@list.empty(), _.prepend(_)),
    content="@list.from_array(['t', 'h', 'i', 's', ' ', 'i', 's', ' ', 'a', ' ', 'l', 'o', 'n', 'g', ' ', 's', 't', 'r', 'i', 'n', 'g'])",
  )
}

///|
test "String::repeat" {
  inspect("abc".repeat(3), content="abcabcabc")
  inspect("".repeat(3), content="")
  inspect("a".repeat(0), content="")
  inspect("a".repeat(1), content="a")
  inspect("a".repeat(2), content="aa")
  inspect("a".repeat(3), content="aaa")
  inspect("a".repeat(4), content="aaaa")
  inspect("a".repeat(5), content="aaaaa")
}

///|
test "pad_left" {
  inspect("2".pad_start(3, '0'), content="002")
  inspect("22".pad_start(2, '0'), content="22")
  inspect("5".pad_start(4, 'x'), content="xxx5")
}

///|
test "pad_right" {
  inspect("2".pad_end(3, 'x'), content="2xx")
  inspect("22".pad_end(2, '0'), content="22")
  inspect("5".pad_end(4, 'x'), content="5xxx")
}

///|
// test "panic rev_get1" {
//   let str = "Hello🤣🤣🤣"
//   let _ = str.rev_iter().nth(-1).unwrap()

// }

///|
test "panic rev_get2" {
  let str = "Hello🤣🤣🤣"
  let _ = str.rev_iter().nth(8).unwrap()

}

///|
test "length_ge" {
  let str = "Hello🤣🤣🤣"
  assert_true(str.char_length_ge(0))
  assert_true(str.char_length_ge(8))
  assert_false(str.char_length_ge(9))
}

///|
test "length_eq" {
  let str = "Hello🤣🤣🤣"
  assert_true(str.char_length_eq(8))
  assert_false(str.char_length_eq(9))
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

  inspect(process_string("truexx"), content="True")
  // more tests
  inspect(process_string("false xx"), content="False")
  inspect(process_string("true"), content="True")
  inspect(process_string(""), content="Other")
}

///|
test "offset_of_nth_char" {
  let s = "a😭b😂c"
  inspect(s.offset_of_nth_char(0), content="Some(0)")
  inspect(s.offset_of_nth_char(1), content="Some(1)")
  inspect(s.offset_of_nth_char(2), content="Some(3)")
  inspect(s.offset_of_nth_char(3), content="Some(4)")
  inspect(s.offset_of_nth_char(4), content="Some(6)")
  inspect(s.offset_of_nth_char(5), content="None")
  inspect(s.offset_of_nth_char(-1), content="Some(6)")
  inspect(s.offset_of_nth_char(-2), content="Some(4)")
  inspect(s.offset_of_nth_char(-3), content="Some(3)")
  inspect(s.offset_of_nth_char(-4), content="Some(1)")
  inspect(s.offset_of_nth_char(-5), content="Some(0)")
  inspect(s.offset_of_nth_char(-6), content="None")
}

///|
test "offset_of_nth_char range" {
  let s = "a😭b😂c"
  inspect(
    s.offset_of_nth_char(0, start_offset=1, end_offset=6),
    content="Some(1)",
  )
  inspect(
    s.offset_of_nth_char(1, start_offset=1, end_offset=6),
    content="Some(3)",
  )
  inspect(
    s.offset_of_nth_char(2, start_offset=1, end_offset=6),
    content="Some(4)",
  )
  inspect(s.offset_of_nth_char(3, start_offset=1, end_offset=6), content="None")
  inspect(s.offset_of_nth_char(4, start_offset=1, end_offset=6), content="None")
  inspect(
    s.offset_of_nth_char(-1, start_offset=1, end_offset=6),
    content="Some(4)",
  )
  inspect(
    s.offset_of_nth_char(-2, start_offset=1, end_offset=6),
    content="Some(3)",
  )
  inspect(
    s.offset_of_nth_char(-3, start_offset=1, end_offset=6),
    content="Some(1)",
  )
  inspect(
    s.offset_of_nth_char(-4, start_offset=1, end_offset=6),
    content="None",
  )
  inspect(
    s.offset_of_nth_char(-5, start_offset=1, end_offset=6),
    content="None",
  )
}

///|
test "offset_of_nth_char property" {
  let s = "a😭b😂c"
  let n = s.char_length()
  for i in 0..<n {
    let index = s.offset_of_nth_char(i).unwrap()
    assert_eq(s.get_char(index).unwrap(), s.iter().nth(i).unwrap())
  }
}

///|
test "offset_of_nth_char property negative" {
  let s = "a😭b😂c"
  let n = s.char_length()
  for i in 1..=n {
    let index = s.offset_of_nth_char(-i).unwrap()
    assert_eq(s.get_char(index).unwrap(), s.rev_iter().nth(i - 1).unwrap())
  }
}

///|
test "split and then join should be identity" {
  let string = ""
  assert_eq(string, string.split("").map(StringView::to_string).join(""))
  assert_eq(string, string.split("a").map(StringView::to_string).join("a"))
  let string = "a,b,c,"
  assert_eq(string, string.split("").map(StringView::to_string).join(""))
  assert_eq(string, string.split(",").map(StringView::to_string).join(","))
  let string = "a b c"
  assert_eq(string, string.split("").map(StringView::to_string).join(""))
  assert_eq(string, string.split(" ").map(StringView::to_string).join(" "))
  let string = "aaaaa"
  assert_eq(string, string.split("").map(StringView::to_string).join(""))
  assert_eq(string, string.split("a").map(StringView::to_string).join("a"))
}

///|
test "string chars array" {
  let v0 : String = ['a', .."x"]
  assert_true(v0 is "ax")
  let v : String = ['a', 'b']
  assert_true(v is "ab")
}

///|
test "gard tail position" {
  let s = "abc"
  guard s is [.., ch]
  assert_eq(ch, 'c') // failed
}

///|
test "guard const" {
  let s = "hello.txt"
  assert_true(s is [.., .. ".txt"])
}

///|
test "string default" {
  inspect(@string.default(), content="")
}
