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
/// The `Malformed` payload of `decode(text)`, or `None` when decoding
/// succeeds.
fn malformed_input(text : StringView) -> StringView? {
  try @percent.decode(text) catch {
    Malformed(input) => Some(input)
  } noraise {
    _ => None
  }
}

///|
test "decode well-formed input" {
  inspect(@percent.decode(""), content="")
  inspect(@percent.decode("plain"), content="plain")
  inspect(
    @percent.decode("Application%20Support"),
    content="Application Support",
  )
  inspect(@percent.decode("%2F%3F%23%26%3D%3A"), content="/?#&=:")
  inspect(@percent.decode("%00"), content="\u{0}")
  inspect(@percent.decode("100%25"), content="100%")
  // Hexadecimal digits in either case.
  inspect(
    @percent.decode("%e4%b8%ad%E6%96%87%F0%9F%8C%99"),
    content="中文🌙",
  )
  // Escapes decode exactly once.
  inspect(@percent.decode("%2520"), content="%20")
  inspect(@percent.decode("a%20b%2520"), content="a b%20")
  // Form encoding is not applied: `+` stays `+`.
  inspect(@percent.decode("a+b%2Bc"), content="a+b+c")
  // A byte order mark is kept, whether escaped or literal.
  inspect(
    @percent.decode("%EF%BB%BFx%EF%BB%BF\u{FEFF}"),
    content="\u{FEFF}x\u{FEFF}\u{FEFF}",
  )
}

///|
test "literal characters pass through beside escapes" {
  inspect(@percent.decode("中文%20🌙"), content="中文 🌙")
  inspect(@percent.decode("é%C3%A9é"), content="ééé")
  // Non-ASCII lookalikes are not hexadecimal digits.
  @debug.debug_inspect(
    malformed_input("%Ａ0"),
    content=(
      #|Some(<StringView: "%Ａ0">)
    ),
  )
  // An escape run ends at a literal character, even mid-sequence.
  @debug.debug_inspect(
    malformed_input("%C3é"),
    content=(
      #|Some(<StringView: "%C3é">)
    ),
  )
}

///|
test "literal unpaired surrogates are preserved" {
  let high = (0xD800).unsafe_to_char()
  let low = (0xDC00).unsafe_to_char()
  for
    text in [
      String::from_array([high]),
      String::from_array([low]),
      String::from_array([low, high]),
      String::from_array([high, high, low]),
      String::from_array([high, low]),
    ] {
    assert_eq(@percent.decode(text), text)
    assert_eq(@percent.decode_lossy(text), text)
    let mixed = String::from_array([high, '%', '2', '0', low])
    let expected = String::from_array([high, ' ', low])
    assert_eq(@percent.decode(mixed), expected)
    assert_eq(@percent.decode_lossy(mixed), expected)
  }
}

///|
test "views with a nonzero offset and a truncated escape at the view end" {
  let text = "xx%20y%41"
  inspect(@percent.decode(text[2:]), content=" yA")
  inspect(@percent.decode(text[2:5]), content=" ")
  // The digit after the view must not be read.
  @debug.debug_inspect(
    malformed_input(text[2:4]),
    content=(
      #|Some(<StringView: "%2">)
    ),
  )
  inspect(@percent.decode_lossy(text[2:4]), content="%2")
  @debug.debug_inspect(
    malformed_input(text[6:8]),
    content=(
      #|Some(<StringView: "%4">)
    ),
  )
}

///|
test "malformed escapes and escaped UTF-8 raise with the whole input" {
  for
    malformed in [
      "%", "%2", "%zz", "%0g", "%g0", "%%41", "%2%41", "%80", "%BF", "%C0%AF", "%C1%BF",
      "%C2", "%C2x%A0", "%E0%80%AF", "%E1%80", "%E1%80%41", "%E2x%82%AC", "%ED%A0%80",
      "%ED%BF%BF", "%E2%82", "%F0%80%80%AF", "%F4%90%80%80", "%F5%80%80%80", "%FF",
    ] {
    // Earlier valid escapes must not leak into the error.
    let input = "prefix%20\{malformed}%20suffix"
    try @percent.decode(input) catch {
      Malformed(reported) => assert_eq(reported, input)
    } noraise {
      decoded => fail("decoded \{input} as \{decoded}")
    }
  }
}

///|
test "Malformed payload and Debug rendering" {
  let text = "ab%zzcd"
  try {
    let _ = @percent.decode(text[1:])
    panic()
  } catch {
    err => {
      @debug.debug_inspect(
        err,
        content=(
          #|Malformed(<StringView: "b%zzcd">)
        ),
      )
      match err {
        Malformed(view) => {
          assert_eq(view.start_offset(), 1)
          assert_eq(view.length(), 6)
        }
      }
    }
  }
}

///|
test "decode_lossy keeps a malformed % and resumes right after it" {
  inspect(@percent.decode_lossy("%"), content="%")
  inspect(@percent.decode_lossy("%2"), content="%2")
  inspect(@percent.decode_lossy("%zz"), content="%zz")
  inspect(@percent.decode_lossy("%%41"), content="%A")
  inspect(@percent.decode_lossy("%2%41"), content="%2A")
  inspect(@percent.decode_lossy("a%20b%zz"), content="a b%zz")
  inspect(@percent.decode_lossy("%41%zz%42"), content="A%zzB")
  inspect(@percent.decode_lossy("100%"), content="100%")
  inspect(@percent.decode_lossy("%%%"), content="%%%")
}

///|
test "decode_lossy replaces invalid escaped UTF-8 with U+FFFD" {
  inspect(@percent.decode_lossy("%80"), content="\u{FFFD}")
  inspect(@percent.decode_lossy("%E1%80"), content="\u{FFFD}")
  inspect(
    @percent.decode_lossy("%ED%A0%80"),
    content="\u{FFFD}\u{FFFD}\u{FFFD}",
  )
  inspect(@percent.decode_lossy("%C0%AF"), content="\u{FFFD}\u{FFFD}")
  inspect(
    @percent.decode_lossy("%F4%90%80%80"),
    content="\u{FFFD}\u{FFFD}\u{FFFD}\u{FFFD}",
  )
  inspect(@percent.decode_lossy("%C3é"), content="\u{FFFD}é")
  inspect(
    @percent.decode_lossy("%E2x%82%AC"),
    content="\u{FFFD}x\u{FFFD}\u{FFFD}",
  )
  inspect(@percent.decode_lossy("%E1%80%41"), content="\u{FFFD}A")
  // Bytes before a malformed escape are still decoded as their own run.
  inspect(@percent.decode_lossy("%C3%A9%zz%C3"), content="é%zz\u{FFFD}")
  inspect(@percent.decode_lossy("%C3%zz%A9"), content="\u{FFFD}%zz\u{FFFD}")
}

///|
test "decode_lossy agrees with decode on well-formed input" {
  for
    text in [
      "", "plain", "Application%20Support", "%e4%b8%ad%E6%96%87%F0%9F%8C%99", "中文%20🌙",
      "a+b%2Bc", "%2520", "%EF%BB%BFx%EF%BB%BF", "%00", "%2F%3F%23%26%3D%3A",
    ] {
    assert_eq(@percent.decode_lossy(text), @percent.decode(text))
  }
}

///|
test "round trip" {
  for
    text in [
      "", "Application Support", "中文🌙", "a+b/c?d#e&f=g", "100%", "\u{0}\u{7F}\u{80}\u{7FF}\u{800}\u{D7FF}\u{E000}\u{FFFF}\u{10000}\u{10FFFF}",
      "\u{FEFF}BOM", "%zz",
    ] {
    assert_eq(@percent.decode(@percent.encode(text)), text)
  }
  for code in 0..<128 {
    let text = code.unsafe_to_char().to_string()
    assert_eq(@percent.decode(@percent.encode(text)), text)
  }
}
