// Copyright 2024 International Digital Economy Academy
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

// TODO: error handling when int overflow
fn power_2_above(x : Int, n : Int) -> Int {
  for i = x {
    if i >= n {
      break i
    }
    continue i.lsl(1)
  }
}

test "power_2_above" {
  inspect(power_2_above(1, 15), content="16")?
  inspect(power_2_above(1, 16), content="16")?
  inspect(power_2_above(1, 17), content="32")?
  inspect(power_2_above(1, 32), content="32")?
  inspect(power_2_above(128, 33), content="128")?
}

/// Create new hash map.
pub fn HashMap::new[K, V](~capacity : Int = 8) -> HashMap[K, V] {
  let capacity = power_2_above(8, capacity)
  { size: 0, capacity, entries: FixedArray::make(capacity, None) }
}

/// Create new hash map from array.
pub fn HashMap::from_array[K : Hash + Eq, V](
  arr : Array[(K, V)]
) -> HashMap[K, V] {
  let m = new(capacity=arr.length())
  arr.iter(fn(e) { m.set(e.0, e.1) })
  m
}

/// Set a key-value pair into hash map.
/// @alert unsafe "Panic if the hash map is full."
pub fn set[K : Hash + Eq, V](self : HashMap[K, V], key : K, value : V) -> Unit {
  if self.size >= self.capacity.lsr(1) {
    self.grow()
  }
  let hash = key.hash()
  for idx = hash.land(self.capacity - 1), entry = { psl: 0, hash, key, value } {
    match self.entries[idx] {
      None => {
        self.entries[idx] = Some(entry)
        self.size += 1
        break
      }
      Some(curr_entry) => {
        if curr_entry.hash == entry.hash && curr_entry.key == entry.key {
          curr_entry.value = entry.value
          break
        }
        let curr_entry = if entry.psl > curr_entry.psl {
          self.entries[idx] = Some(entry)
          curr_entry
        } else {
          entry
        }
        curr_entry.psl += 1
        continue (idx + 1).land(self.capacity - 1), curr_entry
      }
    }
  }
}

pub fn op_set[K : Hash + Eq, V](
  self : HashMap[K, V],
  key : K,
  value : V
) -> Unit {
  self.set(key, value)
}

/// Get the value associated with a key.
pub fn get[K : Hash + Eq, V](self : HashMap[K, V], key : K) -> Option[V] {
  let hash = key.hash()
  for i = 0, idx = hash.land(self.capacity - 1) {
    // if i == self.capacity {
    //   panic()
    // }
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          break Some(entry.value)
        }
        if i > entry.psl {
          break None
        }
        continue i + 1, (idx + 1).land(self.capacity - 1)
      }
      None => break None
    }
  }
}

pub fn op_get[K : Hash + Eq, V](self : HashMap[K, V], key : K) -> Option[V] {
  self.get(key)
}

/// Get the value associated with a key, 
/// returns the provided default value if the key does not exist.
pub fn get_or_default[K : Hash + Eq, V](
  self : HashMap[K, V],
  key : K,
  default : V
) -> V {
  match self.get(key) {
    Some(v) => v
    None => default
  }
}

/// Check if the hash map contains a key.
pub fn contains[K : Hash + Eq, V](self : HashMap[K, V], key : K) -> Bool {
  match self.get(key) {
    Some(_) => true
    None => false
  }
}

/// Remove a key-value pair from hash map.
pub fn remove[K : Hash + Eq, V](self : HashMap[K, V], key : K) -> Unit {
  let hash = key.hash()
  for i = 0, idx = hash.land(self.capacity - 1) {
    match self.entries[idx] {
      Some(entry) => {
        if entry.hash == hash && entry.key == key {
          self.entries[idx] = None
          self.shift_back(idx)
          self.size -= 1
          break
        }
        if i > entry.psl {
          break
        }
        continue i + 1, (idx + 1).land(self.capacity - 1)
      }
      None => break
    }
  }
}

fn shift_back[K : Hash, V](self : HashMap[K, V], start_index : Int) -> Unit {
  for prev = start_index, curr = (start_index + 1).land(self.capacity - 1) {
    match self.entries[curr] {
      Some({ psl, hash, key, value, .. }) => {
        if psl == 0 {
          break
        }
        self.entries[prev] = Some({ psl: psl - 1, hash, key, value })
        self.entries[curr] = None
        continue curr, (curr + 1).land(self.capacity - 1)
      }
      None => break
    }
  }
}

fn grow[K : Hash + Eq, V](self : HashMap[K, V]) -> Unit {
  let old_entries = self.entries
  self.entries = FixedArray::make(self.capacity.lsl(1), None)
  self.capacity = self.capacity * 2
  self.size = 0
  for i = 0; i < old_entries.length(); i = i + 1 {
    match old_entries[i] {
      Some({ key, value, .. }) => self.set(key, value)
      None => ()
    }
  }
}
