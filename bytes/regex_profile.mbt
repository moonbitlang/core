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

///|
let re_profile : @re.Profile = @re.Profile::new(
  valid=@re.RecharSet::char_range(0, 255),
  word=@re.RecharSet::char_range('a', 'z') +
    @re.RecharSet::char_range('A', 'Z') +
    @re.RecharSet::char_range('0', '9') +
    @re.RecharSet::char('_'),
  space=@re.RecharSet::char(' ') +
    @re.RecharSet::char('\t') +
    @re.RecharSet::char('\n') +
    @re.RecharSet::char('\r') +
    @re.RecharSet::char('\u{000B}') +
    @re.RecharSet::char('\f'),
  digit=@re.RecharSet::char_range('0', '9'),
  line_terminator=@re.RecharSet::char('\n'),
  case_insensitive=cs => cs +
    (cs & @re.RecharSet::char_range('A', 'Z')).offset_by(it => it + 32) +
    (cs & @re.RecharSet::char_range('a', 'z')).offset_by(it => it - 32),
  category=c => match c {
    'a'..='z' | 'A'..='Z' | '0'..='9' | '_' => @re.Category::word()
    '\n' => @re.Category::newline()
    _ => @re.Category::not_word()
  },
)
