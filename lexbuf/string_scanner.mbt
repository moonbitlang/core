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
/// A lightweight scanner for a `StringView` input.
///
/// `StringScanner` is a non-streaming target for `lexscan`. Unlike `Lexbuf` and
/// `AsyncLexbuf`, it does not refill its input and does not support retention.
/// The generated scanner advances `cursor` after each selected case, so the
/// same value can be passed to successive `lexscan` expressions.
///
/// Both `data` offsets and `cursor` are measured in UTF-16 code units. The
/// cursor is relative to `data`: it is in the range `0..=data.length()` and
/// never inside a surrogate pair. A `StringView` slice is therefore a valid
/// input, and scanning it does not read outside the slice.
///
/// Create a scanner with `StringScanner(data)`, which checks the cursor.
///
/// ```mbt nocheck
/// let scanner = @lexbuf.StringScanner("hello 42")
///
/// let token = lexscan scanner {
///   re"^[a-z]+" as word => word
///   re"^ +" => " "
///   _ => "?"
/// }
/// ```
pub(all) struct StringScanner {
  /// The input view to scan. Its indexes use UTF-16 code units.
  data : StringView
  /// The relative offset of the next code unit to scan, in UTF-16 code units.
  mut cursor : Int32
}

///|
/// Creates a scanner over `data` that starts at `cursor`, a UTF-16 code-unit
/// offset relative to `data` (`0` by default).
///
/// # Panics
///
/// - If `cursor` is outside `0..=data.length()`.
/// - If `cursor` is inside a surrogate pair of `data`.
///
/// # Example
///
/// ```mbt check
/// test {
///   let scanner = @lexbuf.StringScanner("ab\u{1F600}c", cursor=2)
///   inspect(scanner.cursor, content="2")
/// }
/// ```
pub fn StringScanner::StringScanner(
  data : StringView,
  cursor~ : Int32 = 0,
) -> StringScanner {
  guard cursor >= 0 && cursor <= data.length() else {
    abort("StringScanner: cursor is out of range")
  }
  guard cursor == data.length() ||
    !data.unsafe_get(cursor).is_trailing_surrogate() else {
    abort("StringScanner: cursor is inside a surrogate pair")
  }
  { data, cursor, }
}

///|
/// Compiler protocol: sets the cursor without checking it. Generated `lexscan`
/// code calls this to commit the end of a match, which is always in range and
/// at a character boundary.
#doc(hidden)
pub fn StringScanner::__unsafe_set_cursor(
  self : StringScanner,
  cursor : Int32,
) -> Unit {
  self.cursor = cursor
}
