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
/// Reads the next line, without its line terminator. Lines end with `"\n"`;
/// a `"\r"` just before it is removed too, so `"\r\n"` input gives the same
/// lines. The last line need not end with a terminator. Returns `None` once
/// all input has been consumed.
///
/// Lines may span any number of chunks. Line reading mixes freely with
/// `lexscan` over the same lexbuf, for example to skip a header line before
/// scanning tokens, or to take the rest of a line after a scanned prefix.
///
/// ```mbt check
/// test {
///   let chunks = ["first\r", "\nsecond"].iter()
///   let input = @lexbuf.Lexbuf::from_fn(() => chunks.next())
///   let lines = []
///   while input.read_line() is Some(line) {
///     lines.push(line.to_owned())
///   }
///   debug_inspect(lines, content="[\"first\", \"second\"]")
/// }
/// ```
pub fn Lexbuf::read_line(self : Lexbuf) -> StringView? {
  lexscan self {
    // CRLF must precede LF to win equal-length matches and exclude the CR.
    (re"^[^\n]*" as line) + re"\r\n" => Some(line)
    (re"^[^\n]*" as line) + re"\n" => Some(line)
    re"^[^\n]+" as line => Some(line)
    _ => None
  }
}

///|
/// Reads the next line, without its line terminator, or returns `None` once
/// all input has been consumed. See `Lexbuf::read_line`.
///
/// If the source raises an error or the read is cancelled, the lexbuf may be
/// left partway through the line: do not read from it again.
pub async fn AsyncLexbuf::read_line(self : AsyncLexbuf) -> StringView? {
  lexscan self {
    // CRLF must precede LF to win equal-length matches and exclude the CR.
    (re"^[^\n]*" as line) + re"\r\n" => Some(line)
    (re"^[^\n]*" as line) + re"\n" => Some(line)
    re"^[^\n]+" as line => Some(line)
    _ => None
  }
}
