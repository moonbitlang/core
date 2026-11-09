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
/// A type that `lexscan` can scan in place: it holds a `StringView` input and
/// a cursor into it.
///
/// Implement it to make your own type a non-streaming `lexscan` target, like
/// `StringScanner`, without wrapping the cursor in a separate scanner object.
/// A parser can then keep its cursor in its own context and use it both in
/// `lexscan` and in hand-written loops.
///
/// Offsets are UTF-16 code units. The cursor is relative to the input.
///
/// Each `lexscan` over such a value calls each method exactly once:
/// `scan_input` and `scan_cursor` when it starts, and `set_scan_cursor` before
/// the body of the selected case runs. It passes the end of the match, which
/// equals the starting cursor for an empty match, or the starting cursor
/// itself when `_` is selected. A body that scans the same value again
/// therefore sees the new cursor. The input must not change while `lexscan`
/// runs. `lexscan` aborts if the cursor it reads is outside
/// `0..=input.length()` or inside a surrogate pair, so a wrong implementation
/// cannot make it read outside the input or split a character.
///
/// ```mbt nocheck
/// struct Parser {
///   input : StringView
///   mut offset : Int32
/// }
///
/// impl @lexbuf.Scannable for Parser with fn scan_input(self) {
///   self.input
/// }
///
/// impl @lexbuf.Scannable for Parser with fn scan_cursor(self) {
///   self.offset
/// }
///
/// impl @lexbuf.Scannable for Parser with fn set_scan_cursor(self, cursor) {
///   self.offset = cursor
/// }
///
/// fn Parser::word(self : Parser) -> StringView? {
///   lexscan self {
///     re"^[a-z]+" as word => Some(word)
///     _ => None
///   }
/// }
/// ```
pub(open) trait Scannable {
  /// The input to scan. Its indexes use UTF-16 code units.
  fn scan_input(Self) -> StringView
  /// The offset of the next code unit to scan, relative to `scan_input`.
  fn scan_cursor(Self) -> Int32
  /// Moves the cursor to `cursor`, relative to `scan_input`. `lexscan` only
  /// passes the end of a match or the starting cursor, which are in range and
  /// at a character boundary.
  fn set_scan_cursor(Self, Int32) -> Unit
}

///|
/// The bytes counterpart of `Scannable`: a type that `lexscan` can scan in
/// place with bytes regexes, holding a `BytesView` input and a cursor into it.
///
/// Offsets are bytes. The cursor is relative to the input.
///
/// Each `lexscan` over such a value calls each method exactly once, as for
/// `Scannable`: `scan_input` and `scan_cursor` when it starts, and
/// `set_scan_cursor` before the body of the selected case runs, with the end
/// of the match or, when `_` is selected, the starting cursor. The input must
/// not change while `lexscan` runs. `lexscan` aborts if the cursor it reads is
/// outside `0..=input.length()`, so a wrong implementation cannot make it read
/// outside the input.
pub(open) trait BytesScannable {
  /// The input to scan. Its indexes are byte offsets.
  fn scan_input(Self) -> BytesView
  /// The offset of the next byte to scan, relative to `scan_input`.
  fn scan_cursor(Self) -> Int32
  /// Moves the cursor to `cursor`, relative to `scan_input`. `lexscan` only
  /// passes the end of a match or the starting cursor, which are in range.
  fn set_scan_cursor(Self, Int32) -> Unit
}

///|
/// `StringScanner` is `Scannable`, so generic code over `Scannable` accepts
/// it. `lexscan` on a `StringScanner` does not go through these methods.
pub impl Scannable for StringScanner with fn scan_input(self) {
  self.data
}

///|
pub impl Scannable for StringScanner with fn scan_cursor(self) {
  self.cursor
}

///|
/// Moves the cursor to `cursor`, relative to `data`.
///
/// # Panics
///
/// - If `cursor` is outside `0..=data.length()`.
/// - If `cursor` is inside a surrogate pair of `data`.
pub impl Scannable for StringScanner with fn set_scan_cursor(self, cursor) {
  guard cursor >= 0 && cursor <= self.data.length() else {
    abort("StringScanner: cursor is out of range")
  }
  guard cursor == self.data.length() ||
    !self.data.unsafe_get(cursor).is_trailing_surrogate() else {
    abort("StringScanner: cursor is inside a surrogate pair")
  }
  self.cursor = cursor
}

///|
/// `BytesScanner` is `BytesScannable`, so generic code over `BytesScannable`
/// accepts it. `lexscan` on a `BytesScanner` does not go through these
/// methods.
pub impl BytesScannable for BytesScanner with fn scan_input(self) {
  self.data
}

///|
pub impl BytesScannable for BytesScanner with fn scan_cursor(self) {
  self.cursor
}

///|
/// Moves the cursor to `cursor`, relative to `data`.
///
/// # Panics
///
/// - If `cursor` is outside `0..=data.length()`.
pub impl BytesScannable for BytesScanner with fn set_scan_cursor(self, cursor) {
  guard cursor >= 0 && cursor <= self.data.length() else {
    abort("BytesScanner: cursor is out of range")
  }
  self.cursor = cursor
}

///|
/// The trait methods are not methods of the scanners: call them through the
/// trait.
#deprecated("Call through `@lexbuf.Scannable`", skip_current_package=true)
#doc(hidden)
pub extend StringScanner with Scannable::{
  scan_input,
  scan_cursor,
  set_scan_cursor,
}

///|
#deprecated("Call through `@lexbuf.BytesScannable`", skip_current_package=true)
#doc(hidden)
pub extend BytesScanner with BytesScannable::{
  scan_input,
  scan_cursor,
  set_scan_cursor,
}

///|
/// Compiler protocol: returns `cursor` after checking that it is a valid
/// starting point in `input`. Generated `lexscan` code calls it on the cursor
/// of a `Scannable` value before reading the input.
///
/// # Panics
///
/// - If `cursor` is outside `0..=input.length()`.
/// - If `cursor` is inside a surrogate pair of `input`.
#doc(hidden)
pub fn __check_scan_cursor(input : StringView, cursor : Int32) -> Int32 {
  guard cursor >= 0 && cursor <= input.length() else {
    abort("lexscan: cursor is out of range")
  }
  guard cursor == input.length() ||
    !input.unsafe_get(cursor).is_trailing_surrogate() else {
    abort("lexscan: cursor is inside a surrogate pair")
  }
  cursor
}

///|
/// Compiler protocol: returns `cursor` after checking that it is in
/// `0..=input.length()`. Generated `lexscan` code calls it on the cursor of a
/// `BytesScannable` value before reading the input.
///
/// # Panics
///
/// - If `cursor` is outside `0..=input.length()`.
#doc(hidden)
pub fn __check_bytes_scan_cursor(input : BytesView, cursor : Int32) -> Int32 {
  guard cursor >= 0 && cursor <= input.length() else {
    abort("lexscan: cursor is out of range")
  }
  cursor
}
