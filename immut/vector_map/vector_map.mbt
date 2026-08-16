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
/// Create an empty map. `O(1)`.
#as_free_fn
pub fn[K, V] VectorMap::new() -> VectorMap[K, V] {
  { index: @hashmap.new(), spine: @vector.new(), size: 0 }
}

///|
/// Create a map holding a single entry. `O(1)`.
#as_free_fn
pub fn[K : Hash, V] VectorMap::singleton(key : K, value : V) -> VectorMap[K, V] {
  {
    index: @hashmap.singleton(key, 0),
    spine: @vector.singleton(Some((key, value))),
    size: 1,
  }
}

///|
/// Create a map from an array of key-value pairs, in the array's order.
///
/// A repeated key keeps the position of its **first** occurrence and the value
/// of its **last**, matching what repeated `add`s would produce.
///
/// One trie descent per input pair, plus a second for each pair that introduces
/// a key, so `O(m log n)` for `m` pairs — repeated keys cost the lookup only.
///
/// # Example
///
/// ```mbt check
/// test {
///   let m = @vector_map.VectorMap([(3, "c"), (1, "a"), (3, "z")])
///   debug_inspect(
///     m.to_array(),
///     content=(
///       #|[(3, "z"), (1, "a")]
///     ),
///   )
/// }
/// ```
pub fn[K : Eq + Hash, V] VectorMap::VectorMap(
  arr : ArrayView[(K, V)],
) -> VectorMap[K, V] {
  from_pairs(arr.iter())
}

///|
/// Create a map from an iterator of key-value pairs, in the iterator's order.
///
/// A repeated key keeps the position of its first occurrence and the value of
/// its last. One trie descent per pair, plus a second for each pair that
/// introduces a key, so `O(m log n)` for `m` pairs.
#as_free_fn
#alias(from_iterator, deprecated)
#as_free_fn(from_iterator, deprecated)
pub fn[K : Eq + Hash, V] VectorMap::from_iter(
  iter : Iter[(K, V)],
) -> VectorMap[K, V] {
  from_pairs(iter)
}

///|
/// Build a dense map in a single pass: the first sighting of a key appends a
/// slot, every later one overwrites that slot's value in place.
fn[K : Eq + Hash, V] from_pairs(iter : Iter[(K, V)]) -> VectorMap[K, V] {
  let entries : Array[(K, V)] = []
  let mut index : @hashmap.HashMap[K, Int] = @hashmap.new()
  for kv in iter {
    let (key, value) = kv
    match index.get(key) {
      // Keep the key first inserted, so that the retained key and the
      // retained position always come from the same occurrence.
      Some(slot) => entries[slot] = (entries[slot].0, value)
      None => {
        index = index.add(key, entries.length())
        entries.push((key, value))
      }
    }
  }
  {
    index,
    spine: @vector.from_iter(entries.iter().map(kv => Some(kv))),
    size: entries.length(),
  }
}

///|
/// The number of entries in the map. `O(1)` — the count is stored, unlike
/// `@immut/hashmap.HashMap::length` which walks the whole trie.
#alias(size, deprecated)
pub fn[K, V] VectorMap::length(self : VectorMap[K, V]) -> Int {
  self.size
}

///|
/// Whether the map holds no entries. `O(1)`.
pub fn[K, V] VectorMap::is_empty(self : VectorMap[K, V]) -> Bool {
  self.size == 0
}

///|
/// Look up a key. One trie descent and one spine descent, so `O(log n)`.
#alias(find, deprecated)
pub fn[K : Eq + Hash, V] VectorMap::get(self : VectorMap[K, V], key : K) -> V? {
  guard self.index.get(key) is Some(slot) else { return None }
  guard self.spine.get(slot) is Some(Some((_, value))) else { return None }
  Some(value)
}

///|
/// Look up a key, aborting when it is absent. `O(log n)`, as for `get`.
#alias("_[_]")
pub fn[K : Eq + Hash, V] VectorMap::at(self : VectorMap[K, V], key : K) -> V {
  guard! self.get(key) is Some(value)
  value
}

///|
/// Whether the map holds an entry for `key`. One trie descent and no spine
/// access at all, so `O(log n)` and cheaper than `get`.
pub fn[K : Eq + Hash, V] VectorMap::contains(
  self : VectorMap[K, V],
  key : K,
) -> Bool {
  self.index.contains(key)
}

///|
/// Add an entry, returning a new map.
///
/// A key already present keeps its position and only its value is replaced; a
/// new key is appended after every existing entry. Removing a key and adding it
/// back therefore moves it to the end.
///
/// `O(log n)` for a key already present. For a new key `O(log n)` amortised,
/// but `O(n)` on the call that carries the spine over the rebuild threshold.
///
/// # Example
///
/// ```mbt check
/// test {
///   let m = @vector_map.VectorMap([("a", 1), ("b", 2)])
///   // updating in place keeps "a" first
///   debug_inspect(
///     m.add("a", 10).keys().to_array(),
///     content=(
///       #|["a", "b"]
///     ),
///   )
///   // re-adding after a removal appends
///   debug_inspect(
///     m.remove("a").add("a", 10).keys().to_array(),
///     content=(
///       #|["b", "a"]
///     ),
///   )
/// }
/// ```
pub fn[K : Eq + Hash, V] VectorMap::add(
  self : VectorMap[K, V],
  key : K,
  value : V,
) -> VectorMap[K, V] {
  match self.index.get(key) {
    Some(slot) => {
      // The key already stored is the one kept, so that the retained key and
      // the retained position always come from the same insertion.
      guard! self.spine.get(slot) is Some(Some((old_key, _)))
      {
        index: self.index,
        spine: self.spine.set(slot, Some((old_key, value))),
        size: self.size,
      }
    }
    None => {
      // Appending grows the spine, which can carry it over the length at which
      // holes left by earlier removals become worth reclaiming — a spine of 31
      // slots holding one entry is under the threshold and so is left alone,
      // but the entry appended after it is not. Hence the check here as well as
      // in `remove`: the ratio is a property of the spine, not of one operation.
      let map = {
        index: self.index.add(key, self.spine.length()),
        spine: self.spine.push(Some((key, value))),
        size: self.size + 1,
      }
      if map.should_compact() {
        map.compact()
      } else {
        map
      }
    }
  }
}

///|
/// Remove a key, returning a new map. A key that is absent returns the receiver
/// itself.
///
/// `O(log n)` amortised. The worst case is a call that reclaims: trimming `k`
/// uncovered holes costs `k` spine pops, each of which may copy a path, so
/// `O(k log n)`; a rebuild costs `O(n)`. The amortisation holds along one line
/// of descent only — repeatedly removing from a version taken just before a
/// trim or a rebuild pays for it each time.
pub fn[K : Eq + Hash, V] VectorMap::remove(
  self : VectorMap[K, V],
  key : K,
) -> VectorMap[K, V] {
  guard self.index.get(key) is Some(slot) else { return self }
  // Punching a hole keeps every surviving slot where it is, so the rest of the
  // index stays valid; trimming afterwards keeps last-in-first-out deletion
  // from leaving anything behind at all.
  let map = {
    index: self.index.remove(key),
    spine: trim_trailing(self.spine.set(slot, None)),
    size: self.size - 1,
  }
  if map.should_compact() {
    map.compact()
  } else {
    map
  }
}

///|
/// Replace, insert, or remove the entry for `key` in one step: `f` sees the
/// current value if there is one, and its result becomes the new value, or
/// removes the key when it is `None`.
///
/// A lookup followed by an `add` or a `remove`, so `O(log n)` amortised, with
/// the reclamation worst cases those two carry.
///
/// # Example
///
/// ```mbt check
/// test {
///   let m = @vector_map.VectorMap([("a", 1)])
///   let bumped = m.update("a", v => Some(v.unwrap_or(0) + 1))
///   debug_inspect(bumped.get("a"), content="Some(2)")
///   let cleared = m.update("a", _ => None)
///   inspect(cleared.is_empty(), content="true")
/// }
/// ```
pub fn[K : Eq + Hash, V] VectorMap::update(
  self : VectorMap[K, V],
  key : K,
  f : (V?) -> V? raise?,
) -> VectorMap[K, V] raise? {
  match f(self.get(key)) {
    Some(value) => self.add(key, value)
    None => self.remove(key)
  }
}

///|
/// Drop tombstones off the end of the spine, restoring the invariant that a
/// non-empty spine ends in a live entry.
fn[K, V] trim_trailing(
  spine : @vector.Vector[(K, V)?],
) -> @vector.Vector[(K, V)?] {
  for s = spine {
    guard s.peek() is Some(None) else { break s }
    guard s.pop() is Some(rest) else { break s }
    continue rest
  }
}

///|
/// Whether the tombstones are worth an `O(n)` rebuild.
///
/// Rebuilding once the holes outnumber the live entries keeps the wasted slots
/// at or below half — the comparison is strict, so an even split stands — and
/// makes each rebuild pay for the `Omega(n)` removals that caused it. Note that
/// the threshold compares `holes > size` rather than `size < length / 2`: the
/// two disagree on odd spines carrying exactly one hole more than they carry
/// entries, where integer division rounds the majority away — at length 33 with
/// 16 entries and 17 holes, `size < length / 2` is `16 < 16` and never fires.
fn[K, V] VectorMap::should_compact(self : VectorMap[K, V]) -> Bool {
  let length = self.spine.length()
  length >= MIN_COMPACT_LENGTH && length - self.size > self.size
}

///|
/// Rebuild the spine dense and renumber the index onto the new slots.
///
/// No key is hashed again: `HashMap::map` walks the existing trie and replaces
/// values in place, preserving its shape.
fn[K, V] VectorMap::compact(self : VectorMap[K, V]) -> VectorMap[K, V] {
  let remap = FixedArray::make(self.spine.length(), 0)
  let kept : Array[(K, V)?] = Array::new(capacity=self.size)
  self.spine.eachi((slot, entry) => {
    if entry is Some(_) {
      remap[slot] = kept.length()
      kept.push(entry)
    }
  })
  {
    index: self.index.map((_, slot) => remap[slot]),
    spine: @vector.from_iter(kept.iter()),
    size: kept.length(),
  }
}
