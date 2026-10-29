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
fn content(pattern : String, input : Bytes) -> Bytes? {
  let re = try! @bytes.BytesRegex(pattern)
  re.execute(input).map(m => m.content().to_owned())
}

///|
test "BytesRegex: any byte" {
  debug_inspect(
    content("a.c", b"a\xffc"),
    content=(
      #|Some(<Bytes: [0x61, 0xff, 0x63]>)
    ),
  )
  debug_inspect(
    content("a.c", b"a\x00c"),
    content=(
      #|Some(<Bytes: [0x61, 0x00, 0x63]>)
    ),
  )
  debug_inspect(
    content("a.c", b"a\nc"),
    content=(
      #|Some(<Bytes: [0x61, 0x0a, 0x63]>)
    ),
  )
  debug_inspect(
    content("^.{3}$", b"\xe2\x82\xac"),
    content=(
      #|Some(<Bytes: [0xe2, 0x82, 0xac]>)
    ),
  )
}

///|
test "BytesRegex: byte escapes and high bytes in classes" {
  debug_inspect(
    content("[\\x80-\\xbf]+", b"a\xe2\x82\xacb"),
    content=(
      #|Some(<Bytes: [0x82, 0xac]>)
    ),
  )
  debug_inspect(
    content("[^a]", b"a\x80"),
    content=(
      #|Some(<Bytes: [0x80]>)
    ),
  )
  debug_inspect(
    content("[^[:word:]]", b"ab\xe9"),
    content=(
      #|Some(<Bytes: [0xe9]>)
    ),
  )
  debug_inspect(content("[^\\x00-\\x7f]+", b"abc"), content="None")
  // Input need not be UTF-8.
  debug_inspect(
    content("\\xff\\xfe", b"\x00\xff\xfe"),
    content=(
      #|Some(<Bytes: [0xff, 0xfe]>)
    ),
  )
}

///|
test "BytesRegex: ASCII-only case folding and word boundaries" {
  // `\xc9` and `\xe9` are `É` and `é` in Latin-1, but only ASCII folds.
  debug_inspect(content("(?i:\\xc9)", b"\xe9"), content="None")
  debug_inspect(
    content("(?i:abc)", b"xAbC"),
    content=(
      #|Some(<Bytes: [0x41, 0x62, 0x43]>)
    ),
  )
  // A byte above `0x7F` is not a word byte.
  debug_inspect(
    content("a\\b", b"a\xe9"),
    content=(
      #|Some(<Bytes: [0x61]>)
    ),
  )
  debug_inspect(
    content("\\b\\xe9", b"a\xe9"),
    content=(
      #|Some(<Bytes: [0xe9]>)
    ),
  )
  debug_inspect(
    content("\\B\\xe9", b"\xe9\xe9"),
    content=(
      #|Some(<Bytes: [0xe9]>)
    ),
  )
}

///|
test "BytesRegex: last_index keeps anchors and look-behind" {
  let re = @bytes.BytesRegex("\\bb")
  debug_inspect(re.execute(b"ab", last_index=1) is Some(_), content="false")
  debug_inspect(re.execute(b" b", last_index=1) is Some(_), content="true")
  let re = @bytes.BytesRegex("^b")
  debug_inspect(re.execute(b"ab", last_index=1) is Some(_), content="false")
}

///|
test "BytesRegex: groups are views of the searched view" {
  let data = b"xx key=\xffvalue yy"
  let input = data[3:]
  let re = @bytes.BytesRegex("(?<key>[[:alpha:]]+)=(?<value>[^ ]*)|(z)")
  guard re.execute(input) is Some(m) else { fail("expected a match") }
  debug_inspect(
    m.before().to_owned(),
    content=(
      #|<Bytes: []>
    ),
  )
  debug_inspect(
    m.content().to_owned(),
    content=(
      #|<Bytes: [0x6b, 0x65, 0x79, 0x3d, 0xff, 0x76, 0x61, 0x6c, 0x75, 0x65]>
    ),
  )
  debug_inspect(
    m.after().to_owned(),
    content=(
      #|<Bytes: [0x20, 0x79, 0x79]>
    ),
  )
  debug_inspect(
    m.named_group("key").map(g => g.to_owned()),
    content=(
      #|Some(<Bytes: [0x6b, 0x65, 0x79]>)
    ),
  )
  debug_inspect(
    m.named_group("value").map(g => g.start_offset() - input.start_offset()),
    content="Some(4)",
  )
  debug_inspect(m.group(3), content="None")
  debug_inspect(m.group(4), content="None")
  debug_inspect(m.named_group("missing"), content="None")
}

///|
test "BytesRegex: pattern errors" {
  let cases = [
    "caf\u{e9}", "\\u00e9", "[\\u{e9}]", "\\x4", "a{3,1}", "(a", "[z-a]",
  ]
  let errors = cases.map(pattern => {
    try @bytes.BytesRegex(pattern) catch {
      e => "\{e}"
    } noraise {
      _ => "ok"
    }
  })
  debug_inspect(
    errors,
    content=(
      #|[
      #|  "ParserError at position 3: Non-ASCII characters are not allowed in a bytes pattern, use \\xHH for a byte",
      #|  "ParserError at position 0: Unicode escape sequences are not allowed in a bytes pattern, use \\xHH for a byte",
      #|  "ParserError at position 1: Unicode escape sequences are not allowed in a bytes pattern, use \\xHH for a byte",
      #|  "ParserError at position 0: Invalid escape sequence",
      #|  "ParserError at position 1: Invalid quantifier",
      #|  "ParserError at position 0: Unclosed group",
      #|  "ParserError at position 1: Invalid character class range",
      #|]
    ),
  )
}

///|
test "BytesRegex: Debug" {
  debug_inspect(
    @bytes.BytesRegex("a|\\xff"),
    content=(
      #|<BytesRegex:
      #|  Alternation(<ReadOnlyArray: [Char([(97, 97)]), Char([(255, 255)])]>)>
    ),
  )
}
