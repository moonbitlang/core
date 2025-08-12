///|
pub struct Decimal {
  mantissa : @bigint.BigInt
  scale : Int
}

///|
pub fn from_parts(mantissa : @bigint.BigInt, scale : Int) -> Decimal {
  { mantissa, scale }
}

///| Create a Decimal from a regular integer
pub fn from_int(value : Int) -> Decimal {
  { mantissa: @bigint.BigInt::from_int(value), scale: 0 }
}

///|
pub impl Show for Decimal with output(self, logger) {
  let sign = if self.mantissa < @bigint.BigInt::from_int(0) { "-" } else { "" }

  let abs_m = if self.mantissa < @bigint.BigInt::from_int(0) {
    -self.mantissa
  } else {
    self.mantissa
  }

  let mantissa_str = abs_m.to_string().to_string()
  let len = mantissa_str.length()
  let scale = self.scale

  if scale == 0 {
    logger.write_string(sign)
    logger.write_string(mantissa_str)
    return
  }

  if scale >= len {
    logger.write_string(sign)
    logger.write_string("0.")
    logger.write_string("0".repeat(scale - len))
    logger.write_string(mantissa_str)
    return
  }

  if scale < 0 {
    logger.write_string(sign)
    logger.write_string(mantissa_str)
    logger.write_string("0".repeat(-scale))
    return
  }

  let pivot = len - scale
  logger.write_string(sign)
  logger.write_substring(mantissa_str, 0, pivot)
  logger.write_string(".")
  let remaining = len - pivot
  logger.write_substring(mantissa_str, pivot, remaining)
}

///|
fn normalize(d1 : Decimal, d2 : Decimal) -> (@bigint.BigInt, @bigint.BigInt) {
  if d1.scale == d2.scale {
    return (d1.mantissa, d2.mantissa)
  } else if d1.scale > d2.scale {
    let diff = d1.scale - d2.scale
    let base = @bigint.BigInt::from_int(10)
    let factor = @bigint.BigInt::pow(base, @bigint.BigInt::from_int(diff))
    let new_mantissa2 = d2.mantissa * factor
    (d1.mantissa, new_mantissa2)
  } else { // d2.scale > d1.scale
    let diff = d2.scale - d1.scale
    let base = @bigint.BigInt::from_int(10)
    let factor = @bigint.BigInt::pow(base, @bigint.BigInt::from_int(diff))
    let new_mantissa1 = d1.mantissa * factor
    (new_mantissa1, d2.mantissa)
  }
}

///|
pub impl Eq for Decimal with op_equal(self, other) {
  if self.scale == other.scale && self.mantissa == other.mantissa {
    return true
  }
  let (m1, m2) = normalize(self, other)
  m1 == m2
}

///|
pub impl Compare for Decimal with compare(self, other) {
  let (m1, m2) = normalize(self, other)
  @bigint.BigInt::compare(m1, m2)
}
