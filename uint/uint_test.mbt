test "UInt to byte" {
  let a = 10U.to_byte()
  inspect!(a, content="b'\\x0A'")
  let b = 255U.to_byte()
  inspect!(b, content="b'\\xFF'")
  let c = 10UL.to_byte()
  inspect!(c, content="b'\\x0A'")
  let d = 255UL.to_byte()
  inspect!(d, content="b'\\xFF'")
  let f = 24U.lsr(16)
  let e = f.to_byte()
  inspect!(e, content="b'\\x00'")
  let f = 24U.lsr(64)
  let e = f.to_byte()
  inspect!(e, content="b'\\x18'")
  // to_byte
  let u = 0xDEADBEEFU
  let b = u.to_byte()
  inspect!(b, content="b'\\xEF'")
  let u = 0x87654321U
  let b = u.to_byte()
  inspect!(b, content="b'\\x21'")
  let u = 0xFFFFU
  let b = u.to_byte()
  inspect!(b, content="b'\\xFF'")
  let u = 0xFFU
  let b = u.to_byte()
  inspect!(b, content="b'\\xFF'")
  let u = 0x12345678U
  let b = u.to_byte()
  inspect!(b, content="b'\\x78'")
  let u = 0U
  let b = u.to_byte()
  inspect!(b, content="b'\\x00'")
}
