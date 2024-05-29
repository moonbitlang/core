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

fn debug_entries[K : Show, V : Show](self : LinkedHashMap[K, V]) -> String {
  let buf = Buffer::make(0)
  for i = 0; i < self.entries.length(); i = i + 1 {
    if i > 0 {
      buf.write_char(',')
    }
    match self.entries[i] {
      Empty => buf.write_char('_')
      Valid(~psl, ~key, ~value, ..) =>
        buf.write_string("(\(psl),\(key),\(value))")
    }
  }
  buf.to_string()
}

fn debug_linked_list[K : Show, V : Show](self : LinkedHashMap[K, V]) -> String {
  let buf = Buffer::make(0)
  loop self.head {
    Some(Valid(~key, ~value, ~prev, ~next, ~hash, ..)) => {
      buf.write_char('(')
      buf.write_string("\(hash),\(key),\(value)")
      buf.write_string(",prev:")
      match prev {
        Some(Valid(~hash, ..)) => buf.write_string(hash.to_string())
        None | Some(Empty) => buf.write_char('_')
      }
      buf.write_string(",next:")
      match next {
        Some(Valid(~hash, ..)) => buf.write_string(hash.to_string())
        None | Some(Empty) => buf.write_char('_')
      }
      buf.write_char(')')
      buf.write_char('\n')
      continue next
    }
    None | Some(Empty) => buf.write_string("end")
  }
  buf.to_string()
}

/// Get the number of key-value pairs in the map.
pub fn size[K, V](self : LinkedHashMap[K, V]) -> Int {
  self.size
}

/// Get the capacity of the map.
pub fn capacity[K, V](self : LinkedHashMap[K, V]) -> Int {
  self.capacity
}

/// Check if the hash map is empty.
pub fn is_empty[K, V](self : LinkedHashMap[K, V]) -> Bool {
  self.size == 0
}

/// Iterate over all key-value pairs of the map in the order of insertion.
pub fn iter[K, V](self : LinkedHashMap[K, V], f : (K, V) -> Unit) -> Unit {
  loop self.head {
    Some(Valid(~key, ~value, ~next, ..)) => {
      f(key, value)
      continue next
    }
    None | Some(Empty) => break
  }
}

/// Iterate over all key-value pairs of the map in the order of insertion, with index.
pub fn iteri[K, V](self : LinkedHashMap[K, V], f : (Int, K, V) -> Unit) -> Unit {
  loop 0, self.head {
    idx, Some(Valid(~key, ~value, ~next, ..)) => {
      f(idx, key, value)
      continue idx + 1, next
    }
    _, None | Some(Empty) => break
  }
}

/// Clears the map, removing all key-value pairs. Keeps the allocated space.
pub fn clear[K, V](self : LinkedHashMap[K, V]) -> Unit {
  self.entries.fill(Empty)
  self.size = 0
  self.head = None
  self.tail = None
}

/// Returns the iterator of the hash map, provide elements in the order of insertion.
pub fn as_iter[K, V](self : LinkedHashMap[K, V]) -> @iter.Iter[(K, V)] {
  @iter.Iter::_unstable_internal_make(
    fn(yield) {
      loop self.head {
        Some(Valid(~key, ~value, ~next, ..)) => {
          if yield((key, value)).not() {
            break false
          }
          continue next
        }
        None | Some(Empty) => break true
      }
    },
  )
}

/// Converts the hash map to an array.
pub fn to_array[K, V](self : LinkedHashMap[K, V]) -> Array[(K, V)] {
  let arr = []
  loop self.head {
    Some(Valid(~key, ~value, ~next, ..)) => {
      arr.push((key, value))
      continue next
    }
    None | Some(Empty) => break
  }
  arr
}
