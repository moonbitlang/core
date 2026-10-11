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
/// entry that stops the scan loop. Terminal states take every other entry
/// below `DEAD`, transitions that move registers the entries in between.
fn terminal(state : Int) -> Int {
  DEAD - 1 - 2 * state
}

///|
fn terminal_state(entry : Int) -> Int {
  (DEAD - 1 - entry) / 2
}

///|
/// Encode a transition that moves registers, as a negative table entry that
/// takes the scan loop off its fast path.
fn moving(index : Int) -> Int {
  DEAD - 2 - 2 * index
}

///|
fn is_moving(entry : Int) -> Bool {
  entry < DEAD && ((DEAD - 1 - entry) & 1) == 1
}

///|
/// Move registers as `pairs` says: the value of each `from` goes to its `to`.
fn Regex::move_registers(self : Regex, pairs : FixedArray[Int]) -> Unit {
  let count = pairs.length() / 2
  if self.move_values.length() < count {
    self.move_values = FixedArray::make(count, 0)
  }
  let values = self.move_values
  let regs = self.regs
  for i in 0..<count {
    values[i] = regs[pairs[2 * i]]
  }
  for i in 0..<count {
    regs[pairs[2 * i + 1]] = values[i]
  }
}

///|
/// Take a transition that moves registers, after the register of the
/// transition itself has been written. Returns the table entry of the state
/// entered.
fn Regex::follow(self : Regex, entry : Int) -> Int {
  let taken = self.moves[(DEAD - 2 - entry) / 2]
  self.move_registers(taken.pairs)
  taken.target
}

///|
/// Drop every cached state and transition.
fn Regex::flush(self : Regex) -> Unit {
  // Rows past the cached states were never written.
  let used = self.kernels.length() * self.width()
  self.state_ids.clear()
  self.kernels.clear()
  self.trans.fill(UNKNOWN, end=used)
  self.slots.fill(0, end=used)
  self.start_bases.fill(UNKNOWN)
  self.cache_words = 0
  self.shapes = None
  self.moves.clear()
  self.move_words = 0
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
  if self.shapes is Some(shapes) {
    add_shape(
      shapes,
      shape_hash(key, threads, Ranks::new(self.regs.length())),
      state,
    )
  }
  state
}

///|
/// Scratch space to number the registers of a key in order of appearance.
priv struct Ranks {
  rank : FixedArray[Int]
  /// `rank[r]` is valid when `stamp[r] == epoch`.
  stamp : FixedArray[Int]
  mut epoch : Int
}

///|
fn Ranks::new(registers : Int) -> Ranks {
  {
    rank: FixedArray::make(registers, 0),
    stamp: FixedArray::make(registers, 0),
    epoch: 0,
  }
}

///|
/// Hash of a state key that does not depend on which registers it uses:
/// every register is replaced by its rank in order of first appearance. Two
/// states that are the same up to a renaming of registers hash alike.
fn shape_hash(key : FixedArray[Int], threads : Int, ranks : Ranks) -> Int {
  ranks.epoch += 1
  let epoch = ranks.epoch
  let hasher = Hasher()
  let rows = 2 + threads
  for i in 0..<rows {
    hasher.combine_int(key[i])
  }
  let mut next_rank = 0
  let mut at = rows
  while at < key.length() {
    let pairs = key[at]
    hasher.combine_int(pairs)
    for i = at + 1; i < at + 1 + 2 * pairs; i = i + 2 {
      hasher.combine_int(key[i])
      let register = key[i + 1]
      if ranks.stamp[register] != epoch {
        ranks.stamp[register] = epoch
        ranks.rank[register] = next_rank
        next_rank += 1
      }
      hasher.combine_int(ranks.rank[register])
    }
    at += 1 + 2 * pairs
  }
  hasher.finalize()
}

///|
fn add_shape(
  shapes : @hashmap.HashMap[Int, Array[Int]],
  hash : Int,
  state : Int,
) -> Unit {
  match shapes.get(hash) {
    Some(states) => states.push(state)
    None => shapes.set(hash, [state])
  }
}

///|
/// If the state described by `key` is the cached state `state` with its
/// registers renamed, return the renaming: for each register of `key`, the
/// register that plays its part in `state`, and `-1` for the others.
fn Regex::renaming(
  self : Regex,
  key : FixedArray[Int],
  threads : Int,
  state : Int,
) -> FixedArray[Int]? {
  let other = self.kernels[state]
  let theirs = other.key
  guard other.threads == threads && theirs.length() == key.length() else {
    None
  }
  let rows = 2 + threads
  for i in 0..<rows {
    guard key[i] == theirs[i] else { return None }
  }
  let registers = self.regs.length()
  let forward = FixedArray::make(registers, -1)
  let backward = FixedArray::make(registers, -1)
  let mut at = rows
  while at < key.length() {
    let pairs = key[at]
    guard theirs[at] == pairs else { return None }
    for i = at + 1; i < at + 1 + 2 * pairs; i = i + 2 {
      guard key[i] == theirs[i] else { return None }
      let mine = key[i + 1]
      let its = theirs[i + 1]
      if forward[mine] < 0 && backward[its] < 0 {
        forward[mine] = its
        backward[its] = mine
      } else if forward[mine] != its {
        return None
      }
    }
    at += 1 + 2 * pairs
  }
  Some(forward)
}

///|
/// Find a cached state to enter in place of the state described by `key`,
/// which does not fit in the cache. Returns that state and the register
/// moves that entering it takes, or `None` when there is none.
///
/// A state names the register that holds each tag of each thread. Which
/// registers these are is an accident of the path that led to the state:
/// two states that only differ in the names of their registers behave alike
/// from then on. While there is room, both are kept, because moving from one
/// state to the next then costs a single store. A search with many threads
/// alive at once, one per start position, walks through one such copy after
/// the other, and there can be as many copies as there are threads. So when
/// there is no room, the search enters the copy that is already cached and
/// pays for it by moving the values to the registers that state reads.
fn Regex::reuse(
  self : Regex,
  key : FixedArray[Int],
  threads : Int,
) -> (Int, FixedArray[Int])? {
  let shapes = match self.shapes {
    Some(shapes) => shapes
    None => {
      let shapes = @hashmap.HashMap([])
      let ranks = Ranks::new(self.regs.length())
      for state, kernel in self.kernels {
        add_shape(shapes, shape_hash(kernel.key, kernel.threads, ranks), state)
      }
      self.shapes = Some(shapes)
      shapes
    }
  }
  let hash = shape_hash(key, threads, Ranks::new(self.regs.length()))
  guard shapes.get(hash) is Some(candidates) else { None }
  // The oldest copy has the longest run of cached transitions ahead of it.
  for state in candidates {
    guard self.renaming(key, threads, state) is Some(forward) else { continue }
    let pairs : Array[Int] = []
    for register, target in forward {
      if target >= 0 && target != register {
        pairs.push(register)
        pairs.push(target)
      }
    }
    return Some((state, FixedArray::from_array(pairs)))
  }
  None
}

///|
/// Row base of the start state under look-behind context `ctx`.
fn Regex::start_base(self : Regex, ctx : Int) -> Int {
  let base = self.start_bases[ctx]
  if base != UNKNOWN {
    return base
  }
  // One thread at the entry node that has set no tag yet.
  let key : FixedArray[Int] = [ctx, 0, self.entry, 0]
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
/// or `nsym` for end of input) taken at position `pos`. Returns the next row
/// base, `DEAD`, or an encoded terminal state, and leaves the register
/// written by the transition in `built_slot`.
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
fn Regex::build(self : Regex, base : Int, column : Int, pos : Int) -> Int {
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
  let mut offset = 2 + threads
  for i in 0..<threads {
    let tags = kernel.row(offset)
    offset += 1 + tags.length()
    stack.push((kernel.node(i), tags))
    while stack.pop() is Some((node, tags)) {
      guard visited[node] != epoch else { continue }
      visited[node] = epoch
      match nodes[node] {
        Tag(tag, next) => stack.push((next, set_current(tags, tag)))
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
    // Every thread row has been read, so `offset` is at the row of the match.
    accept = Some(kernel.row(offset))
  }
  if accept is Some(tags) {
    out_tags.push(tags)
  }
  // Allocate one register for every tag set by this transition: the lowest
  // one that no surviving thread and no match candidate still reads.
  let rows = out_tags.length()
  let mut fresh = false
  let used : Array[Bool] = [true]
  let mut size = 2 + out_nodes.length()
  for tags in out_tags {
    size += 1 + tags.length()
    for i = 1; i < tags.length(); i = i + 2 {
      let slot = tags[i]
      if slot == CURRENT {
        fresh = true
      } else {
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
  let key = FixedArray::make(size, 0)
  key[0] = if at_end { 0 } else { self.sym_ctx[column] }
  key[1] = if accept is Some(_) { 1 } else { 0 }
  for i, node in out_nodes {
    key[2 + i] = node
  }
  let mut at = 2 + count
  for tags in out_tags {
    key[at] = tags.length() / 2
    for i = 0; i < tags.length(); i = i + 2 {
      key[at + 1 + i] = tags[i]
      key[at + 2 + i] = if tags[i + 1] == CURRENT { slot } else { tags[i + 1] }
    }
    at += 1 + tags.length()
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
      if self.cache_words + self.cost(key) <= self.max_cache_words {
        let entry = encode(self.insert(key, count))
        self.trans[base + column] = entry
        self.slots[base + column] = slot
        entry
      } else if self.reuse(key, count) is Some((state, pairs)) {
        let entry = encode(state)
        // The move reads the register this transition writes, so that is
        // written first. The caller writes `built_slot` once more; send that
        // to the unused register `0`.
        self.regs[slot] = pos
        self.move_registers(pairs)
        self.built_slot = 0
        let words = pairs.length() + 2
        if self.move_words + words <= self.max_cache_words {
          self.move_words += words
          self.trans[base + column] = moving(self.moves.length())
          self.slots[base + column] = slot
          self.moves.push({ pairs, target: entry, })
        }
        entry
      } else {
        // The source row disappears with the cache, so the transition is
        // returned without being recorded.
        self.flush()
        encode(self.insert(key, count))
      }
  }
}
