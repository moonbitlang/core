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
pub fn compile(profile~ : Profile, ast : Pattern) -> Regex {
  let ast = if ast.is_anchored() {
    capture(ast)
  } else {
    seq([
      shortest(
        quantifier(char(profile.valid), { min: 0, max: None, mode: Greedy }),
      ),
      capture(ast),
    ])
  }
  let symbol_map = @symbol_map.new()
  symbolize(profile~, symbol_map~, ast)
  let (symbol_table, symbol_repr) = symbol_map.finalize(profile.lb, profile.ub)
  let ctx = @automata.Context::new()
  let tc = TranslateContext::new(ctx, symbol_table)
  let (expr, pref) = translate(tc, ast)
  let expr = enforce_pref(tc.ctx, First, pref, expr)
  Regex::new(
    profile,
    ctx,
    expr,
    ReadOnlyArray::from_array(tc.groups),
    symbol_table,
    symbol_repr,
  )
}
