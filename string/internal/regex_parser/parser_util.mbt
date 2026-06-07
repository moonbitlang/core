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
fn hex2i(hex : StringView) -> Int {
  for c in hex; value = 0 {
    let value = value * 16
    match c {
      '0'..='9' => continue value + (c.to_int() - '0'.to_int())
      'a'..='f' => continue value + (c.to_int() - 'a'.to_int() + 10)
      'A'..='F' => continue value + (c.to_int() - 'A'.to_int() + 10)
      _ => panic()
    }
  } nobreak {
    value
  }
}

///|
fn pattern_map_char(
  pat : @re.Pattern,
  f : (@re.RecharSet) -> @re.RecharSet,
) -> @re.Pattern {
  match pat.desc {
    Capture(name~, pat) => @re.capture(name?, pattern_map_char(pat, f))
    Preference(pref, pat) => @re.preference(pref, pattern_map_char(pat, f))
    Quantifier(quant, pat) => @re.quantifier(pattern_map_char(pat, f), quant)
    Alternation(pats) => @re.alt(pats.map(p => pattern_map_char(p, f)))
    Sequence(pats) => @re.seq(pats.map(p => pattern_map_char(p, f)))
    Char(c) => @re.char(f(c))
    Assertion(a) => @re.assertion(a)
  }
}

///|
fn ignore_case(cs : @re.RecharSet) -> @re.RecharSet {
  cs +
  (cs & @re.RecharSet::char_range('A', 'Z')).offset_by(it => it + 32) +
  (cs & @re.RecharSet::char_range('a', 'z')).offset_by(it => it - 32)
}

///|
let posix_cset_ascii : @re.RecharSet = @re.RecharSet::char_range(0, 0x7f)

///|
let posix_cset_upper : @re.RecharSet = @re.RecharSet::char_range('A', 'Z')

///|
let posix_cset_lower : @re.RecharSet = @re.RecharSet::char_range('a', 'z')

///|
let posix_cset_alpha : @re.RecharSet = posix_cset_upper + posix_cset_lower

///|
let posix_cset_digit : @re.RecharSet = @re.RecharSet::char_range('0', '9')

///|
let posix_cset_xdigit : @re.RecharSet = posix_cset_digit +
  @re.RecharSet::char_range('a', 'f') +
  @re.RecharSet::char_range('A', 'F')

///|
let posix_cset_alnum : @re.RecharSet = posix_cset_alpha + posix_cset_digit

///|
let posix_cset_space : @re.RecharSet = @re.RecharSet::char(' ') +
  @re.RecharSet::char('\t') +
  @re.RecharSet::char('\n') +
  @re.RecharSet::char('\r') +
  @re.RecharSet::char('\u{000B}') +
  @re.RecharSet::char('\f')

///|
let posix_cset_blank : @re.RecharSet = @re.RecharSet::char(' ') +
  @re.RecharSet::char('\t')
