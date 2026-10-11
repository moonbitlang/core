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
/// Transition table entry: the transition has not been built yet.
const UNKNOWN : Int = -1

///|
/// Transition table entry: no thread survives and nothing was accepted.
/// Entries below `DEAD` denote a terminal state, see `terminal`.
const DEAD : Int = -2

///|
/// Register of a tag while a transition is being built: the tag is set by
/// this very transition and still needs a register.
const CURRENT : Int = -1

///|
/// Default budget for the lazy DFA cache, in machine words (table entries
/// plus state descriptions); a word is an `Int`, so this is 64 MB of table
/// and state data. A state that does not fit is not added when a cached
/// state can stand in for it, see `reuse`; otherwise the cache is dropped and
/// rebuilt on demand. Memory therefore does not grow without bound on
/// patterns whose DFA is huge, at the price of rebuilding states, which is
/// several times slower than a cached step. The budget is large enough for a
/// DFA of about two hundred thousand small states. The state being added
/// after a drop is always kept, even when it is larger than the budget on
/// its own.
const MAX_CACHE_WORDS : Int = 1 << 24

///|
/// The kernel of a lazy DFA state: the NFA nodes reached right after
/// consuming a symbol, in priority order, before epsilon closure.
///
/// `key` describes the state completely and is what states are compared by:
///
/// - `key[0]`: look-behind context, i.e. which `After` assertions hold here.
/// - `key[1]`: `1` when a match has been found on the way to this state.
/// - `key[2 + i]`: NFA node of thread `i`.
/// - then one row per thread with the tags set on its path: the number of
///   tags, followed by `(tag, register)` pairs in increasing tag order. Tags
///   that were never set are left out, so a row is as long as the path that
///   led to the thread needs and not as wide as the whole pattern. When a
///   match has been found, one more row follows with the tags of that match.
///   It plays the role of the `Accept` node in the compiler's DFA states and
///   has the lowest priority.
priv struct Kernel {
  key : FixedArray[Int]
  threads : Int
}

///|
fn Kernel::ctx(self : Kernel) -> Int {
  self.key[0]
}

///|
fn Kernel::accepted(self : Kernel) -> Bool {
  self.key[1] != 0
}

///|
fn Kernel::node(self : Kernel, thread : Int) -> Int {
  self.key[2 + thread]
}

///|
/// The `(tag, register)` pairs of the row that starts at `offset` in `key`.
/// Rows have different lengths, so they are read in order starting at
/// `2 + threads`; the next row starts `1 + length` words further.
fn Kernel::row(self : Kernel, offset : Int) -> FixedArray[Int] {
  let len = 2 * self.key[offset]
  let row = FixedArray::make(len, 0)
  self.key.blit_to(row, len~, src_offset=offset + 1)
  row
}

///|
/// `row` with `tag` set by the transition being built. Rows are shared
/// between threads while a transition is built, so `row` is never written.
fn set_current(row : FixedArray[Int], tag : Int) -> FixedArray[Int] {
  let len = row.length()
  let mut i = 0
  while i < len && row[i] < tag {
    i += 2
  }
  if i < len && row[i] == tag {
    if row[i + 1] == CURRENT {
      return row
    }
    let copy = row.copy()
    copy[i + 1] = CURRENT
    return copy
  }
  let out = FixedArray::make(len + 2, CURRENT)
  row.blit_to(out, len=i)
  out[i] = tag
  row.blit_to(out, len=len - i, src_offset=i, dst_offset=i + 2)
  out
}

///|
/// A regex compiled to a tagged NFA whose tagged DFA is built lazily while
/// matching.
struct Regex {
  groups : ReadOnlyArray[String?]
  table : @symbol_map.Table
  nodes : FixedArray[Node]
  entry : Int
  ntags : Int
  /// Number of input symbols. Column `nsym` of a table row is end of input.
  nsym : Int
  /// Look-behind context after consuming each symbol.
  sym_ctx : FixedArray[Int]
  /// Look-ahead category of each column, including end of input.
  col_cat : FixedArray[Category]
  /// Look-behind context when there is no previous character.
  ctx_start : Int
  // Lazy DFA cache.
  state_ids : @hashmap.HashMap[FixedArray[Int], Int]
  kernels : Array[Kernel]
  /// Indexed by `state * (nsym + 1) + column`; holds the next row base,
  /// `UNKNOWN`, `DEAD` or an encoded terminal state.
  mut trans : FixedArray[Int]
  /// Parallel to `trans`: the register that receives the current position
  /// when the transition is taken. Register `0` is a sink that is never read,
  /// so the scan loop can write unconditionally.
  mut slots : FixedArray[Int]
  /// Row base of the start state for each look-behind context.
  start_bases : FixedArray[Int]
  /// Register written by the transition most recently built by `build`.
  mut built_slot : Int
  /// Words currently held by the cache, and its budget.
  mut cache_words : Int
  max_cache_words : Int
  /// The cached states by `shape_hash`, in the order they were added. Only
  /// needed once the cache is full, so it is built then, see `reuse`.
  mut shapes : @hashmap.HashMap[Int, Array[Int]]?
  // Scratch space reused across `execute` calls.
  mut regs : FixedArray[Int]
  visited : FixedArray[Int]
  targeted : FixedArray[Int]
  mut epoch : Int
}

///|
/// Names of the capture groups in index order; `None` for unnamed groups.
/// Group 0 is the whole match.
pub fn Regex::group_names(self : Regex) -> ReadOnlyArray[String?] {
  self.groups
}

///|
/// Compile `ast` for searching: unless the pattern is anchored at the start
/// of input, a lazy "any character" loop is prepended, exactly like the
/// compiler prepares an unanchored `lexmatch` case.
///
/// `max_cache_words` is the budget of the lazily built DFA cache; when a new
/// state would exceed it the cache is dropped and rebuilt on demand. One
/// state is always kept, whatever its size.
pub fn compile(
  profile~ : Profile,
  ast : Pattern,
  max_cache_words? : Int = MAX_CACHE_WORDS,
) -> Regex {
  let symbol_map = @symbol_map.new()
  symbolize(profile~, symbol_map~, ast)
  let (table, symbol_repr) = symbol_map.finalize(profile.lb, profile.ub)
  let nsym = symbol_repr.length()
  let builder : Builder = { nodes: [], table, groups: [None], after_cats: [], }
  let ir = IGroup(0, builder.lower(ast))
  let accept = builder.add(Accept)
  let body = builder.emit(ir, accept)
  let entry = if ast.is_anchored() {
    body
  } else {
    let any = RecharSet::char_range(0, nsym - 1)
    let search = builder.add(Accept)
    let skip = builder.add(Char(any, search))
    builder.set_choice(search, true, body, skip)
    search
  }
  let after_cats = builder.after_cats
  fn ctx_of(cat : Category) -> Int {
    for i = 0, ctx = 0; i < after_cats.length(); {
      continue i + 1,
        if cat.intersects(after_cats[i]) {
          ctx | (1 << i)
        } else {
          ctx
        }
    } nobreak {
      ctx
    }
  }

  let sym_ctx = FixedArray::makei(nsym, i => {
    ctx_of((profile.category)(symbol_repr[i]))
  })
  let col_cat = FixedArray::makei(nsym + 1, i => {
    if i == nsym {
      Category::inexistant()
    } else {
      (profile.category)(symbol_repr[i])
    }
  })
  let nnodes = builder.nodes.length()
  let ntags = builder.groups.length() * 2
  {
    groups: ReadOnlyArray::from_array(builder.groups),
    table,
    nodes: FixedArray::from_array(builder.nodes),
    entry,
    ntags,
    nsym,
    sym_ctx,
    col_cat,
    ctx_start: ctx_of(Category::inexistant()),
    state_ids: HashMap([]),
    kernels: [],
    trans: [],
    slots: [],
    start_bases: FixedArray::make(1 << after_cats.length(), UNKNOWN),
    built_slot: 0,
    cache_words: 0,
    max_cache_words,
    shapes: None,
    regs: FixedArray::make(8, -1),
    visited: FixedArray::make(nnodes, 0),
    targeted: FixedArray::make(nnodes, 0),
    epoch: 0,
  }
}
