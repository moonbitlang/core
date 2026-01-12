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
fn re_surrogate_pair(codepoint : Int) -> (Int, Int) {
  let cp = codepoint - 0x10000
  let high = 0xD800 + ((cp >> 10) & 0x3FF)
  let low = 0xDC00 + (cp & 0x3FF)
  (high, low)
}

///|
fn re_lower_cset(cs : @re.RecharSet) -> @re.Pattern {
  let cset1 = cs & @re.RecharSet::char_range(0x0000, 0xFFFF)
  let cset2 = cs & @re.RecharSet::char_range(0x10000, 0x10FFFF)
  let alts = []
  if !cset1.is_empty() {
    alts.push(@re.char(cset1))
  }
  for interval in cset2.intervals() {
    let (lo, hi) = interval
    if lo == hi {
      let pair = re_surrogate_pair(lo)
      alts.push(
        @re.seq([
          @re.char(@re.RecharSet::char(pair.0)),
          @re.char(@re.RecharSet::char(pair.1)),
        ]),
      )
    } else {
      let lo = re_surrogate_pair(lo)
      let hi = re_surrogate_pair(hi)
      if lo.0 == hi.0 {
        alts.push(
          @re.seq([
            @re.char(@re.RecharSet::char(lo.0)),
            @re.char(@re.RecharSet::char_range(lo.1, hi.1)),
          ]),
        )
      } else {
        alts.push(
          @re.seq([
            @re.char(@re.RecharSet::char(lo.0)),
            @re.char(@re.RecharSet::char_range(lo.1, 0xDFFF)),
          ]),
        )
        if lo.0 + 1 < hi.0 {
          alts.push(
            @re.seq([
              @re.char(@re.RecharSet::char_range(lo.0 + 1, hi.0 - 1)),
              @re.char(@re.RecharSet::char_range(0xDC00, 0xDFFF)),
            ]),
          )
        }
        alts.push(
          @re.seq([
            @re.char(@re.RecharSet::char(hi.0)),
            @re.char(@re.RecharSet::char_range(0xDC00, hi.1)),
          ]),
        )
      }
    }
  }
  @re.shortest(@re.alt(ReadOnlyArray::from_array(alts)))
}

///|
fn re_lower_to_utf16(ast : @re.Pattern) -> @re.Pattern {
  match ast.desc {
    Char(cs) => re_lower_cset(cs)
    Sequence(exprs) => @re.seq(exprs.map(e => re_lower_to_utf16(e)))
    Alternation(exprs) => @re.alt(exprs.map(e => re_lower_to_utf16(e)))
    Quantifier(q, expr) => @re.quantifier(re_lower_to_utf16(expr), q)
    Preference(p, expr) => @re.preference(p, re_lower_to_utf16(expr))
    Capture(name~, expr) => @re.capture(name?, re_lower_to_utf16(expr))
    Assertion(a) => @re.assertion(a)
  }
}
