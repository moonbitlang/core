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

// Recursive wide-digit division for large native/wasm BigInts.
//
// Knuth D produces one 64-bit quotient limb per O(n) multiply/subtract pass,
// which is quadratic for balanced operands. Here a group of half the divisor's
// limbs is treated as one wide digit. A recursive division estimates that wide
// digit and Karatsuba multiplication refines it, making division inherit the
// subquadratic multiplication complexity for large operands.

///|
/// Divisors below this size are faster with ordinary Knuth D.
const DIV_RECURSIVE_THRESHOLD = 64

///|
/// Recursive division only pays off when both the divisor and quotient are
/// wide. With at most two quotient-limb passes, Knuth D is linear in the large
/// divisor and avoids recursive splitting, multiplication, and allocation.
/// Requires `dividend_len >= divisor_len`.
fn use_recursive_division(dividend_len : Int, divisor_len : Int) -> Bool {
  divisor_len >= DIV_RECURSIVE_THRESHOLD && dividend_len - divisor_len > 1
}

///|
/// Magnitude-only division. Both operands must be positive and `self > other`.
fn BigInt::div_mod_mag(self : BigInt, other : BigInt) -> (BigInt, BigInt) {
  if other.len == 1 {
    self.div_mod_single_limb(other.limbs.unsafe_get(0))
  } else if use_recursive_division(self.len, other.len) {
    self.div_mod_recursive(other)
  } else {
    self.knuth_div(other)
  }
}

///|
/// Normalize once around the recursive division. Every recursive divisor is a
/// high slice of this normalized divisor, so its top bit remains set.
fn BigInt::div_mod_recursive(self : BigInt, other : BigInt) -> (BigInt, BigInt) {
  let shift = nlz(other.limbs.unsafe_get(other.len - 1))
  let u = if shift == 0 { self } else { self << shift }
  let v = if shift == 0 { other } else { other << shift }
  let (q, r) = div_mod_normalized(u, v)
  (q, if shift == 0 { r } else { r >> shift })
}

///|
/// Divide positive magnitudes with a normalized divisor.
fn div_mod_normalized(u : BigInt, v : BigInt) -> (BigInt, BigInt) {
  let cmp = u.cmp_mag(v)
  if cmp < 0 {
    return (zero, u)
  }
  if cmp == 0 {
    return (one, zero)
  }
  if v.len == 1 {
    return u.div_mod_single_limb(v.limbs.unsafe_get(0))
  }
  if use_recursive_division(u.len, v.len) {
    return div_mod_recursive_steps(u, v)
  }
  u.knuth_div(v)
}

///|
/// Long division in base 2^(64*block), where `block = floor(v.len/2)`.
///
/// `work` is cloned once and then updated in place. `work_end` excludes stale
/// processed limbs, so each step copies only its at-most-three-digit window
/// instead of rebuilding the entire unprocessed low prefix.
fn div_mod_recursive_steps(u : BigInt, v : BigInt) -> (BigInt, BigInt) {
  let n = v.len
  let block = n / 2
  let m = u.len - n
  let qlimbs = make(m + 1)
  let work = make(u.len)
  work.unsafe_blit(0, u.limbs, 0, u.len)
  let mut work_end = u.len
  let mut j = m
  while j > block {
    let offset = j - block
    let window = slice_mag(work, offset, work_end - offset)
    let (qhat, remainder) = div_recursive_step(window, v, block)
    if !qhat.is_zero() {
      add_at(qlimbs, m + 1, qhat.limbs, qhat.len, offset)
    }
    if remainder.is_zero() {
      work_end = offset
    } else {
      work.unsafe_blit(offset, remainder.limbs, 0, remainder.len)
      work_end = offset + remainder.len
    }
    j -= block
  }
  let remaining = slice_mag(work, 0, work_end)
  let (qhat, remainder) = div_recursive_step(remaining, v, block)
  if !qhat.is_zero() {
    add_at(qlimbs, m + 1, qhat.limbs, qhat.len, 0)
  }
  (
    { limbs: qlimbs, sign: Positive, len: normalize_len(qlimbs, m + 1), },
    remainder,
  )
}

///|
/// Divide an at-most-three-wide-digit window by a two-wide-digit divisor.
///
/// Dropping `block - 1` low limbs gives a tightly bounded overestimate. The low
/// halves refine it with one multiplication and, exceptionally, one or two
/// add-back corrections.
fn div_recursive_step(
  window : BigInt,
  divisor : BigInt,
  block : Int,
) -> (BigInt, BigInt) {
  let split = block - 1
  let high = window.high_mag(split)
  let divisor_high = divisor.high_mag(split)
  let (estimated, high_remainder) = div_mod_normalized(high, divisor_high)
  let low = window.low_mag(split)
  let divisor_low = divisor.low_mag(split)
  let mut combined = join_mag(low, high_remainder, split)
  let mut qhat = estimated
  let mut product = qhat * divisor_low
  let shifted_high = divisor_high.shl_mag_limbs(split)
  let mut corrections = 0
  while product.cmp_mag(combined) > 0 {
    if corrections == 2 {
      abort("internal recursive division error")
    }
    qhat = qhat.sub_mag(one)
    product = product.sub_mag(divisor_low)
    combined = combined.add_mag(shifted_high)
    corrections += 1
  }
  (qhat, combined.sub_mag(product))
}

///|
/// The low `count` limbs of a positive magnitude.
fn BigInt::low_mag(self : BigInt, count : Int) -> BigInt {
  slice_mag(self.limbs, 0, minimum_int(count, self.len))
}

///|
/// The magnitude above the low `count` limbs.
fn BigInt::high_mag(self : BigInt, count : Int) -> BigInt {
  slice_mag(self.limbs, count, self.len - count)
}

///|
/// Shift a positive magnitude by whole limbs without allocating a spare limb.
fn BigInt::shl_mag_limbs(self : BigInt, count : Int) -> BigInt {
  if self.is_zero() || count == 0 {
    return self
  }
  let limbs = make(self.len + count)
  limbs.unsafe_blit(count, self.limbs, 0, self.len)
  { limbs, sign: Positive, len: self.len + count, }
}

///|
/// Form `high * 2^(64*split) + low`; `low` must fit below `split`.
fn join_mag(low : BigInt, high : BigInt, split : Int) -> BigInt {
  let len = maximum_int(low.len, split + high.len)
  let limbs = make(len)
  if !low.is_zero() {
    limbs.unsafe_blit(0, low.limbs, 0, low.len)
  }
  if !high.is_zero() {
    limbs.unsafe_blit(split, high.limbs, 0, high.len)
  }
  { limbs, sign: Positive, len: normalize_len(limbs, len), }
}
