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

/// UUID that complies with RFC 4122.
///
/// UUID objects are immutable, hashable and usable as mapping keys.
/// The Display of UUIDs is like `12345678-1234-1234-1234-123456789abc`;
/// UUIDs can be constructed using such strings, or 16-bytes strings with big-
/// endian byte order.
///
/// # Usage
///
/// ```moonbit
/// let u = @uuid.from_hex("ddf99703-742f-7505-4c54-df36a9c243fe")
/// let u2 = @uuid.from_bytes(Bytes::[221, 249, 151, 3, 116, 47, 117, 5, 76, 84, 223, 54, 169, 194, 67, 254])
/// @assertion.assert_eq(u, u2)
/// ```
///
/// Construct an RFC-4122-compliant v4 UUID:
///
/// ```moonbit
/// let u = @uuid
///   .from_hex("9558cfadb48547c70f9adf1f75cdef29")
///   .as_version(@uuid.V4)
/// ```
///
struct UUID {
  // XXX: replace with an 128-bit data structure when there is one
  hi : Int64
  lo : Int64
}

/// Constructs a UUID with the given big-endian bytes.
///
/// The produced UUID is not RFC-4122 compliant; see also `as_version()`.
///
pub fn from_bytes(bytes : Bytes) -> Result[UUID, String] {
  if bytes.length() != 16 {
    return Err("requires 16 bytes")
  }
  // XXX: this is ideally Int64::from_bytes() (needs a cheap slicing method)
  let hi = for rv = 0L, i = 0; i < 8; {
    continue rv.lor(bytes[i].to_int64().lsl((7 - i) * 8)), i + 1
  } else {
    rv
  }
  let lo = for rv = 0L, i = 8; i < 16; {
    continue rv.lor(bytes[i].to_int64().lsl((15 - i) * 8)), i + 1
  } else {
    rv
  }
  Ok({ hi, lo })
}

/// The UUID as a 16-byte string.
pub fn to_bytes(self : UUID) -> Bytes {
  // XXX: replace with a cheaper way
  let rv = Bytes::make(16, 0)
  for i = 0; i < 8; i = i + 1 {
    rv[i] = self.hi.lsr((7 - i) * 8).to_int()
  }
  for i = 8; i < 16; i = i + 1 {
    rv[i] = self.lo.lsr((15 - i) * 8).to_int()
  }
  rv
}

test "bytes" {
  let buf = Bytes::[
    201, 130, 251, 104, 223, 80, 76, 161, 145, 248, 186, 162, 4, 9, 229, 185,
  ]
  inspect(from_bytes(buf)?.to_bytes(), content="苉棻僟ꅌꊺऄ맥")? // XXX: this is a terrible Show
  inspect(from_bytes(Bytes::make(15, 0)), content="Err(requires 16 bytes)")?
  inspect(from_bytes(Bytes::make(17, 0)), content="Err(requires 16 bytes)")?
}

fn hex_char_to_int64(c : Char) -> Result[Int64, String] {
  let d = if '0' <= c && c <= '9' {
    c.to_int() - '0'.to_int()
  } else if 'a' <= c && c <= 'f' {
    c.to_int() - 'a'.to_int() + 10
  } else if 'A' <= c && c <= 'F' {
    c.to_int() - 'A'.to_int() + 10
  } else {
    return Err("invalid syntax")
  }
  Ok(d.to_int64())
}

/// Constructs a UUID with the given hexadecimal string.
///
/// This function ignores dashes (`-`) in the given string. The remaining
/// letters must be exactly 32 hexadecimals, or an error will be raised.
///
pub fn from_hex(hex : String) -> Result[UUID, String] {
  // XXX: ideally we should use strconv here, but we don't have sufficient
  // tooling around String yet
  let (hi, i) = for hi = 0L, i = 0, n = 0; n < 16; {
    if i >= hex.length() {
      return Err("not enough hexadecimal in UUID string")
    }
    let c = hex[i]
    if c == '-' {
      continue hi, i + 1, n
    } else {
      let d = hex_char_to_int64(c)?
      continue hi.lor(d.lsl((15 - n) * 4)), i + 1, n + 1
    }
  } else {
    (hi, i)
  }
  let (lo, i) = for lo = 0L, i = i, n = 0; n < 16; {
    if i >= hex.length() {
      return Err("not enough hexadecimal in UUID string")
    }
    let c = hex[i]
    if c == '-' {
      continue lo, i + 1, n
    } else {
      let d = hex_char_to_int64(c)?
      continue lo.lor(d.lsl((15 - n) * 4)), i + 1, n + 1
    }
  } else {
    (lo, i)
  }
  if i == hex.length() {
    Ok({ hi, lo })
  } else {
    Err("badly formed hexadecimal UUID string")
  }
}

let hex_table : Array[Int] = "0123456789abcdef".to_array().map(
  fn { c => c.to_int() },
)

let dash : Int = '-'.to_int()

let segments = [8, 4, 4, 0, 4, 12]

// XXX: use sum() instead; weird `moon fmt`
let size : Int = (segments.fold_left(fn { acc, x => acc + x }, init=0) + segments.length() -
  2) * 2

pub fn to_string(self : UUID) -> String {
  // This is a manually-composed UTF-16 string
  let rv = Bytes::make(size, 0)
  for v = self.lo, c = size - 1, i = size - 1, d = segments.length() - 1 {
    let s = segments[d] * 2
    if s == 0 {
      continue self.hi, c, i, d - 1
    } else if i > c - s {
      rv[i - 1] = hex_table[v.land(0xfL).to_int()]
      continue v.lsr(4), c, i - 2, d
    } else if i > 0 {
      rv[i - 1] = dash
      continue v, i - 2, i - 2, d - 1
    } else {
      break rv.to_string()
    }
  }
}

test "from_hex" {
  let hex = "13cb501c-1234-5678-9034-abcdef937e20"
  inspect(from_hex(hex)?, content=hex)?
  inspect(
    from_hex("12345678-1234-1234-1234-ABCDEF098765")?,
    content="12345678-1234-1234-1234-abcdef098765",
  )?
  inspect(
    from_hex("13cb"),
    content="Err(not enough hexadecimal in UUID string)",
  )?
  inspect(
    from_hex("13cb501c-99a8-c889-3234"),
    content="Err(not enough hexadecimal in UUID string)",
  )?
}
