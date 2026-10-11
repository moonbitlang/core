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
/// A node of the priority-ordered tagged NFA.
///
/// This is the runtime counterpart of the compiler's `Tnfa2`: alternatives of
/// a `Union` are ordered by priority, capture endpoints are `Tag` nodes, and
/// zero-width assertions are explicit nodes resolved during epsilon closure.
priv enum Node {
  /// Consume one symbol from the set, then continue at the target node.
  Char(RecharSet, Int)
  /// Epsilon alternatives, highest priority first.
  Union(FixedArray[Int])
  /// Record the current position in the tag, then continue.
  Tag(Int, Int)
  /// Look-behind: bit index into the DFA state's context mask.
  After(Int, Int)
  /// Look-ahead: the category of the next symbol must intersect.
  Before(Category, Int)
  Accept
}

///|
/// The pattern after capture groups are numbered and character sets are
/// mapped to symbols. Group numbers are fixed here so that copies made for
/// counted repetitions keep sharing the same tags.
priv enum Ir {
  IChar(RecharSet)
  ISeq(Array[Ir])
  IAlt(Array[Ir])
  IRepeat(Ir, min~ : Int, max~ : Int?, greedy~ : Bool, nullable~ : Bool)
  IGroup(Int, Ir)
  IAfter(Category)
  IBefore(Category)
}

///|
priv struct Builder {
  nodes : Array[Node]
  table : @symbol_map.Table
  groups : Array[String?]
  after_cats : Array[Category]
}

///|
fn Builder::add(self : Builder, node : Node) -> Int {
  self.nodes.push(node)
  self.nodes.length() - 1
}

///|
fn Builder::after_bit(self : Builder, cat : Category) -> Int {
  match self.after_cats.search(cat) {
    Some(i) => i
    None => {
      self.after_cats.push(cat)
      self.after_cats.length() - 1
    }
  }
}

///|
fn ir_after(cat : Category) -> Ir {
  IAfter(cat)
}

///|
fn ir_before(cat : Category) -> Ir {
  IBefore(cat)
}

///|
fn lower_assertion(asrt : Assertion) -> Ir {
  match asrt {
    StartOfInput => ir_after(Category::inexistant())
    EndOfInput => ir_before(Category::inexistant())
    StartOfLine => ir_after(Category::inexistant_or_newline())
    EndOfLine => ir_before(Category::inexistant_or_newline())
    StartOfWord =>
      ISeq([
        ir_after(Category::inexistant_or_non_word_end()),
        ir_before(Category::word()),
      ])
    EndOfWord =>
      ISeq([
        ir_after(Category::word()),
        ir_before(Category::inexistant_or_non_word_start()),
      ])
    NotWordBoundary =>
      IAlt([
        ISeq([ir_after(Category::word()), ir_before(Category::word())]),
        ISeq([
          ir_after(Category::inexistant_or_non_word_end()),
          ir_before(Category::inexistant_or_non_word_start()),
        ]),
      ])
  }
}

///|
/// Number capture groups in pre-order and map character sets to symbols.
///
/// `Preference` nodes are transparent: this engine always uses leftmost-first
/// (priority) semantics, like the compiler's `First_match` strategy.
fn Builder::lower(self : Builder, pat : Pattern) -> Ir {
  match pat.desc {
    Char(set) => IChar(self.table.map_set(set))
    Sequence(pats) => ISeq([ for p in pats => self.lower(p) ])
    Alternation(_) => {
      // Flatten left-nested alternations built by repeated `|` so that
      // neither this pass nor code emission recurses once per operand.
      let flat : Array[Pattern] = []
      let stack : Array[Pattern] = [pat]
      while stack.pop() is Some(p) {
        match p.desc {
          Alternation(ps) =>
            for i = ps.length() - 1; i >= 0; i = i - 1 {
              stack.push(ps[i])
            }
          _ => flat.push(p)
        }
      }
      IAlt(flat.map(p => self.lower(p)))
    }
    Quantifier(q, inner) => {
      let greedy = q.mode is Greedy
      IRepeat(
        self.lower(inner),
        min=q.min,
        max=q.max,
        greedy~,
        nullable=inner.nullable,
      )
    }
    Preference(_, inner) => self.lower(inner)
    Capture(name~, inner) => {
      let index = self.groups.length()
      self.groups.push(name)
      IGroup(index, self.lower(inner))
    }
    Assertion(asrt) => lower_assertion(asrt)
  }
}

///|
/// A two-way epsilon choice. `first` is preferred when `greedy`.
fn Builder::choice(
  self : Builder,
  greedy : Bool,
  first : Int,
  second : Int,
) -> Int {
  self.add(Union(if greedy { [first, second] } else { [second, first] }))
}

///|
fn Builder::set_choice(
  self : Builder,
  at : Int,
  greedy : Bool,
  first : Int,
  second : Int,
) -> Unit {
  self.nodes[at] = Union(if greedy { [first, second] } else { [second, first] })
}

///|
/// Emit nodes matching `ir` and then continuing at `next`; returns the entry
/// node. The shapes follow the compiler's `Regex_compile2.build_tnfa`.
fn Builder::emit(self : Builder, ir : Ir, next : Int) -> Int {
  match ir {
    IChar(set) => self.add(Char(set, next))
    ISeq(irs) =>
      for i = irs.length() - 1, next = next; i >= 0; {
        continue i - 1, self.emit(irs[i], next)
      } nobreak {
        next
      }
    IAlt(irs) =>
      match irs {
        [] => self.add(Char(RecharSet::empty(), next))
        [ir] => self.emit(ir, next)
        _ =>
          self.add(
            Union(FixedArray::makei(irs.length(), i => self.emit(irs[i], next))),
          )
      }
    IGroup(index, inner) => {
      let close = self.add(Tag(index * 2 + 1, next))
      let body = self.emit(inner, close)
      self.add(Tag(index * 2, body))
    }
    IAfter(cat) => self.add(After(self.after_bit(cat), next))
    IBefore(cat) => self.add(Before(cat, next))
    IRepeat(inner, min~, max~, greedy~, nullable~) => {
      let rest = match max {
        None =>
          if min == 0 {
            if nullable {
              // `x*` with nullable `x` is `(x+)?`, which keeps leftmost-first
              // semantics when an iteration can match the empty string.
              let plus = self.add(Accept)
              let body = self.emit(inner, plus)
              self.set_choice(plus, greedy, body, next)
              self.choice(greedy, body, next)
            } else {
              let star = self.add(Accept)
              let body = self.emit(inner, star)
              self.set_choice(star, greedy, body, next)
              star
            }
          } else {
            // The last mandatory copy loops: `x{n,}` is `x{n-1}x+`.
            let plus = self.add(Accept)
            let body = self.emit(inner, plus)
            self.set_choice(plus, greedy, body, next)
            body
          }
        Some(max) =>
          for i = max - min, rest = next; i > 0; {
            let body = self.emit(inner, rest)
            continue i - 1, self.choice(greedy, body, next)
          } nobreak {
            rest
          }
      }
      let mandatory = if max is None && min > 0 { min - 1 } else { min }
      for i = mandatory, rest = rest; i > 0; {
        continue i - 1, self.emit(inner, rest)
      } nobreak {
        rest
      }
    }
  }
}
