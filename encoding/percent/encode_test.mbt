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
test "unreserved characters are copied through" {
  let unreserved = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~"
  inspect(@percent.encode(unreserved) == unreserved, content="true")
  inspect(@percent.encode(""), content="")
}

///|
test "every other ASCII character escapes with uppercase hex" {
  let builder = StringBuilder()
  for code in 0..<128 {
    let ch = code.unsafe_to_char()
    let encoded = @percent.encode(ch.to_string())
    if ch is ('A'..='Z' | 'a'..='z' | '0'..='9' | '-' | '.' | '_' | '~') {
      assert_eq(encoded, ch.to_string())
    } else {
      assert_eq(encoded.length(), 3)
      assert_eq(encoded[0], '%')
      builder.write_string(encoded)
    }
  }
  inspect(
    builder.to_string(),
    content=(
      #|%00%01%02%03%04%05%06%07%08%09%0A%0B%0C%0D%0E%0F%10%11%12%13%14%15%16%17%18%19%1A%1B%1C%1D%1E%1F%20%21%22%23%24%25%26%27%28%29%2A%2B%2C%2F%3A%3B%3C%3D%3E%3F%40%5B%5C%5D%5E%60%7B%7C%7D%7F
    ),
  )
}

///|
test "space is %20 and reserved delimiters are escaped" {
  inspect(@percent.encode("a b"), content="a%20b")
  inspect(@percent.encode("a+b/c?d#e&f=g"), content="a%2Bb%2Fc%3Fd%23e%26f%3Dg")
  inspect(@percent.encode("100%"), content="100%25")
  // Stricter than JavaScript's encodeURIComponent, which keeps `!*'()`.
  inspect(@percent.encode("!'()*"), content="%21%27%28%29%2A")
}

///|
test "non-ASCII text is UTF-8 encoded" {
  inspect(@percent.encode("é"), content="%C3%A9")
  inspect(
    @percent.encode("中文🌙"),
    content="%E4%B8%AD%E6%96%87%F0%9F%8C%99",
  )
  inspect(@percent.encode("\u{7F}\u{80}"), content="%7F%C2%80")
  inspect(@percent.encode("\u{7FF}\u{800}"), content="%DF%BF%E0%A0%80")
  inspect(@percent.encode("\u{D7FF}\u{E000}"), content="%ED%9F%BF%EE%80%80")
  inspect(@percent.encode("\u{FFFF}\u{10000}"), content="%EF%BF%BF%F0%90%80%80")
  inspect(@percent.encode("\u{10FFFF}"), content="%F4%8F%BF%BF")
  inspect(@percent.encode("\u{FEFF}x"), content="%EF%BB%BFx")
  inspect(@percent.encode("\u{0}"), content="%00")
}

///|
test "unpaired surrogates encode as U+FFFD" {
  let high = (0xD800).unsafe_to_char()
  let low = (0xDC00).unsafe_to_char()
  inspect(@percent.encode(String::from_array([high])), content="%EF%BF%BD")
  inspect(@percent.encode(String::from_array([low])), content="%EF%BF%BD")
  // Reversed order is two unpaired surrogates, not a pair.
  inspect(
    @percent.encode(String::from_array([low, high])),
    content="%EF%BF%BD%EF%BF%BD",
  )
  inspect(
    @percent.encode(String::from_array([high, high, low])),
    content="%EF%BF%BD%F0%90%80%80",
  )
  inspect(
    @percent.encode(String::from_array([high, 'A', low, 'b'])),
    content="%EF%BF%BDA%EF%BF%BDb",
  )
  // A high surrogate at the end of the view has nothing to pair with.
  let text = String::from_array([high, low])
  inspect(@percent.encode(text.view(end_offset=1)), content="%EF%BF%BD")
  inspect(@percent.encode(text), content="%F0%90%80%80")
}

///|
test "views with a nonzero offset" {
  let text = "xx中 y"
  inspect(@percent.encode(text[2:]), content="%E4%B8%AD%20y")
  inspect(@percent.encode(text[2:3]), content="%E4%B8%AD")
  inspect(@percent.encode(text[3:4]), content="%20")
}

///|
test "long alternating literal and escaped spans" {
  let builder = StringBuilder()
  let expected = StringBuilder()
  for i in 0..<300 {
    builder.write_string("ab")
    expected.write_string("ab")
    if i % 2 == 0 {
      builder.write_string(" ")
      expected.write_string("%20")
    } else {
      builder.write_string("é")
      expected.write_string("%C3%A9")
    }
  }
  assert_eq(@percent.encode(builder.to_string()), expected.to_string())
}
