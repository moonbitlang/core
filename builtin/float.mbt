///|
pub fn Float::to_int(self : Float) -> Int {
  if self != self {
    0
  } else if self > (0x7F7FFFFF).reinterpret_as_float() {
    2147483647
  } else if self < (0xFF7FFFFF).reinterpret_as_float() {
    -2147483648
  } else {
    self.unsafe_to_int()
  }
}
