///|
pub fn Double::to_int(self : Double) -> Int {
  if self != self {
    0
  } else if self > 0x7FEFFFFFFFFFFFFFL.reinterpret_as_double() {
    2147483647
  } else if self < 0xFFEFFFFFFFFFFFFFL.reinterpret_as_double() {
    -2147483648
  } else {
    self.unsafe_to_int()
  }
}
