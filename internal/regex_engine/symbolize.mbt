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
fn symbolize(
  profile~ : Profile,
  symbol_map~ : @symbol_map.SymbolMap,
  expr : Pattern,
) -> Unit {
  fn aux(expr : Pattern) {
    match expr.desc {
      Char(s) => symbol_map.split(s)
      Sequence(l) => l.each(aux)
      Alternation(l) => l.each(aux)
      Quantifier(_, r) => aux(r)
      Assertion(StartOfLine) | Assertion(EndOfLine) =>
        symbol_map.split(RecharSet::char('\n'))
      Assertion(StartOfWord)
      | Assertion(EndOfWord)
      | Assertion(NotWordBoundary) => symbol_map.split(profile.word)
      Assertion(StartOfInput) | Assertion(EndOfInput) => ()
      Preference(_, r) => aux(r)
      Capture(r, ..) => aux(r)
    }
  }

  aux(expr)
}
