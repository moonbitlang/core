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
priv struct TranslateContext {
  ctx : @automata.Context
  pref : Preference
  groups : Array[String?]
  symbol_table : &@symbol_map.Table
}

///|
fn TranslateContext::new(
  ctx : @automata.Context,
  symbol_table : &@symbol_map.Table,
) -> TranslateContext {
  TranslateContext::{ ctx, pref: First, groups: [], symbol_table }
}

///|
fn translate(
  tc : TranslateContext,
  ast : Pattern,
) -> (@automata.Expr, Preference) {
  let { ctx, pref, groups, symbol_table } = tc
  match ast.desc {
    Char(c) => (@automata.e_cset(ctx~, symbol_table.map_set(c)), pref)
    Sequence(exprs) => (transl_seq(tc, exprs), pref)
    Alternation(exprs) => {
      // TODO: merge sequences
      let alts = []
      for expr in exprs {
        let (cr, pref2) = translate(tc, expr)
        alts.push(enforce_pref(ctx, pref, pref2, cr))
      }
      (@automata.e_alt(ctx~, alts), pref)
    }
    Quantifier(q, expr) => {
      let (cr, pref2) = translate(tc, expr)
      let rem = match q.max {
        None => @automata.e_rep(ctx~, q.mode, pref2, cr)
        Some(max) => {
          let repeater = match q.mode {
            Greedy =>
              rem => {
                @automata.e_alt(ctx~, [
                  @automata.e_seq(ctx~, pref2, @automata.e_copy(ctx~, cr), rem),
                  @automata.e_eps,
                ])
              }
            NonGreedy =>
              rem => {
                @automata.e_alt(ctx~, [
                  @automata.e_eps,
                  @automata.e_seq(ctx~, pref2, @automata.e_copy(ctx~, cr), rem),
                ])
              }
          }
          iter(max - q.min, repeater, @automata.e_eps)
        }
      }
      let result = iter(
        q.min,
        rem => @automata.e_seq(ctx~, pref2, @automata.e_copy(ctx~, cr), rem),
        rem,
      )
      (result, pref)
    }
    Preference(pref2, expr) => {
      let (cr, pref3) = translate({ ..tc, pref: pref2 }, expr)
      (enforce_pref(ctx, pref2, pref3, cr), pref2)
    }
    Capture(name~, expr) => {
      let group_index = groups.length()
      groups.push(name)
      let (cr, pref2) = translate(tc, expr)
      (
        @automata.e_seq(
          ctx~,
          First,
          @automata.e_mark(ctx~, @automata.Mark(group_index * 2)),
          @automata.e_seq(
            ctx~,
            First,
            cr,
            @automata.e_mark(ctx~, @automata.Mark(group_index * 2 + 1)),
          ),
        ),
        pref2,
      )
    }
    Assertion(asrt) => (transl_asrt(ctx, asrt), pref)
  }
}

///|
fn transl_asrt(ctx : @automata.Context, asrt : Assertion) -> @automata.Expr {
  match asrt {
    StartOfLine => @automata.e_after(ctx~, Category::inexistant_or_newline())
    EndOfLine => @automata.e_before(ctx~, Category::inexistant_or_newline())
    StartOfWord =>
      @automata.e_seq(
        ctx~,
        First,
        @automata.e_after(ctx~, Category::inexistant_or_non_word()),
        @automata.e_before(ctx~, Category::word()),
      )
    EndOfWord =>
      @automata.e_seq(
        ctx~,
        First,
        @automata.e_after(ctx~, Category::word()),
        @automata.e_before(ctx~, Category::inexistant_or_non_word()),
      )
    NotWordBoundary =>
      @automata.e_alt(ctx~, [
        @automata.e_seq(
          ctx~,
          First,
          @automata.e_after(ctx~, Category::word()),
          @automata.e_before(ctx~, Category::word()),
        ),
        @automata.e_seq(
          ctx~,
          First,
          @automata.e_after(ctx~, Category::inexistant_or_non_word()),
          @automata.e_before(ctx~, Category::inexistant_or_non_word()),
        ),
      ])
    StartOfInput => @automata.e_after(ctx~, Category::inexistant())
    EndOfInput => @automata.e_before(ctx~, Category::inexistant())
  }
}

///|
fn transl_seq(
  tc : TranslateContext,
  exprs : ReadOnlyArray[Pattern],
) -> @automata.Expr {
  fn go(i : Int) -> @automata.Expr {
    if i >= exprs.length() {
      @automata.e_eps
    } else if i == exprs.length() - 1 {
      let (cr, pref2) = translate(tc, exprs[i])
      enforce_pref(tc.ctx, tc.pref, pref2, cr)
    } else {
      let (cr, pref2) = translate(tc, exprs[i])
      let cr2 = go(i + 1)
      if @automata.is_eps(cr2) {
        cr
      } else if @automata.is_eps(cr) {
        cr2
      } else {
        @automata.e_seq(ctx=tc.ctx, pref2, cr, cr2)
      }
    }
  }

  go(0)
}

///|
fn enforce_pref(
  ctx : @automata.Context,
  pref : Preference,
  pref2 : Preference,
  cr : @automata.Expr,
) -> @automata.Expr {
  match (pref, pref2) {
    (First, First) => cr
    (First, k) => @automata.e_seq(ctx~, k, cr, @automata.e_eps)
    _ => cr
  }
}

///|
fn[T] iter(n : Int, f : (T) -> T, init : T) -> T {
  if n == 0 {
    init
  } else {
    iter(n - 1, f, f(init))
  }
}
