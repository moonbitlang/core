// Copyright 2026 International Digital Economy Academy
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

///|
fn decimal_power_count(bits : Int, signed : Bool) -> UInt {
  match (bits, signed) {
    (16, _) => 5U
    (32, _) => 10U
    (64, true) => 19U
    (64, false) => 20U
    _ => abort("arbitrary integer: unsupported bit width")
  }
}

///|
fn canonical_integer_bits(
  mask : UInt64,
  signed : Bool,
  rs : @splitmix.RandomState,
) -> UInt64 {
  guard signed else { rs.next_uint(limit=4U).to_uint64() }
  match rs.next_uint(limit=5U) {
    0U => 0UL
    1U => 1UL
    2U => mask
    3U => 2UL
    _ => mask - 1UL
  }
}

///|
fn apply_random_sign(
  magnitude : UInt64,
  signed : Bool,
  rs : @splitmix.RandomState,
) -> UInt64 {
  if signed && rs.next_uint(limit=2U) == 1U {
    0UL - magnitude
  } else {
    magnitude
  }
}

///|
fn boundary_delta(base : UInt64, rs : @splitmix.RandomState) -> UInt64 {
  match rs.next_uint(limit=3U) {
    0U => base - 1UL
    1U => base
    _ => base + 1UL
  }
}

///|
fn binary_boundary_bits(
  bits : Int,
  signed : Bool,
  rs : @splitmix.RandomState,
) -> UInt64 {
  let exponent_count = if signed { bits - 1 } else { bits }
  let exponent = rs
    .next_uint(limit=exponent_count.reinterpret_as_uint())
    .reinterpret_as_int()
  let magnitude = boundary_delta(1UL << exponent, rs)
  apply_random_sign(magnitude, signed, rs)
}

///|
fn decimal_boundary_bits(
  bits : Int,
  signed : Bool,
  rs : @splitmix.RandomState,
) -> UInt64 {
  let exponent = rs
    .next_uint(limit=decimal_power_count(bits, signed))
    .reinterpret_as_int()
  let magnitude = boundary_delta(
    (0 : Int).until(exponent).fold(init=1UL, (power, _) => power * 10UL),
    rs,
  )
  apply_random_sign(magnitude, signed, rs)
}

///|
fn extreme_integer_bits(
  bits : Int,
  mask : UInt64,
  signed : Bool,
  rs : @splitmix.RandomState,
) -> UInt64 {
  let choice = rs.next_uint(limit=4U)
  if signed {
    let sign_bit = 1UL << (bits - 1)
    match choice {
      0U => sign_bit
      1U => sign_bit + 1UL
      2U => sign_bit - 2UL
      _ => sign_bit - 1UL
    }
  } else {
    match choice {
      0U => mask
      1U => mask - 1UL
      2U => mask - 2UL
      _ => 1UL << (bits - 1)
    }
  }
}

///|
/// 40% full-width, 20% canonical, 20% binary boundaries,
/// 10% decimal boundaries, and 10% type extrema.
fn gen_integer_bits(
  bits : Int,
  signed : Bool,
  rs : @splitmix.RandomState,
) -> UInt64 {
  let mask = if bits == 64 {
    0xffff_ffff_ffff_ffffUL
  } else {
    (1UL << bits) - 1UL
  }

  let value = match rs.next_uint(limit=100U) {
    0..<40 => rs.next_uint64()
    40..<60 => canonical_integer_bits(mask, signed, rs)
    60..<80 => binary_boundary_bits(bits, signed, rs)
    80..<90 => decimal_boundary_bits(bits, signed, rs)
    _ => extreme_integer_bits(bits, mask, signed, rs)
  }
  value & mask
}

///|
pub impl Arbitrary for Int16 with fn arbitrary(_, rs) {
  Int16::reinterpret_from_uint16(gen_integer_bits(16, true, rs).to_uint16())
}

///|
pub impl Arbitrary for UInt16 with fn arbitrary(_, rs) {
  gen_integer_bits(16, false, rs).to_uint16()
}

///|
pub impl Arbitrary for Int with fn arbitrary(_, rs) {
  gen_integer_bits(32, true, rs).to_uint().reinterpret_as_int()
}

///|
pub impl Arbitrary for UInt with fn arbitrary(_, rs) {
  gen_integer_bits(32, false, rs).to_uint()
}

///|
pub impl Arbitrary for Int64 with fn arbitrary(_, rs) {
  gen_integer_bits(64, true, rs).reinterpret_as_int64()
}

///|
pub impl Arbitrary for UInt64 with fn arbitrary(_, rs) {
  gen_integer_bits(64, false, rs)
}
