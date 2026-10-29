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
fn hex2i(hex : StringView) -> Int32 {
  for c in hex; value = 0 {
    let value = value * 16
    match c {
      '0'..<='9' => continue value + (c.to_int() - '0')
      'a'..<='f' => continue value + (c.to_int() - 'a' + 10)
      'A'..<='F' => continue value + (c.to_int() - 'A' + 10)
      _ => panic()
    }
  } nobreak {
    value
  }
}

///|
fn pattern_map_char(
  pat : @re.Pattern,
  f : (@re.ByteSet) -> @re.ByteSet,
) -> @re.Pattern {
  match pat.desc {
    Capture(name~, pat) => @re.capture(name?, pattern_map_char(pat, f))
    Quantifier(quant, pat) => @re.quantifier(pattern_map_char(pat, f), quant)
    Alternation(pats) => @re.alt(pats.map(p => pattern_map_char(p, f)))
    Sequence(pats) => @re.seq(pats.map(p => pattern_map_char(p, f)))
    Char(c) => @re.char(f(c))
    Assertion(a) => @re.assertion(a)
  }
}

///|
fn ignore_case(cs : @re.ByteSet) -> @re.ByteSet {
  cs +
  (cs & @re.ByteSet::char_range('A', 'Z')).offset_by(it => it + 32) +
  (cs & @re.ByteSet::char_range('a', 'z')).offset_by(it => it - 32)
}

///|
/// Every byte, the meaning of `.` and the complement of `[^...]`.
let cset_any : @re.ByteSet = @re.ByteSet::full()

///|
let posix_cset_ascii : @re.ByteSet = @re.ByteSet::char_range(0, 0x7f)

///|
let posix_cset_upper : @re.ByteSet = @re.ByteSet::char_range('A', 'Z')

///|
let posix_cset_lower : @re.ByteSet = @re.ByteSet::char_range('a', 'z')

///|
let posix_cset_alpha : @re.ByteSet = posix_cset_upper + posix_cset_lower

///|
let posix_cset_digit : @re.ByteSet = @re.ByteSet::char_range('0', '9')

///|
let posix_cset_xdigit : @re.ByteSet = posix_cset_digit +
  @re.ByteSet::char_range('a', 'f') +
  @re.ByteSet::char_range('A', 'F')

///|
let posix_cset_alnum : @re.ByteSet = posix_cset_alpha + posix_cset_digit

///|
let posix_cset_space : @re.ByteSet = @re.ByteSet::char(' ') +
  @re.ByteSet::char('\t') +
  @re.ByteSet::char('\n') +
  @re.ByteSet::char('\r') +
  @re.ByteSet::char('\u{000B}') +
  @re.ByteSet::char('\f')

///|
let posix_cset_blank : @re.ByteSet = @re.ByteSet::char(' ') +
  @re.ByteSet::char('\t')
