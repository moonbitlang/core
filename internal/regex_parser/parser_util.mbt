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
  let mut value = 0
  for c in hex {
    value = value * 16
    match c {
      '0'..='9' => value = value + (c.to_int() - '0'.to_int())
      'a'..='f' => value = value + (c.to_int() - 'a'.to_int() + 10)
      'A'..='F' => value = value + (c.to_int() - 'A'.to_int() + 10)
      _ => panic()
    }
  }
  value
}

///|
fn pattern_map_char(pat : Pattern, f : (RecharSet) -> RecharSet) -> Pattern {
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
fn ignore_case(cs : RecharSet) -> RecharSet {
  cs +
  (cs & @re.RecharSet::char_range('A', 'Z')).offset_by(it => it + 32) +
  (cs & @re.RecharSet::char_range('a', 'z')).offset_by(it => it - 32)
}

///|
let posix_cset_ascii : RecharSet = RecharSet::char_range(0, 0x7f)

///|
let posix_cset_upper : RecharSet = RecharSet::char_range('A', 'Z')

///|
let posix_cset_lower : RecharSet = RecharSet::char_range('a', 'z')

///|
let posix_cset_alpha : RecharSet = posix_cset_upper + posix_cset_lower

///|
let posix_cset_digit : RecharSet = RecharSet::char_range('0', '9')

///|
let posix_cset_xdigit : RecharSet = posix_cset_digit +
  RecharSet::char_range('a', 'f') +
  RecharSet::char_range('A', 'F')

///|
let posix_cset_alnum : RecharSet = posix_cset_alpha + posix_cset_digit

///|
let posix_cset_space : RecharSet = RecharSet::char(' ') +
  RecharSet::char('\t') +
  RecharSet::char('\n') +
  RecharSet::char('\r') +
  RecharSet::char('\u{000B}') +
  RecharSet::char('\f')

///|
let posix_cset_blank : RecharSet = RecharSet::char(' ') + RecharSet::char('\t')
