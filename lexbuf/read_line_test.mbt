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
/// Splits `text` at the given UTF-16 offsets, keeping empty chunks.
fn split_at(text : String, cuts : Array[Int32]) -> Array[String] {
  let chunks = []
  let mut start = 0
  for cut in cuts {
    chunks.push(text[start:cut].to_owned())
    start = cut
  }
  chunks.push(text[start:].to_owned())
  chunks
}

///|
/// Returns the UTF-16 offsets of `text` that are not inside a surrogate pair.
fn char_boundaries(text : String) -> Array[Int32] {
  let offsets = [0]
  let mut offset = 0
  for c in text {
    offset += c.utf16_len()
    offsets.push(offset)
  }
  offsets
}

///|
fn source(chunks : Array[String]) -> () -> String? {
  let chunks = chunks.iter()
  () => chunks.next()
}

///|
fn sync_lines(chunks : Array[String]) -> Array[String] raise {
  let input = @lexbuf.Lexbuf::from_fn(source(chunks))
  let lines = []
  while input.read_line() is Some(line) {
    lines.push(line.to_owned())
  }
  lexscan input {
    re"^$" => ()
    _ => fail("expected EOF")
  }
  lines
}

///|
test "Lexbuf::read_line strips terminators and keeps a final unterminated line" {
  debug_inspect(
    sync_lines(["one\n", "two\r\n\nthree"]),
    content=(
      #|["one", "two", "", "three"]
    ),
  )
  debug_inspect(sync_lines(["one\n"]), content="[\"one\"]")
  debug_inspect(sync_lines([]), content="[]")
  debug_inspect(sync_lines(["", "\n", ""]), content="[\"\"]")
  // A lone `\r` is not a line terminator.
  debug_inspect(
    sync_lines(["a\rb\r"]),
    content=(
      #|["a\rb\r"]
    ),
  )
}

///|
test "Lexbuf::read_line gives the same lines for every split of the input" {
  let text = "αβ\r\n😀 x\n\n日本語\r\r\nlast😀"
  let expected = sync_lines([text])
  debug_inspect(
    expected,
    content=(
      #|["αβ", "😀 x", "", "日本語\r", "last😀"]
    ),
  )
  let cuts = char_boundaries(text)
  for i in cuts {
    for j in cuts {
      if i <= j {
        assert_eq(sync_lines(split_at(text, [i, j])), expected)
      }
    }
  }
}

///|
test "Lexbuf::read_line mixes with lexscan over the same lexbuf" {
  let input = @lexbuf.Lexbuf::from_fn(
    source(["# header, ", "skipped\nkey", "=va", "lue\r\nk2=v2"]),
  )
  debug_inspect(
    input.read_line(),
    content=(
      #|Some(<StringView: "# header, skipped">)
    ),
  )
  let pairs = []
  for ;; {
    lexscan input {
      (re"^[a-z0-9]+" as key) + re"=" =>
        pairs.push((key.to_owned(), input.read_line().unwrap().to_owned()))
      re"^$" => break
      _ => fail("expected key=value")
    }
  }
  debug_inspect(
    pairs,
    content=(
      #|[("key", "value"), ("k2", "v2")]
    ),
  )
}

///|
test "Lexbuf::read_line reads lines longer than a chunk from many small chunks" {
  let long = "x".repeat(200) + "😀" + "y".repeat(100)
  let text = "\{long}\r\n\{long}\nz"
  // One chunk per character.
  let cuts = char_boundaries(text)
  let chunks = split_at(text, cuts[1:cuts.length() - 1].to_owned())
  let lines = sync_lines(chunks)
  assert_eq(lines, [long, long, "z"])
}
