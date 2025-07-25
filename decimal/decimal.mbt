pub struct Decimal {
  mantissa: @bigint.BigInt 
  scale: Int              
}

pub fn from_parts(mantissa: @bigint.BigInt, scale: Int) -> Decimal {
  { mantissa, scale }
}

/// 从一个普通整数创建 Decimal
pub fn from_int(value: Int) -> Decimal {
  { mantissa: @bigint.BigInt::from_int(value), scale: 0 }
}
pub fn to_string(self: Decimal) -> String raise @string.CreatingViewError {
  let sign = if self.mantissa < @bigint.BigInt::from_int(0) {
    "-"
  } else {
    ""
  };
  let abs_mantissa = if self.mantissa < @bigint.BigInt::from_int(0) {
    -self.mantissa
  } else {
    self.mantissa
  };

  let mantissa_str = abs_mantissa.to_string();
  let len = mantissa_str.length();
  let scale = self.scale;

  if scale == 0 {
    return sign + mantissa_str;
  }

  let result = if scale >= len {
    "0." + "0".repeat(scale - len) + mantissa_str
  } else {
    let pivot = len - scale;
    mantissa_str[0:pivot].data() + "." + mantissa_str[pivot:len].data()
  };

  sign + result
}

fn normalize(d1: Decimal, d2: Decimal) -> (@bigint.BigInt, @bigint.BigInt) {
  if d1.scale == d2.scale {
    return (d1.mantissa, d2.mantissa);
  } else if d1.scale > d2.scale {
    let diff = d1.scale - d2.scale;
    let base = @bigint.BigInt::from_int(10);
    let factor = @bigint.BigInt::pow(base, @bigint.BigInt::from_int(diff));
    let new_mantissa2 = d2.mantissa * factor;
    (d1.mantissa, new_mantissa2)
  } else { // d2.scale > d1.scale
    let diff = d2.scale - d1.scale;
    let base = @bigint.BigInt::from_int(10);
    let factor = @bigint.BigInt::pow(base, @bigint.BigInt::from_int(diff));
    let new_mantissa1 = d1.mantissa * factor;
    (new_mantissa1, d2.mantissa)
  }
}

impl Eq for Decimal {
  fn op_equal(self: Decimal, other: Decimal) -> Bool {
    let (m1, m2) = normalize(self, other);
    m1 == m2
  }
} 


impl Compare for Decimal {
  // 核心方法
  fn compare(self: Decimal, other: Decimal) -> Int {
    let (m1, m2) = normalize(self, other);
    @bigint.BigInt::compare(m1, m2)
  }
}
