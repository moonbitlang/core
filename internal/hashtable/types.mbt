/// A mutable hash table implements with Robin Hood hashing.
///
/// reference:
/// - <https://programming.guide/robin-hood-hashing.html>
/// - <https://cs.uwaterloo.ca/research/tr/1986/CS-86-14.pdf>

///|
/// Mutable hash table, not thread safe.
pub(all) struct HashTable[K] {
  mut entries : FixedArray[K?]
  mut capacity : Int // current capacity
  mut capacity_mask : Int // capacity_mask = capacity - 1, used to find idx
  mut size : Int // active key count
  mut grow_at : Int // threshold that triggers grow
}

///|
pub fn[K] HashTable::new(capacity~ : Int = 8) -> HashTable[K] {
  let capacity = capacity.next_power_of_two()
  {
    entries: FixedArray::make(capacity, None),
    capacity,
    capacity_mask: capacity - 1,
    size: 0,
    grow_at: calc_grow_threshold(capacity),
  }
}

///|
fn calc_grow_threshold(capacity : Int) -> Int {
  capacity * 13 / 16
}

///|
pub(open) trait HashEntry {
  psl(Self) -> Int
  set_psl(Self, Int) -> Unit
  hash(Self) -> Int
}

///|
#locals(is_)
#inline
pub fn[K : HashEntry] HashTable::remove(
  table : Self[K],
  hash : Int,
  start_index : Int,
  is_ : (K) -> Bool,
) -> Unit {
  for i = 0, idx = start_index {
    match table.entries[idx] {
      Some(entry) => {
        if entry.hash() == hash && is_(entry) {
          table.entries[idx] = None
          table.shift_back(idx)
          table.size -= 1
          break
        }
        if i > entry.psl() {
          break
        }
        continue i + 1, (idx + 1) & table.capacity_mask
      }
      None => break
    }
  }
}

///|
fn[K : HashEntry] HashTable::shift_back(
  table : Self[K],
  start_index : Int,
) -> Unit {
  for prev = start_index, curr = (start_index + 1) & table.capacity_mask {
    match table.entries[curr] {
      Some(entry) => {
        let psl = entry.psl()
        if psl == 0 {
          break
        }
        entry.set_psl(psl - 1)
        table.entries[prev] = Some(entry)
        table.entries[curr] = None
        continue curr, (curr + 1) & table.capacity_mask
      }
      None => break
    }
  }
}

///|
#locals(is_)
#inline
pub fn[K : HashEntry] HashTable::contains(
  table : Self[K],
  hash : Int,
  start_index : Int,
  is_ : (K) -> Bool,
) -> Bool {
  for i = 0, idx = start_index {
    guard table.entries[idx] is Some(entry) else { return false }
    if entry.hash() == hash && is_(entry) {
      return true
    }
    if i > entry.psl() {
      return false
    }
    continue i + 1, (idx + 1) & table.capacity_mask
  }
}

///|
pub fn[K] HashTable::clear(table : Self[K]) -> Unit {
  table.entries.fill(None)
  table.size = 0
}
