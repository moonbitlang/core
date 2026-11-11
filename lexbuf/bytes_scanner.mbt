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
/// A lightweight scanner for a `BytesView` input, the bytes counterpart of
/// `StringScanner`.
///
/// `BytesScanner` is a non-streaming target for `lexscan` with bytes regexes.
/// Unlike `BytesLexbuf` and `AsyncBytesLexbuf`, it does not refill its input
/// and does not support retention. The generated scanner advances `cursor`
/// after each selected case, so the same value can be passed to successive
/// `lexscan` expressions.
///
/// Both `data` offsets and `cursor` are measured in bytes. The cursor is
/// relative to `data` and in the range `0..=data.length()`. A `BytesView`
/// slice is therefore a valid input, and scanning it does not read outside the
/// slice.
///
/// Create a scanner with `BytesScanner(data)`, which checks that the cursor is
/// in range.
///
/// ```mbt nocheck
/// let scanner = @lexbuf.BytesScanner(b"hello 42")
///
/// let token = lexscan scanner {
///   reb"^[a-z]+" as word => word
///   reb"^ +" => b" "
///   _ => b"?"
/// }
/// ```
pub struct BytesScanner {
  /// The input view to scan. Its indexes are byte offsets.
  data : BytesView
  /// The relative offset of the next byte to scan.
  mut cursor : Int32
}

///|
/// Creates a scanner over `data` that starts at `cursor`, a byte offset
/// relative to `data` (`0` by default).
///
/// # Panics
///
/// - If `cursor` is outside `0..=data.length()`.
///
/// # Example
///
/// ```mbt check
/// test {
///   let scanner = @lexbuf.BytesScanner(b"\xff\x00ab", cursor=2)
///   inspect(scanner.cursor, content="2")
/// }
/// ```
pub fn BytesScanner::BytesScanner(
  data : BytesView,
  cursor~ : Int32 = 0,
) -> BytesScanner {
  guard cursor >= 0 && cursor <= data.length() else {
    abort("BytesScanner: cursor is out of range")
  }
  { data, cursor, }
}

///|
/// Compiler protocol: sets the cursor without checking it. Intended for
/// generated `lexscan` code, which commits the end of a match. The caller must
/// keep `cursor` in `0..=self.data.length()`.
#doc(hidden)
pub fn BytesScanner::__unsafe_set_cursor(
  self : BytesScanner,
  cursor : Int32,
) -> Unit {
  self.cursor = cursor
}
