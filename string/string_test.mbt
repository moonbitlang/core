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

test "default" {
  inspect!(@string.default())
}

test "compare" {
  @test.eq!(0, "".compare(""))
  @test.eq!(-1, "".compare("abc"))
  @test.eq!(1, "abc".compare(""))
  @test.eq!(-1, "abcd".compare("abce"))
  @test.eq!(1, "abce".compare("abcd"))
  @test.eq!(-1, "c".compare("ab"))
  @test.eq!(1, "ab".compare("c"))
}

test "to_bytes" {
  @test.eq!("中文".to_bytes().to_string(), "中文")
  @test.eq!("asdf".to_bytes().to_string(), "asdf")
  @test.eq!("🤣🤣".to_bytes().to_string(), "🤣🤣")
  @test.eq!("🤔".to_bytes().to_string(), "🤔")
}

test "Show::output" {
  fn repr(s : String) {
    let buf = Buffer::new(size_hint=0)
    s |> Show::output(buf)
    buf.to_string()
  }

  @test.eq!(repr("a"), "\"a\"")
  @test.eq!(repr("'"), "\"'\"")
  @test.eq!(repr("\""), "\"\\\"\"")
  @test.eq!(repr("\\"), "\"\\\\\"")
  @test.eq!(repr("\n"), "\"\\n\"")
  @test.eq!(repr("\r"), "\"\\r\"")
  @test.eq!(repr("\b"), "\"\\b\"")
  @test.eq!(repr("\t"), "\"\\t\"")
  @test.eq!(repr("\x00"), "\"\\x00\"")
  @test.eq!(repr("abc'\"def\\"), "\"abc'\\\"def\\\\\"")
}

test "to_array" {
  let a = "你好！mbt😀".to_array()
  inspect!(a[0], content="'你'")
  inspect!(a[1], content="'好'")
  inspect!(a[2], content="'！'")
  inspect!(a[3], content="'m'")
  inspect!(a[4], content="'b'")
  inspect!(a[5], content="'t'")
  inspect!(a[6], content="'😀'")
}

test "substring" {
  @test.eq!("abc".substring(), "abc")
  @test.eq!("abc".substring(start=1), "bc")
  @test.eq!("abc".substring(end=2), "ab")
  @test.eq!("abc".substring(start=1, end=2), "b")
}

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

// test here to avlid cyclic dependency between assertion and builtin
test "Buffer::to_bytes" {
  let buffer = Buffer::new(size_hint=16)
  buffer.write_string("中文")
  @test.eq!(buffer.to_bytes().to_string(), "中文")
}

test "panic substring_start_index_error" {
  "test".substring(start=-1, end=0) |> ignore
}

test "panic substring_end_index_error" {
  "test".substring(start=0, end=-1) |> ignore
}

test "panic substring_start_end_index_error" {
  "test".substring(start=1, end=0) |> ignore
}

test "panic substring_length_index_error" {
  "test".substring(start=0, end=5) |> ignore
}

test "trim_left" {
  inspect!("aaabcd".trim_left("a"), content="bcd")
  inspect!("aaabcd".trim_left(" "), content="aaabcd")
  inspect!("aaabcd".trim_left(""), content="aaabcd")
  inspect!("  abc".trim_left(" "), content="abc")
  inspect!(
    "哇你好月兔你好哇".trim_left("你好哇"),
    content="月兔你好哇",
  )
  inspect!("😍😍😭😡😡".trim_left("😍"), content="😭😡😡")
}

test "trim_right" {
  inspect!("abcddd".trim_right("d"), content="abc")
  inspect!("abcddd".trim_right(" "), content="abcddd")
  inspect!("abcddd".trim_right(""), content="abcddd")
  inspect!("abc  ".trim_right(" "), content="abc")
  inspect!(
    "哇你好月兔你好哇".trim_right("你好哇"),
    content="哇你好月兔",
  )
  inspect!("😍😍😭😡😡".trim_right("😡"), content="😍😍😭")
}

test "trim" {
  inspect!("xxxabcxxx".trim("x"), content="abc")
  inspect!("xxxabcxxx".trim(""), content="xxxabcxxx")
  inspect!("哇你好月兔你好哇".trim("你好哇"), content="月兔")
  inspect!("\n\r\t abc \n\r\t".trim(" \n\r\t"), content="abc")
  inspect!("=-wow-=".trim("-="), content="wow")
  inspect!("😍😍😭😡😡".trim("😍😡"), content="😭")
}

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

test "is_empty" {
  inspect!("".is_empty(), content="true")
  inspect!(" ".is_empty(), content="false")
  inspect!("\n".is_empty(), content="false")
  inspect!("\r".is_empty(), content="false")
  inspect!("\t".is_empty(), content="false")
  inspect!("a".is_empty(), content="false")
}

test "is_blank" {
  inspect!("".is_blank(), content="true")
  inspect!(" ".is_blank(), content="true")
  inspect!("\n".is_blank(), content="true")
  inspect!("\r".is_blank(), content="true")
  inspect!("\t".is_blank(), content="true")
  inspect!("a".is_blank(), content="false")
}

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

test "to_lower" {
  inspect!("ABCXYZ".to_lower(), content="abcxyz")
  inspect!("aBcXyZ".to_lower(), content="abcxyz")
  inspect!("".to_lower(), content="")
  inspect!(" ".to_lower(), content=" ")
  inspect!("月兔".to_lower(), content="月兔")
}

test "to_upper" {
  inspect!("abcxyz".to_upper(), content="ABCXYZ")
  inspect!("AbCxYz".to_upper(), content="ABCXYZ")
  inspect!("".to_upper(), content="")
  inspect!(" ".to_upper(), content=" ")
  inspect!("月兔".to_upper(), content="月兔")
}

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