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
  mut offset : Int
  input : StringView
  end_offset : Int
  mut remaining_available_depth : Int
}

///|
fn ParseContext::make(
  input : StringView,
  max_nesting_depth : Int,
) -> ParseContext {
  {
    offset: 0,
    input,
    end_offset: input.length(),
    remaining_available_depth: max_nesting_depth,
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
