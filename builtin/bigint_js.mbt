// Copyright 2024 International Digital Economy Academy
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

type BigInt

pub fn BigInt::from_string(str : String) -> BigInt {
  if str.length() == 0 {
    abort("empty string")
  }
  BigInt::js_from_string(str)
}

extern "js" fn BigInt::js_from_string(str : String) -> BigInt =
  #|(x) => BigInt(x)

pub impl Show for BigInt with output(self, logger) {
  logger.write_string(self.to_string())
}

pub extern "js" fn to_string(self : BigInt) -> String =
  #|(x) => String(x)

pub extern "js" fn BigInt::from_hex(str : String) -> BigInt =
  #|(x) => x.startsWith('-') ? -BigInt(`0x${x.slice(1)}`) : BigInt(`0x${x}`)

pub extern "js" fn to_hex(self : BigInt, ~uppercase : Bool = true) -> String =
  #|(x, uppercase) => {
  #|  const r = x.toString(16);
  #|  return uppercase ? r.toUpperCase() : r;
  #|}

extern "js" fn hex2(b : Byte) -> String =
  #|(x) => x.toString(16).padStart(2, '0')

pub fn BigInt::from_octets(octets : Bytes, ~signum : Int = 1) -> BigInt {
  if signum < 0 {
    return -1N * BigInt::from_octets(octets, signum=1)
  }
  if signum == 0 {
    return 0N
  }
  let str = StringBuilder::new()
  str.write_string("0x")
  for octet in octets {
    str.write_string(hex2(octet))
  }
  BigInt::from_string(str.to_string())
}

pub fn to_octets(self : BigInt, ~length? : Int) -> Bytes {
  if self < 0 {
    abort("negative BigInt")
  }

  // TODO: Optimize this
  let buf = []
  fn to_bytes() {
    let len = buf.length()
    let len = match length {
      Some(len2) =>
        if len2 <= 0 {
          abort("negative length")
        } else if len2 > len {
          len2
        } else {
          len
        }
      None => len
    }
    let res = Bytes::new(len)
    let mut j = res.length() - 1
    for octet in buf {
      res[j] = octet
      j -= 1
    }
    res
  }

  if self == 0 {
    buf.push(0)
    return to_bytes()
  }
  let mut x = self
  while x > 0 {
    buf.push(x.to_byte())
    x = x >> 8
  }
  to_bytes()
}

pub extern "js" fn compare(self : BigInt, other : BigInt) -> Int =
  #|(x, y) => x < y ? -1 : x > y ? 1 : 0

pub extern "js" fn op_equal(self : BigInt, other : BigInt) -> Bool =
  #|(x, y) => x === y

pub extern "js" fn BigInt::from_int(x : Int) -> BigInt =
  #|(x) => BigInt(x)

pub extern "js" fn BigInt::from_int64(x : Int64) -> BigInt =
  #|(x) => BigInt(x.hi) * 0x100000000n + BigInt(x.lo >>> 0)

pub extern "js" fn BigInt::from_uint64(x : UInt64) -> BigInt =
  #|(x) => BigInt(x.hi >>> 0) * 0x100000000n + BigInt(x.lo >>> 0)

pub extern "js" fn is_zero(self : BigInt) -> Bool =
  #|(x) => x === 0n

pub extern "js" fn op_neg(self : BigInt) -> BigInt =
  #|(x) => -x

pub extern "js" fn op_add(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x + y

pub extern "js" fn op_sub(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x - y

pub extern "js" fn op_mul(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x * y

pub extern "js" fn op_div(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x / y

pub extern "js" fn op_mod(self : BigInt, other : BigInt) -> BigInt =
  #|(x, y) => x % y

pub extern "js" fn pow(
  self : BigInt,
  other : BigInt,
  ~modulus : BigInt = 1N
) -> BigInt =
  #|(x, y, z) => (x ** y) % z

extern "js" fn to_byte(self : BigInt) -> Byte =
  #|(x) => Number(BigInt.asUintN(8, x)) | 0

pub fn op_shl(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    abort("negative shift count")
  }
  self.js_shl(n)
}

pub fn op_shr(self : BigInt, n : Int) -> BigInt {
  if n < 0 {
    abort("negative shift count")
  }
  self.js_shr(n)
}

extern "js" fn js_shl(self : BigInt, other : Int) -> BigInt =
  #|(x, y) => x << BigInt(y)

extern "js" fn js_shr(self : BigInt, other : Int) -> BigInt =
  #|(x, y) => x >> BigInt(y)
