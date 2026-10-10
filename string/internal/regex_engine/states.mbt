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
fn tagged_assertion(a : Assertion, prev : Category, next : Category) -> Bool {
  match a {
    StartOfInput => prev.intersects(Category::inexistant())
    EndOfInput => next.intersects(Category::inexistant())
    StartOfLine => prev.intersects(Category::inexistant_or_newline())
    EndOfLine => next.intersects(Category::inexistant_or_newline())
    StartOfWord =>
      prev.intersects(Category::inexistant_or_non_word_end()) &&
      next.intersects(Category::word())
    EndOfWord =>
      prev.intersects(Category::word()) &&
      next.intersects(Category::inexistant_or_non_word_start())
    NotWordBoundary =>
      (prev.intersects(Category::word()) && next.intersects(Category::word())) ||
      (
        prev.intersects(Category::inexistant_or_non_word_end()) &&
        next.intersects(Category::inexistant_or_non_word_start())
      )
  }
}

///|
fn Regex::width(self : Regex) -> Int {
  self.repr.length() + 1
}

///|
fn Regex::stabilize(self : Regex, key : TaggedKey) -> Int {
  self.cache.get_or_init(key, () => {
    let index = self.states.length()
    self.states.push(key)
    let width = self.width()
    let required = (index + 1) * width
    if required > self.next.length() {
      let size = Int::max(self.next.length() * 2, Int::max(required, width * 4))
      let next = FixedArray::make(size, -1)
      self.next.blit_to(next, len=self.next.length())
      let actions = FixedArray::make(size, 0)
      self.actions.blit_to(actions, len=self.actions.length())
      self.next = next
      self.actions = actions
    }
    let terminal = key.threads.is_empty() || key.threads[0].pc == 0
    if terminal {
      -index - 2
    } else {
      index * width
    }
  })
}

///|
fn Regex::start_state(self : Regex, prev : Category) -> Int {
  for (cat, state) in self.starts {
    if cat == prev {
      return state
    }
  }
  let state = self.stabilize({
    prev,
    threads: [
      {
        pc: self.start,
        tags: ReadOnlyArray::from_array(
          Array::make(self.groups.length() * 2, -1),
        ),
      },
    ],
  })
  self.starts.push((prev, state))
  state
}

///|
// Epsilon closure is ordered DFS, with generation-stamped PC deduplication.
// Histories store register identities, never concrete input offsets.
fn Regex::build_edge(self : Regex, base : Int, symbol : Int) -> Unit {
  let key = self.states[base / self.width()]
  let next_cat = if symbol == self.repr.length() {
    Category::inexistant()
  } else {
    self.categories[symbol]
  }
  self.generation += 1
  if self.generation == 0 {
    self.seen.fill(0)
    self.generation = 1
  }
  let generation = self.generation
  let stack : Array[TaggedThread] = []
  for i = key.threads.length() - 1; i >= 0; i = i - 1 {
    stack.push(key.threads[i])
  }
  let frontier : Array[TaggedThread] = []
  while stack.pop() is Some(thread) {
    if self.seen[thread.pc] == generation {
      continue
    }
    self.seen[thread.pc] = generation
    match self.nodes[thread.pc] {
      Accept => {
        frontier.push(thread)
        // Lower-priority paths can never beat this accepted candidate.
        break
      }
      Chr(chars, next) =>
        if symbol < self.repr.length() && chars.contains(symbol) {
          frontier.push({ pc: next, tags: thread.tags, })
        }
      Split(alts) =>
        for i = alts.length() - 1; i >= 0; i = i - 1 {
          stack.push({ pc: alts[i], tags: thread.tags, })
        }
      Assert(a, next) =>
        if tagged_assertion(a, key.prev, next_cat) {
          stack.push({ pc: next, tags: thread.tags, })
        }
      Tag(tag, next) => {
        let tags = Array::makei(thread.tags.length(), i => thread.tags[i])
        tags[tag] = -2 // SET to current cursor on this edge.
        stack.push({ pc: next, tags: ReadOnlyArray::from_array(tags), })
      }
    }
  }
  // Register identities are stable within the lazy automaton. A transition
  // writes all tags set by its epsilon closure to one fresh register, because
  // they refer to the same input cursor.
  let used = FixedArray::make(self.max_registers + 1, false)
  let mut needs_write = false
  for thread in frontier {
    for source in thread.tags {
      if source == -2 {
        needs_write = true
      }
      if source >= 0 {
        used[source] = true
      }
    }
  }
  let mut slot = 0
  if needs_write {
    while used[slot] {
      slot += 1
    }
    self.max_registers = Int::max(self.max_registers, slot + 1)
  }
  let threads = frontier.map(thread => {
    let tags = if thread.tags.any(source => source == -2) {
      thread.tags.map(source => if source == -2 { slot } else { source })
    } else {
      thread.tags
    }
    { pc: thread.pc, tags, }
  })
  let next = self.stabilize({
    prev: next_cat,
    threads: ReadOnlyArray::from_array(threads),
  })
  let edge = base + symbol
  self.next[edge] = next
  // Physical register zero is a disposable sink; real register r is r + 1.
  self.actions[edge] = if needs_write { slot + 1 } else { 0 }
}
