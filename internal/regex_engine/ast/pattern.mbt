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
pub(all) struct Quantifier {
  min : Int
  max : Int?
  mode : @shared_types.QuantifierMode
} derive(Debug)

///|
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
pub struct Pattern {
  desc : PatternDesc
  nullable : Bool
}

///|
pub impl Debug for Pattern with to_repr(self) {
  self.desc.to_repr()
}

///|
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
pub fn char(cs : @shared_types.RecharSet) -> Pattern {
  if cs.is_empty() {
    empty
  } else {
    Pattern::{ desc: Char(cs), nullable: false }
  }
}

///|
pub let epsilon : Pattern = Pattern::{ desc: Sequence([]), nullable: true }

///|
pub fn seq(exprs : ReadOnlyArray[Pattern]) -> Pattern {
  match exprs {
    [] => epsilon
    [expr] => expr
    exprs =>
      Pattern::{ desc: Sequence(exprs), nullable: exprs.all(e => e.nullable) }
  }
}

///|
pub let empty : Pattern = Pattern::{ desc: Alternation([]), nullable: false }

///|
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
pub fn quantifier(expr : Pattern, q : Quantifier) -> Pattern {
  guard q.min >= 0 else { panic() }
  guard q.max is None || (q.max is Some(max) && max >= q.min) else { panic() }
  Pattern::{ desc: Quantifier(q, expr), nullable: expr.nullable || q.min == 0 }
}

///|
pub fn preference(pref : @shared_types.Preference, expr : Pattern) -> Pattern {
  if expr.desc is Char(_) {
    expr
  } else {
    Pattern::{ desc: Preference(pref, expr), nullable: expr.nullable }
  }
}

///|
pub fn longest(expr : Pattern) -> Pattern {
  preference(Longest, expr)
}

///|
pub fn shortest(expr : Pattern) -> Pattern {
  preference(Shortest, expr)
}

///|
pub fn first(expr : Pattern) -> Pattern {
  preference(First, expr)
}

///|
pub fn capture(name? : String, expr : Pattern) -> Pattern {
  Pattern::{ desc: Capture(name~, expr), nullable: expr.nullable }
}

///|
pub fn assertion(a : Assertion) -> Pattern {
  Pattern::{ desc: Assertion(a), nullable: true }
}

///|
pub let start_of_input : Pattern = assertion(StartOfInput)

///|
pub let end_of_input : Pattern = assertion(EndOfInput)

///|
pub let start_of_line : Pattern = assertion(StartOfLine)

///|
pub let end_of_line : Pattern = assertion(EndOfLine)

///|
pub let start_of_word : Pattern = assertion(StartOfWord)

///|
pub let end_of_word : Pattern = assertion(EndOfWord)

///|
pub let not_word_boundary : Pattern = assertion(NotWordBoundary)
