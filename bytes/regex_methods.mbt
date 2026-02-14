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
/// Replaces all non-overlapping matches in `str` using `replacer`.
///
/// The `replacer` callback is called once for each match and receives the
/// corresponding `MatchResult`.
///
/// If `limit` is provided, at most `limit` matches are replaced.
/// When omitted, all matches are replaced.
///
/// Returns `str` unchanged when there is no match.
///
/// If the regex can match an empty string, replacement content is inserted at
/// the beginning, between bytes, and at the end of `str`.
///
/// Example:
///
/// ```mbt check
/// test {
///   let regex = @bytes.BytesRegex("[[:digit:]]+")
///   let result = regex.replace_by(b"a12b3", m => {
///     let buf = @buffer.new()
///     buf.write_byte(b'[')
///     buf.write_bytesview(m.content())
///     buf.write_byte(b']')
///     buf.to_bytes()[:]
///   })
///   inspect(result, content="b\"a[12]b[3]\"")
/// }
/// ```
#internal(experimental, "subject to breaking change without notice")
pub fn BytesRegex::replace_by(
  regex : BytesRegex,
  str : BytesView,
  replacer : (MatchResult) -> BytesView,
  limit? : Int,
) -> BytesView {
  let buf = @buffer.new()
  let mut copy_index = 0
  let mut search_index = 0
  let mut replaced = 0
  while search_index <= str.length() {
    if limit is Some(limit) && replaced >= limit {
      break
    }
    match regex.execute(str, last_index=search_index) {
      None => break
      Some(m) => {
        guard m.result.group(0) is Some((start, end)) else { break }
        buf.write_bytesview(str[copy_index:start])
        buf.write_bytesview(replacer(m))
        copy_index = end
        search_index = if start == end { end + 1 } else { end }
        replaced += 1
      }
    }
  }
  buf.write_bytesview(str[copy_index:])
  buf.to_bytes()[:]
}

///|
/// Returns an iterator over all non-overlapping matches in `str`.
///
/// Matches are produced from left to right.
///
/// If the regex can match an empty string, iteration still terminates: after
/// each empty match, search resumes at the next byte.
///
/// Example:
///
/// ```mbt check
/// test {
///   let regex = @bytes.BytesRegex("[[:digit:]]+")
///   let matches = regex.find(b"a12b3").to_array()
///   inspect(matches.length(), content="2")
///   inspect(matches[0].content(), content="b\"12\"")
///   inspect(matches[1].content(), content="b\"3\"")
/// }
/// ```
#internal(experimental, "subject to breaking change without notice")
pub fn BytesRegex::find(
  regex : BytesRegex,
  str : BytesView,
) -> Iter[MatchResult] {
  let mut search_index = 0
  let len = str.length()
  Iter::new(() => {
    guard search_index <= len else { None }
    match regex.execute(str, last_index=search_index) {
      None => None
      Some(m) => {
        guard m.result.group(0) is Some((start, end)) else { return None }
        search_index = if start == end { end + 1 } else { end }
        Some(m)
      }
    }
  })
}

///|
/// Splits `str` into all segments separated by regex matches.
///
/// If there is no match, the returned iterator yields only `str`.
///
/// Consecutive matches and boundary matches produce empty segments.
///
/// If the regex can match an empty string, the result includes boundary empty
/// segments and per-byte splits.
///
/// Example:
///
/// ```mbt check
/// test {
///   let regex = @bytes.BytesRegex(",")
///   let parts = regex.split(b"a,,b").to_array()
///   inspect(parts.length(), content="3")
///   inspect(parts[0], content="b\"a\"")
///   inspect(parts[1], content="b\"\"")
///   inspect(parts[2], content="b\"b\"")
/// }
/// ```
#internal(experimental, "subject to breaking change without notice")
pub fn BytesRegex::split(
  regex : BytesRegex,
  str : BytesView,
) -> Iter[BytesView] {
  let mut copy_index = 0
  let mut search_index = 0
  let len = str.length()
  let mut done = false
  Iter::new(() => {
    guard !done else { None }
    while search_index <= len {
      match regex.execute(str, last_index=search_index) {
        None => {
          done = true
          return Some(str[copy_index:])
        }
        Some(m) => {
          guard m.result.group(0) is Some((start, end)) else {
            done = true
            return Some(str[copy_index:])
          }
          let part = str[copy_index:start]
          copy_index = end
          search_index = if start == end { end + 1 } else { end }
          return Some(part)
        }
      }
    }
    done = true
    Some(str[copy_index:])
  })
}
