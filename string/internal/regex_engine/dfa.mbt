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
fn Regex::width(self : Regex) -> Int {
  self.nsym + 1
}

///|
/// Encode a state without threads that holds a match, as a negative table
/// entry that stops the scan loop.
fn terminal(state : Int) -> Int {
  DEAD - 1 - state
}

///|
fn terminal_state(entry : Int) -> Int {
  DEAD - 1 - entry
}

///|
/// Drop every cached state and transition.
fn Regex::flush(self : Regex) -> Unit {
  self.state_ids.clear()
  self.kernels.clear()
  self.trans.fill(UNKNOWN)
  self.slots.fill(0)
  self.start_bases.fill(UNKNOWN)
  self.cache_words = 0
}

///|
/// Words a new state with this key adds to the cache.
fn Regex::cost(self : Regex, key : FixedArray[Int]) -> Int {
  key.length() + 2 * self.width()
}

///|
/// Add a state that is known not to be cached yet and return its index.
fn Regex::insert(self : Regex, key : FixedArray[Int], threads : Int) -> Int {
  let width = self.width()
  let state = self.kernels.length()
  let needed = (state + 1) * width
  if needed > self.trans.length() {
    let capacity = Int::max(needed, self.trans.length() * 2)
    self.trans = FixedArray::make_and_blit(
      self.trans,
      allocate_len=capacity,
      init=UNKNOWN,
      len=self.trans.length(),
    )
    self.slots = FixedArray::make_and_blit(
      self.slots,
      allocate_len=capacity,
      init=0,
      len=self.slots.length(),
    )
  }
  self.kernels.push({ key, threads, })
  self.state_ids.set(key, state)
  self.cache_words += self.cost(key)
  state
}

///|
/// Row base of the start state under look-behind context `ctx`.
fn Regex::start_base(self : Regex, ctx : Int) -> Int {
  let base = self.start_bases[ctx]
  if base != UNKNOWN {
    return base
  }
  let key = FixedArray::make(3 + self.ntags, ABSENT)
  key[0] = ctx
  key[1] = 0
  key[2] = self.entry
  let state = match self.state_ids.get(key) {
    Some(state) => state
    None => self.insert(key, 1)
  }
  let base = state * self.width()
  self.start_bases[ctx] = base
  base
}

///|
/// Largest generation stamp handed out before the marks are cleared.
const EPOCH_LIMIT : Int = 0x7fffffff

///|
/// A fresh generation stamp for the `visited` and `targeted` marks of one
/// `build`. Before the counter can wrap onto a stamp that is still stored in
/// the marks (including the initial `0`), the marks are cleared.
fn Regex::next_epoch(self : Regex) -> Int {
  if self.epoch >= EPOCH_LIMIT {
    self.visited.fill(0)
    self.targeted.fill(0)
    self.epoch = 0
  }
  self.epoch += 1
  self.epoch
}

///|
/// Build the transition out of the state at row `base` on `column` (a symbol,
/// or `nsym` for end of input). Returns the next row base, `DEAD`, or an
/// encoded terminal state, and leaves the register written by the transition
/// in `built_slot`.
///
/// This is the compiler's `Tnfa2.epsilon_closure` followed by one step of
/// `Tnfa2_to_tdfa.istate_next` under the `First_match` strategy, done for a
/// single symbol on demand:
///
/// 1. Close the kernel under epsilon moves in priority order. Tags met on the
///    way are set at the current position. Because the next symbol is known,
///    look-ahead assertions are decided here, and look-behind assertions use
///    the context stored in the state.
/// 2. Reaching `Accept` records a match candidate and discards every
///    lower-priority thread, which is what makes the match leftmost-first.
///    The candidate replaces the one carried by the state, if any.
/// 3. Threads that can consume the symbol form the next kernel.
///
/// Registers differ from the compiler, which renumbers tag versions densely
/// on every state and pays for it with register copies: static code wants few
/// states, a lazy matcher wants a cheap step. Here a thread keeps its
/// registers for as long as it lives. Every tag set by one transition has the
/// same value, so a transition needs at most one fresh register, and taking
/// it is a single store.
fn Regex::build(self : Regex, base : Int, column : Int) -> Int {
  let ntags = self.ntags
  let nodes = self.nodes
  let width = self.width()
  let kernel = self.kernels[base / width]
  let cat = self.col_cat[column]
  let at_end = column == self.nsym
  let epoch = self.next_epoch()
  let visited = self.visited
  let targeted = self.targeted
  let out_nodes : Array[Int] = []
  let out_tags : Array[FixedArray[Int]] = []
  let mut accept : FixedArray[Int]? = None
  let stack : Array[(Int, FixedArray[Int])] = []
  let threads = kernel.threads
  let ctx = kernel.ctx()
  for i in 0..<threads {
    let tags = FixedArray::make(ntags, ABSENT)
    kernel.key.blit_to(tags, len=ntags, src_offset=kernel.row(i, ntags))
    stack.push((kernel.node(i), tags))
    while stack.pop() is Some((node, tags)) {
      guard visited[node] != epoch else { continue }
      visited[node] = epoch
      match nodes[node] {
        Tag(tag, next) => {
          let tags = tags.copy()
          tags[tag] = CURRENT
          stack.push((next, tags))
        }
        After(bit, next) =>
          if (ctx & (1 << bit)) != 0 {
            stack.push((next, tags))
          }
        Before(expected, next) =>
          if cat.intersects(expected) {
            stack.push((next, tags))
          }
        Union(alts) =>
          for j = alts.length() - 1; j >= 0; j = j - 1 {
            stack.push((alts[j], tags))
          }
        Char(set, next) =>
          if !at_end && targeted[next] != epoch && set.contains(column) {
            targeted[next] = epoch
            out_nodes.push(next)
            out_tags.push(tags)
          }
        Accept => {
          accept = Some(tags)
          break
        }
      }
    }
    if accept is Some(_) {
      break
    }
  }
  if accept is None && kernel.accepted() {
    let tags = FixedArray::make(ntags, ABSENT)
    kernel.key.blit_to(tags, len=ntags, src_offset=kernel.row(threads, ntags))
    accept = Some(tags)
  }
  if accept is Some(tags) {
    out_tags.push(tags)
  }
  // Allocate one register for every tag set by this transition: the lowest
  // one that no surviving thread and no match candidate still reads.
  let rows = out_tags.length()
  let mut fresh = false
  let used : Array[Bool] = [true]
  for tags in out_tags {
    for slot in tags {
      if slot == CURRENT {
        fresh = true
      } else if slot != ABSENT {
        while used.length() <= slot {
          used.push(false)
        }
        used[slot] = true
      }
    }
  }
  let slot = if fresh {
    match used.search(false) {
      Some(free) => free
      None => used.length()
    }
  } else {
    0
  }
  if slot >= self.regs.length() {
    self.regs = FixedArray::make_and_blit(
      self.regs,
      allocate_len=Int::max(slot + 1, self.regs.length() * 2),
      init=-1,
      len=self.regs.length(),
    )
  }
  self.built_slot = slot
  guard rows > 0 else {
    self.trans[base + column] = DEAD
    self.slots[base + column] = 0
    DEAD
  }
  let count = out_nodes.length()
  let key = FixedArray::make(2 + count + rows * ntags, ABSENT)
  key[0] = if at_end { 0 } else { self.sym_ctx[column] }
  key[1] = if accept is Some(_) { 1 } else { 0 }
  for i, node in out_nodes {
    key[2 + i] = node
  }
  for i, tags in out_tags {
    for tag, s in tags {
      key[2 + count + i * ntags + tag] = if s == CURRENT { slot } else { s }
    }
  }
  let encode = (state : Int) => {
    if count == 0 {
      terminal(state)
    } else {
      state * width
    }
  }
  match self.state_ids.get(key) {
    Some(state) => {
      let entry = encode(state)
      self.trans[base + column] = entry
      self.slots[base + column] = slot
      entry
    }
    None =>
      if self.cache_words + self.cost(key) > self.max_cache_words &&
        self.kernels.length() > 0 {
        // The source row disappears with the cache, so the transition is
        // returned without being recorded.
        self.flush()
        encode(self.insert(key, count))
      } else {
        let entry = encode(self.insert(key, count))
        self.trans[base + column] = entry
        self.slots[base + column] = slot
        entry
      }
  }
}
