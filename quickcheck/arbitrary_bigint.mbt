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
fn[T] @splitmix.RandomState::pick(
  self : @splitmix.RandomState,
  values : ReadOnlyArray[T],
) -> T {
  let index = self.next_uint(limit=values.length().reinterpret_as_uint())
  values[index.reinterpret_as_int()]
}

///|
fn with_random_sign(
  magnitude : @bigint.BigInt,
  rs : @splitmix.RandomState,
) -> @bigint.BigInt {
  if magnitude.is_zero() || rs.next_uint(limit=2U) == 0U {
    magnitude
  } else {
    -magnitude
  }
}

///|
fn around(base : @bigint.BigInt, rs : @splitmix.RandomState) -> @bigint.BigInt {
  with_random_sign(base + rs.pick([-1N, 0N, 1N]), rs)
}

///|
fn random_bigint(size : Int, rs : @splitmix.RandomState) -> @bigint.BigInt {
  let chunk_limit = size.clamp(min=0, max=31) + 1
  let chunk_count = for count in 1..<chunk_limit {
    guard rs.next_uint(limit=2U) == 0U else { break count }
  } nobreak {
    chunk_limit
  }
  let bytes = Bytes::makei(chunk_count * 8, _ => {
    rs.next_uint(limit=256U).to_byte()
  })
  with_random_sign(@bigint.BigInt::from_octets(bytes), rs)
}

///|
/// 35% arbitrary multi-word bit patterns, 25% canonical small values,
/// 25% values next to common powers of two, and 15% values next to common
/// powers of ten. `size` caps the random branch at one to 32 64-bit words;
/// boundary branches deliberately exercise important widths independently.
pub impl Arbitrary for @bigint.BigInt with fn arbitrary(size, rs) {
  match rs.next_uint(limit=100U) {
    0..<35 => random_bigint(size, rs)
    35..<60 => rs.pick([0N, 1N, -1N, 2N, -2N, 10N, -10N])
    60..<85 =>
      around(
        1N <<
        rs.pick([0, 1, 7, 8, 15, 16, 31, 32, 52, 53, 63, 64, 127, 128, 255, 256]),
        rs,
      )
    _ => {
      let exponent = rs.pick([1, 2, 3, 6, 9, 18, 19, 38, 76, 100])
      around(
        (0 : Int).until(exponent).fold(init=1N, (power, _) => power * 10N),
        rs,
      )
    }
  }
}
