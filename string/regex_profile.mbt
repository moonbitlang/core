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
let word_set : @re.RecharSet = @re.RecharSet::char_range('a', 'z') +
  @re.RecharSet::char_range('A', 'Z') +
  @re.RecharSet::char_range('0', '9') +
  @re.RecharSet::char('_')

///|
let re_profile_unicode : @re.Profile = @re.Profile(
  valid=@re.RecharSet::char_range(0, 0x10FFFF) -
    @re.RecharSet::char_range(0xD800, 0xDFFF),
  word=word_set,
  category=c => {
    match c {
      'a'..='z' | 'A'..='Z' | '0'..='9' | '_' => @re.Category::word()
      '\n' => @re.Category::newline() + @re.Category::not_word()
      _ => @re.Category::not_word()
    }
  },
)

///|
let re_profile_utf16 : @re.Profile = @re.Profile(
  valid=@re.RecharSet::char_range(0, 0xFFFF),
  word=re_profile_unicode.word,
  word_symbolize_splits=[
    word_set,
    // Keep high/low surrogate halves in distinct symbols so \b/\B does not
    // evaluate on a merged symbol class across a surrogate-pair boundary.
    @re.RecharSet::char_range(0xD800, 0xDBFF),
    @re.RecharSet::char_range(0xDC00, 0xDFFF),
  ],
  category=c => {
    match c {
      0xD800..=0xDBFF => @re.Category::not_word_start()
      0xDC00..=0xDFFF => @re.Category::not_word_end()
      _ => (re_profile_unicode.category)(c)
    }
  },
)
