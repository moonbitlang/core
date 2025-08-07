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
