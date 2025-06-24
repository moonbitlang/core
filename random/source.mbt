///|
pub fn next_uint64(self : &Source) -> UInt64 {
  Rand(self).uint64()
}

///|
pub fn next_uint(self : &Source) -> UInt {
  Rand(self).uint()
}

///|
pub fn next_int64(self : &Source) -> Int64 {
  Rand(self).uint64().reinterpret_as_int64()
}

///|
pub fn next_two_uint(self : &Source) -> (UInt, UInt) {
  let u1 = Rand(self).uint()
  let u2 = Rand(self).uint()
  (u1, u2)
}

///|
pub fn next_int(self : &Source) -> Int {
  Rand(self).uint().reinterpret_as_int()
}

///|
pub fn next_positive_int(self : &Source) -> Int {
  Rand(self).int()
}

///|
pub fn next_float(self : &Source) -> Float {
  Rand(self).float()
}

///|
pub fn next_double(self : &Source) -> Double {
  Rand(self).double()
}

///|
pub fn next_bigint(self : &Source, bits : Int) -> @bigint.BigInt {
  Rand(self).bigint(bits)
}

///|
pub fn split(self : &Source) -> &Source {
  self
}
