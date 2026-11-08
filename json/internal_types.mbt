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
priv struct ParseContext {
  /// Scans `input`: `sc.data` is `input`, and `sc.cursor` is the offset of
  /// the next code unit to read. The hot token lexers use `lexscan sc`, which
  /// advances the cursor without slicing the input; the rest of the lexer
  /// reads and writes `sc.cursor` directly.
  sc : @lexbuf.StringScanner
  input : StringView
  end_offset : Int32
  reject_duplicate_keys : Bool
  preserve_number_repr : Bool
}

///|
fn ParseContext::make(
  input : StringView,
  reject_duplicate_keys~ : Bool = false,
  preserve_number_repr~ : Bool = false,
) -> ParseContext {
  {
    sc: { data: input, cursor: 0, },
    input,
    end_offset: input.length(),
    reject_duplicate_keys,
    preserve_number_repr,
  }
}

///|
priv enum Token {
  Null
  True
  False
  Number(Double, String?)
  String(String)
  LBrace
  RBrace
  LBracket
  RBracket
  Comma
  // Colon
}
