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
/// cursor is relative to `data`: it starts at `0` and remains in the range
/// `0..=data.length()`. A `StringView` slice is therefore a valid input, and
/// scanning it does not read outside the slice.
///
/// ```mbt nocheck
/// let scanner = @lexbuf.StringScanner::{ data: "hello 42"[:], cursor: 0, }
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
  mut cursor : Int
}
