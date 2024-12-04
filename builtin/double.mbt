///|
pub fn Double::to_int(self : Double) -> Int {
  if self != self {
    0
  } else if self >= 2147483647 {
    2147483647
  } else if self <= -2147483648 {
    -2147483648
  } else {
    self.unsafe_to_int()
  }
}
