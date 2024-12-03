///|
fn scalbn(self : Double, exp : Int) -> Double {
  let mut n = exp
  let mut y : Double = self
  if n > 1023 {
    y *= 0x1.0p1023
    n -= 1023
    if n > 1023 {
      y *= 0x1.0p1023
      n -= 1023
      if n > 1023 {
        n = 1023
      }
    }
  } else if n < -1022 {
    // make sure final n < -53 to avoid double
    // rounding in the subnormal range
    y *= 0x1.0p-1022 * 0x1.0p53
    n += 1022 - 53
    if n < -1022 {
      y *= 0x1.0p-1022 * 0x1.0p53
      n += 1022 - 53
      if n < -1022 {
        n = -1022
      }
    }
  }
  let ui = (0x3ff + n).to_uint64() << 52
  return y * ui.reinterpret_as_double()
}
