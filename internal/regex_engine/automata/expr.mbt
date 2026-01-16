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
/// Regular expression AST for the automaton with unique IDs and smart constructors.
///
/// This module defines the internal representation of regular expressions used by
/// the automaton. Unlike the user-facing AST in the `ast` module, these expressions
/// are optimized for efficient derivative computation and state management.
///
/// # Key Features
///
/// ## Unique Expression IDs
///
/// Each expression has a unique `ExprId` assigned by the `Context`. This enables:
/// - O(1) equality comparison (just compare IDs)
/// - O(1) hashing (hash the ID)
/// - Efficient use as hash map keys during derivative computation
///
/// Note: This is NOT full hash-consing. Structurally identical expressions created
/// at different times will have different IDs. The ID only provides fast identity
/// comparison, not structural sharing.
///
/// ## Smart Constructors
///
/// Constructor functions (e_seq, e_alt, etc.) perform automatic simplifications:
/// - `e_seq(Empty, x)` → `Empty`
/// - `e_seq(Eps, x)` → `x`
/// - `e_alt([x])` → `x`
/// - `e_alt([])` → `Empty`
///
/// These simplifications keep the expression tree minimal during derivative computation.
///
/// # Expression Types (ExprDef)
///
/// - `Chr(RecharSet)`: Matches a character from the set
/// - `Alt(Array[Expr])`: Alternation - matches any of the alternatives
/// - `Seq(Preference, Expr, Expr)`: Sequence - matches first then second
/// - `Rep(QuantifierMode, Preference, Expr)`: Repetition (*, +, {n,m})
/// - `Eps`: Epsilon - matches empty string
/// - `Mark(Mark)`: Like Eps but adds the mark to MarkSlotMap (for capture group boundaries)
/// - `Before(Category)`: Lookahead assertion (matches if next char is in category)
/// - `After(Category)`: Lookbehind assertion (matches if prev char is in category)
struct Expr {
  id : ExprId
  def : ExprDef
}

///|
type ExprId = Int

///|
const EXPR_ID_EMPTY : ExprId = 0

///|
const EXPR_ID_EPS : ExprId = 1

///|
const EXPR_ID_RESERVED : ExprId = 1

///|
priv enum ExprDef {
  Chr(@shared_types.RecharSet)
  Alt(Array[Expr])
  Seq(@shared_types.Preference, Expr, Expr)
  Rep(@shared_types.QuantifierMode, @shared_types.Preference, Expr)
  Eps
  Mark(Mark)
  Before(@shared_types.Category)
  After(@shared_types.Category)
}

///|
impl Eq for Expr with equal(self, other) {
  self.id == other.id
}

///|
impl Hash for Expr with hash_combine(self, hasher) {
  hasher.combine(self.id)
}

///|
pub fn e_copy(ctx~ : Context, e : Expr) -> Expr {
  match e.def {
    Chr(c) => e_cset(ctx~, c)
    Alt(xs) => e_alt(ctx~, xs.map(x => e_copy(ctx~, x)))
    Seq(pref, x, y) => e_seq(ctx~, pref, e_copy(ctx~, x), e_copy(ctx~, y))
    Rep(mode, pref, x) => e_rep(ctx~, mode, pref, e_copy(ctx~, x))
    Eps => e_eps
    Mark(m) => e_mark(ctx~, m)
    Before(cat) => e_before(ctx~, cat)
    After(cat) => e_after(ctx~, cat)
  }
}

///|
let e_empty : Expr = Expr::{ id: EXPR_ID_EMPTY, def: Alt([]) }

///|
pub let e_eps : Expr = Expr::{ id: EXPR_ID_EPS, def: Eps }

///|
pub fn is_eps(e : Expr) -> Bool {
  e.def is Eps
}

///|
pub fn e_cset(ctx~ : Context, c : @shared_types.RecharSet) -> Expr {
  if c.is_empty() {
    e_empty
  } else {
    Expr::{ id: ctx.new_expr_id(), def: Chr(c) }
  }
}

///|
pub fn e_rep(
  ctx~ : Context,
  mode : @shared_types.QuantifierMode,
  pref : @shared_types.Preference,
  x : Expr,
) -> Expr {
  Expr::{ id: ctx.new_expr_id(), def: Rep(mode, pref, x) }
}

///|
pub fn e_mark(ctx~ : Context, m : Mark) -> Expr {
  Expr::{ id: ctx.new_expr_id(), def: Mark(m) }
}

///|
pub fn e_before(ctx~ : Context, cat : @shared_types.Category) -> Expr {
  Expr::{ id: ctx.new_expr_id(), def: Before(cat) }
}

///|
pub fn e_after(ctx~ : Context, cat : @shared_types.Category) -> Expr {
  Expr::{ id: ctx.new_expr_id(), def: After(cat) }
}

///|
/// Smart constructor for alternation with automatic simplification.
///
/// - Empty array → `e_empty`
/// - Single element → return that element
/// - Otherwise → create Alt node
pub fn e_alt(ctx~ : Context, xs : Array[Expr]) -> Expr {
  match xs {
    [] => e_empty
    [x] => x
    xs => Expr::{ id: ctx.new_expr_id(), def: Alt(xs) }
  }
}

///|
/// Smart constructor for sequence with automatic simplification.
///
/// Simplification rules:
/// - `Seq(Empty, _)` → `Empty` (empty doesn't match anything)
/// - `Seq(_, Empty)` → `Empty`
/// - `Seq(Eps, x)` → `x` (epsilon has no effect)
/// - `Seq(x, Eps)` with First preference → `x`
/// - Otherwise → create Seq node
pub fn e_seq(
  ctx~ : Context,
  pref : @shared_types.Preference,
  x : Expr,
  y : Expr,
) -> Expr {
  match (x.def, y.def) {
    (Alt([]), _) => x
    (_, Alt([])) => y
    (Eps, _) => y
    (_, Eps) if pref is First => x
    _ => Expr::{ id: ctx.new_expr_id(), def: Seq(pref, x, y) }
  }
}
