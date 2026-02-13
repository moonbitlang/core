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
/// Quantifier metadata for a regex pattern.
///
/// - `min`: minimum repetition count.
/// - `max`: optional maximum repetition count.
/// - `mode`: greedy/non-greedy mode.
pub(all) struct Quantifier {
  min : Int
  max : Int?
  mode : @shared_types.QuantifierMode
} derive(Debug)

///|
/// Zero-width regex assertions.
pub enum Assertion {
  StartOfInput
  EndOfInput
  StartOfLine
  EndOfLine
  StartOfWord
  EndOfWord
  NotWordBoundary
} derive(Debug)

///|
/// Core regex pattern AST node with cached nullability.
pub struct Pattern {
  desc : PatternDesc
  nullable : Bool
}

///|
pub impl Debug for Pattern with to_repr(self) {
  self.desc.to_repr()
}

///|
/// Variants of regex pattern syntax nodes.
pub enum PatternDesc {
  Char(@shared_types.RecharSet)
  Sequence(ReadOnlyArray[Pattern])
  Alternation(ReadOnlyArray[Pattern])
  Quantifier(Quantifier, Pattern)
  Preference(@shared_types.Preference, Pattern)
  Capture(name~ : String?, Pattern)
  Assertion(Assertion)
} derive(Debug)

///|
/// Return whether the pattern is anchored to input boundaries.
pub fn Pattern::is_anchored(self : Pattern) -> Bool {
  match self.desc {
    Char(_) => false
    Sequence(exprs) => exprs.any(fn(e) { e.is_anchored() })
    Alternation(exprs) => exprs.all(fn(e) { e.is_anchored() })
    Quantifier(q, expr) => q.min > 0 && expr.is_anchored()
    Preference(_, expr) => expr.is_anchored()
    Capture(expr, ..) => expr.is_anchored()
    Assertion(StartOfInput) => true
    Assertion(_) => false
  }
}

///|
/// Build a character-class pattern.
pub fn char(cs : @shared_types.RecharSet) -> Pattern {
  if cs.is_empty() {
    empty
  } else {
    Pattern::{ desc: Char(cs), nullable: false }
  }
}

///|
/// Epsilon pattern that matches empty input.
pub let epsilon : Pattern = Pattern::{ desc: Sequence([]), nullable: true }

///|
/// Concatenate patterns.
pub fn seq(exprs : ReadOnlyArray[Pattern]) -> Pattern {
  match exprs {
    [] => epsilon
    [expr] => expr
    exprs =>
      Pattern::{ desc: Sequence(exprs), nullable: exprs.all(e => e.nullable) }
  }
}

///|
/// Empty pattern that matches nothing.
pub let empty : Pattern = Pattern::{ desc: Alternation([]), nullable: false }

///|
/// Build an alternation of patterns.
pub fn alt(exprs : ReadOnlyArray[Pattern]) -> Pattern {
  match exprs {
    [] => empty
    [expr] => expr
    exprs =>
      Pattern::{
        desc: Alternation(exprs),
        nullable: exprs.any(e => e.nullable),
      }
  }
}

///|
/// Apply a quantifier to a pattern.
///
/// Panics if `q` is invalid (`min < 0` or `max < min`).
pub fn quantifier(expr : Pattern, q : Quantifier) -> Pattern {
  guard q.min >= 0 else { panic() }
  guard q.max is None || (q.max is Some(max) && max >= q.min) else { panic() }
  Pattern::{ desc: Quantifier(q, expr), nullable: expr.nullable || q.min == 0 }
}

///|
/// Apply matching preference to a pattern.
pub fn preference(pref : @shared_types.Preference, expr : Pattern) -> Pattern {
  if expr.desc is Char(_) {
    expr
  } else {
    Pattern::{ desc: Preference(pref, expr), nullable: expr.nullable }
  }
}

///|
/// Prefer shortest match when ambiguous.
pub fn shortest(expr : Pattern) -> Pattern {
  preference(Shortest, expr)
}

///|
/// Wrap a pattern in a capturing group.
pub fn capture(name? : String, expr : Pattern) -> Pattern {
  Pattern::{ desc: Capture(name~, expr), nullable: expr.nullable }
}

///|
/// Create an assertion pattern node.
pub fn assertion(a : Assertion) -> Pattern {
  Pattern::{ desc: Assertion(a), nullable: true }
}

///|
/// Start-of-input assertion pattern.
pub let start_of_input : Pattern = assertion(StartOfInput)

///|
/// End-of-input assertion pattern.
pub let end_of_input : Pattern = assertion(EndOfInput)

///|
/// Start-of-line assertion pattern.
pub let start_of_line : Pattern = assertion(StartOfLine)

///|
/// End-of-line assertion pattern.
pub let end_of_line : Pattern = assertion(EndOfLine)

///|
/// Start-of-word-boundary assertion pattern.
pub let start_of_word : Pattern = assertion(StartOfWord)

///|
/// End-of-word-boundary assertion pattern.
pub let end_of_word : Pattern = assertion(EndOfWord)

///|
/// Not-a-word-boundary assertion pattern.
pub let not_word_boundary : Pattern = assertion(NotWordBoundary)
