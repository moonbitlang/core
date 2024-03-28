pub fn to_string(self : Int64) -> String {
  fn abs(n : Int64) -> Int64 {
    if n < 0L {
      0L - n
    } else {
      n
    }
  }

  // The min and max value of i64 are -9223372036854775808 and 9223372036854775807,
  // so max=20 is enough.

  let buf = Buffer::make(20)
  if self < 0L {
    buf.write_char('-')
  }
  fn write_digits(num) {
    let num2 = num / 10L
    if num2 != 0L {
      write_digits(num2)
    }
    buf.write_char(Char::from_int(abs(num % 10L).to_int() + 48))
  }

  write_digits(self)
  buf.to_string()
}

pub fn debug_write(self : Int64, buf : Buffer) -> Unit {
  buf.write_string(self.to_string())
}
