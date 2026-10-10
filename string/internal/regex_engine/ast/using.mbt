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
pub using @shared_ast {
  type Assertion,
  type Pattern,
  type PatternDesc,
  type Quantifier,
  alt,
  assertion,
  capture,
  char,
  empty,
  end_of_input,
  end_of_line,
  end_of_word,
  epsilon,
  first,
  longest,
  not_word_boundary,
  preference,
  quantifier,
  seq,
  shortest,
  start_of_input,
  start_of_line,
  start_of_word,
}
