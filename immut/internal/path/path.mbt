///|
/// A Path is a binary string divided into several segments, for example:
/// 0b11_10000_10101_00100_11111_01010
/// where the last segment is 10000, and the first segment is 01010.
pub(all) type T UInt derive(Eq)

///|
const SEGMENT_LENGTH : Int = 5

///|
const INDEX_MASK : UInt = (1 << SEGMENT_LENGTH) - 1

///|
const SEGMENT_NUM : Int = 32 / SEGMENT_LENGTH

///|
const HEAD_TAG : UInt = 0xffffffffU << (SEGMENT_LENGTH * SEGMENT_NUM)

///|
pub fn[A : Hash] T::of(key : A) -> T {
  key.hash().reinterpret_as_uint() | HEAD_TAG
}

///|
/// If SEGMENT_LENGTH == 5, MAX_TAIL == 0b11_11111
const MAX_TAIL : UInt = 0xffffffffU >> (SEGMENT_LENGTH * (SEGMENT_NUM - 1))

///|
pub fn T::is_last(self : T) -> Bool {
  self._ <= MAX_TAIL
}

///|
pub fn T::push(self : T, idx : Int) -> T {
  (self._ << SEGMENT_LENGTH) | idx.reinterpret_as_uint()
}

///|
pub fn T::idx(self : T) -> Int {
  (self._ & INDEX_MASK).reinterpret_as_int()
}

///|
pub fn T::next(self : T) -> T {
  self._ >> SEGMENT_LENGTH
}
