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

//region MyInt64
priv struct MyInt64 {
  hi : Int
  lo : Int
}

fn MyInt64::to_int64(self : MyInt64) -> Int64 = "%identity"

fn MyInt64::from_int64(value : Int64) -> MyInt64 = "%identity"

fn MyInt64::op_neg(self : MyInt64) -> MyInt64 {
  if self.lo == 0 {
    { hi: self.hi.lnot() + 1, lo: 0 }
  } else {
    { hi: self.hi.lnot(), lo: self.lo.lnot() + 1 }
  }
}

fn MyInt64::add_hi_lo(self : MyInt64, bhi : Int, blo : Int) -> MyInt64 {
  let { hi: ahi, lo: alo } = self
  let lo = alo + blo
  let s = lo >> 31
  let as_ = alo >> 31
  let bs = blo >> 31
  let c = ((as_ & bs) | (s.lnot() & (as_ ^ bs))) & 1
  let hi = ahi + bhi + c
  { hi, lo }
}

fn MyInt64::op_add(self : MyInt64, other : MyInt64) -> MyInt64 {
  add_hi_lo(self, other.hi, other.lo)
}

fn MyInt64::op_sub(self : MyInt64, other : MyInt64) -> MyInt64 {
  if other.lo == 0 {
    { hi: self.hi - other.hi, lo: self.lo }
  } else {
    add_hi_lo(self, other.hi.lnot(), other.lo.lnot() + 1)
  }
}

fn MyInt64::op_mul(self : MyInt64, other : MyInt64) -> MyInt64 {
  let { hi: ahi, lo: alo } = self
  let { hi: bhi, lo: blo } = other
  let ahi = ahi.reinterpret_as_uint()
  let alo = alo.reinterpret_as_uint()
  let bhi = bhi.reinterpret_as_uint()
  let blo = blo.reinterpret_as_uint()
  let a48 = ahi >> 16
  let a32 = ahi & 0xffff
  let a16 = alo >> 16
  let a00 = alo & 0xffff
  let b48 = bhi >> 16
  let b32 = bhi & 0xffff
  let b16 = blo >> 16
  let b00 = blo & 0xffff
  let c00 = a00 * b00
  let c16 = c00 >> 16
  let c00 = c00 & 0xffff
  let c16 = c16 + a16 * b00
  let c32 = c16 >> 16
  let c16 = c16 & 0xffff
  let c16 = c16 + a00 * b16
  let c32 = c32 + (c16 >> 16)
  let c16 = c16 & 0xffff
  let c32 = c32 + a32 * b00
  let c48 = c32 >> 16
  let c32 = c32 & 0xffff
  let c32 = c32 + a16 * b16
  let c48 = c48 + (c32 >> 16)
  let c32 = c32 & 0xffff
  let c32 = c32 + a00 * b32
  let c48 = c48 + (c32 >> 16)
  let c32 = c32 & 0xffff
  let c48 = c48 + a48 * b00 + a32 * b16 + a16 * b32 + a00 * b48
  let c48 = c48 & 0xffff
  {
    hi: ((c48 << 16) | c32).reinterpret_as_int(),
    lo: ((c16 << 16) | c00).reinterpret_as_int(),
  }
}

struct Int64WasmHelper {
  div_s : (Int, Int, Int, Int) -> Int
  div_u : (Int, Int, Int, Int) -> Int
  rem_s : (Int, Int, Int, Int) -> Int
  rem_u : (Int, Int, Int, Int) -> Int
  get_high : () -> Int
}

extern "js" fn get_int64_wasm_helper() -> Int64WasmHelper =
  #|function f() {
  #|  if (f._exports) return f._exports;
  #|  return f._exports = new WebAssembly.Instance(new WebAssembly.Module(new Uint8Array([0, 97, 115, 109, 1, 0, 0, 0, 1, 13, 2, 96, 0, 1, 127, 96, 4, 127, 127, 127, 127, 1, 127, 3, 7, 6, 0, 1, 1, 1, 1, 1, 6, 6, 1, 127, 1, 65, 0, 11, 7, 50, 6, 3, 109, 117, 108, 0, 1, 5, 100, 105, 118, 95, 115, 0, 2, 5, 100, 105, 118, 95, 117, 0, 3, 5, 114, 101, 109, 95, 115, 0, 4, 5, 114, 101, 109, 95, 117, 0, 5, 8, 103, 101, 116, 95, 104, 105, 103, 104, 0, 0, 10, 191, 1, 6, 4, 0, 35, 0, 11, 36, 1, 1, 126, 32, 0, 173, 32, 1, 173, 66, 32, 134, 132, 32, 2, 173, 32, 3, 173, 66, 32, 134, 132, 126, 34, 4, 66, 32, 135, 167, 36, 0, 32, 4, 167, 11, 36, 1, 1, 126, 32, 0, 173, 32, 1, 173, 66, 32, 134, 132, 32, 2, 173, 32, 3, 173, 66, 32, 134, 132, 127, 34, 4, 66, 32, 135, 167, 36, 0, 32, 4, 167, 11, 36, 1, 1, 126, 32, 0, 173, 32, 1, 173, 66, 32, 134, 132, 32, 2, 173, 32, 3, 173, 66, 32, 134, 132, 128, 34, 4, 66, 32, 135, 167, 36, 0, 32, 4, 167, 11, 36, 1, 1, 126, 32, 0, 173, 32, 1, 173, 66, 32, 134, 132, 32, 2, 173, 32, 3, 173, 66, 32, 134, 132, 129, 34, 4, 66, 32, 135, 167, 36, 0, 32, 4, 167, 11, 36, 1, 1, 126, 32, 0, 173, 32, 1, 173, 66, 32, 134, 132, 32, 2, 173, 32, 3, 173, 66, 32, 134, 132, 130, 34, 4, 66, 32, 135, 167, 36, 0, 32, 4, 167, 11])), {}).exports;
  #|}

fn MyInt64::op_div(self : MyInt64, other : MyInt64) -> MyInt64 {
  let exports = get_int64_wasm_helper()
  let { hi: ahi, lo: alo } = self
  let { hi: bhi, lo: blo } = other
  let lo = (exports.div_s)(alo, ahi, blo, bhi)
  let hi = (exports.get_high)()
  { hi, lo }
}

fn MyInt64::div_u(self : MyInt64, other : MyInt64) -> MyInt64 {
  let exports = get_int64_wasm_helper()
  let { hi: ahi, lo: alo } = self
  let { hi: bhi, lo: blo } = other
  let lo = (exports.div_u)(alo, ahi, blo, bhi)
  let hi = (exports.get_high)()
  { hi, lo }
}

fn MyInt64::op_mod(self : MyInt64, other : MyInt64) -> MyInt64 {
  let exports = get_int64_wasm_helper()
  let { hi: ahi, lo: alo } = self
  let { hi: bhi, lo: blo } = other
  let lo = (exports.rem_s)(alo, ahi, blo, bhi)
  let hi = (exports.get_high)()
  { hi, lo }
}

fn MyInt64::mod_u(self : MyInt64, other : MyInt64) -> MyInt64 {
  let exports = get_int64_wasm_helper()
  let { hi: ahi, lo: alo } = self
  let { hi: bhi, lo: blo } = other
  let lo = (exports.rem_u)(alo, ahi, blo, bhi)
  let hi = (exports.get_high)()
  { hi, lo }
}

fn MyInt64::lnot(self : MyInt64) -> MyInt64 {
  { hi: self.hi.lnot(), lo: self.lo.lnot() }
}

fn MyInt64::land(self : MyInt64, other : MyInt64) -> MyInt64 {
  { hi: self.hi & other.hi, lo: self.lo & other.lo }
}

fn MyInt64::lor(self : MyInt64, other : MyInt64) -> MyInt64 {
  { hi: self.hi | other.hi, lo: self.lo | other.lo }
}

fn MyInt64::lxor(self : MyInt64, other : MyInt64) -> MyInt64 {
  { hi: self.hi ^ other.hi, lo: self.lo ^ other.lo }
}

fn MyInt64::lsl(self : MyInt64, shift : Int) -> MyInt64 {
  let shift = shift & 63
  if shift == 0 {
    self
  } else if shift < 32 {
    let { hi, lo } = self
    let hi = hi.reinterpret_as_uint()
    let lo = lo.reinterpret_as_uint()
    let hi = (hi << shift) | (lo >> (32 - shift))
    let lo = lo << shift
    { hi: hi.reinterpret_as_int(), lo: lo.reinterpret_as_int() }
  } else {
    { hi: self.lo << (shift - 32), lo: 0 }
  }
}

fn MyInt64::lsr(self : MyInt64, shift : Int) -> MyInt64 {
  let shift = shift & 63
  if shift == 0 {
    self
  } else if shift < 32 {
    {
      hi: (self.hi.reinterpret_as_uint() >> shift).reinterpret_as_int(),
      lo: (self.lo.reinterpret_as_uint() >> shift).reinterpret_as_int() |
      (self.hi << (32 - shift)),
    }
  } else {
    {
      hi: 0,
      lo: (self.hi.reinterpret_as_uint() >> (shift - 32)).reinterpret_as_int(),
    }
  }
}

fn MyInt64::asr(self : MyInt64, shift : Int) -> MyInt64 {
  let shift = shift & 63
  if shift == 0 {
    self
  } else if shift < 32 {
    {
      hi: self.hi >> shift,
      lo: (self.lo.reinterpret_as_uint() >> shift).reinterpret_as_int() |
      (self.hi << (32 - shift)),
    }
  } else {
    { hi: self.hi >> 31, lo: self.hi >> (shift - 32) }
  }
}

fn MyInt64::clz(self : MyInt64) -> Int {
  if self.hi != 0 {
    self.hi.clz()
  } else {
    32 + self.lo.clz()
  }
}

fn MyInt64::ctz(self : MyInt64) -> Int {
  if self.lo != 0 {
    self.lo.ctz()
  } else {
    32 + self.hi.ctz()
  }
}

fn MyInt64::popcnt(self : MyInt64) -> Int {
  self.hi.popcnt() + self.lo.popcnt()
}

fn MyInt64::op_equal(self : MyInt64, other : MyInt64) -> Bool {
  self.hi == other.hi && self.lo == other.lo
}

// a.lsr(0) is compiled to `(a >>> 0 | 0)` in JavaScript
// so we can't use moonbit to generate the code

extern "js" fn MyInt64::compare(self : MyInt64, other : MyInt64) -> Int =
  #|(a, b) => {
  #|  const ahi = a.hi;
  #|  const bhi = b.hi;
  #|  if (ahi < bhi) {
  #|    return -1;
  #|  }
  #|  if (ahi > bhi) {
  #|    return 1;
  #|  }
  #|  const alo = a.lo >>> 0;
  #|  const blo = b.lo >>> 0;
  #|  if (alo < blo) {
  #|    return -1;
  #|  }
  #|  if (alo > blo) {
  #|    return 1;
  #|  }
  #|  return 0;
  #|}

extern "js" fn MyInt64::compare_u(self : MyInt64, other : MyInt64) -> Int =
  #|(a, b) => {
  #|  const ahi = a.hi >>> 0;
  #|  const bhi = b.hi >>> 0;
  #|  if (ahi < bhi) {
  #|    return -1;
  #|  }
  #|  if (ahi > bhi) {
  #|    return 1;
  #|  }
  #|  const alo = a.lo >>> 0;
  #|  const blo = b.lo >>> 0;
  #|  if (alo < blo) {
  #|    return -1;
  #|  }
  #|  if (alo > blo) {
  #|    return 1;
  #|  }
  #|  return 0;
  #|}

fn MyInt64::from_int(value : Int) -> MyInt64 {
  { hi: (value >> 31) & -1, lo: value | 0 }
}

fn MyInt64::to_int(self : MyInt64) -> Int {
  self.lo
}

fn MyInt64::to_uint(self : MyInt64) -> UInt {
  self.lo.reinterpret_as_uint()
}

extern "js" fn MyInt64::from_double(value : Double) -> MyInt64 =
  #|(a) => {
  #|  let neg = false;
  #|  if (a < 0) {
  #|    neg = true;
  #|    a = -a;
  #|  }
  #|  let hi = (a * (1 / 0x100000000)) | 0;
  #|  let lo = a >>> 0;
  #|  if (neg) {
  #|    if (lo === 0) {
  #|      hi = ~hi + 1;
  #|    } else {
  #|      hi = ~hi;
  #|      lo = ~lo + 1;
  #|    }
  #|  }
  #|  return { hi, lo };
  #|}

extern "js" fn MyInt64::to_double(self : MyInt64) -> Double =
  #|(a) => a.hi * 4294967296.0 + (a.lo >>> 0)

fn MyInt64::extend_i32_u(value : Int) -> MyInt64 {
  { hi: 0, lo: value }
}

extern "js" fn MyInt64::reinterpret_as_double(self : MyInt64) -> Double =
  #|function f(a) {
  #|  let view = f._view;
  #|  if (view === undefined) {
  #|    view = f._view = new DataView(new ArrayBuffer(8));
  #|  }
  #|  view.setUint32(0, a.hi);
  #|  view.setUint32(4, a.lo);
  #|  return view.getFloat64(0);
  #|}

extern "js" fn MyInt64::reinterpret_double(value : Double) -> MyInt64 =
  #|function f(a) {
  #|  let view = f._view;
  #|  if (view === undefined) {
  #|    view = f._view = new DataView(new ArrayBuffer(8));
  #|  }
  #|  view.setFloat64(0, a);
  #|  const hi = view.getInt32(0);
  #|  const lo = view.getInt32(4);
  #|  return { hi, lo };
  #|}

extern "js" fn MyInt64::trunc_double_u(value : Double) -> MyInt64 =
  #|(a) => {
  #|  let hi = (a * (1 / 0x100000000)) | 0;
  #|  let lo = a >>> 0;
  #|  return { hi, lo };
  #|}

extern "js" fn MyInt64::convert_to_double_u(self : MyInt64) -> Double =
  #|(a) => (a.hi >>> 0) * 4294967296.0 + (a.lo >>> 0)

extern "js" fn MyInt64::convert_to_double(self : MyInt64) -> Double =
  #|(a) => a.hi * 4294967296.0 + (a.lo >>> 0)
//endregion

pub fn Int64::op_neg(self : Int64) -> Int64 {
  (-MyInt64::from_int64(self)).to_int64()
}

pub fn Int64::op_add(self : Int64, other : Int64) -> Int64 {
  MyInt64::from_int64(self).op_add(MyInt64::from_int64(other)).to_int64()
}

pub fn Int64::op_sub(self : Int64, other : Int64) -> Int64 {
  MyInt64::from_int64(self).op_sub(MyInt64::from_int64(other)).to_int64()
}

pub fn Int64::op_mul(self : Int64, other : Int64) -> Int64 {
  MyInt64::from_int64(self).op_mul(MyInt64::from_int64(other)).to_int64()
}

pub fn Int64::op_div(self : Int64, other : Int64) -> Int64 {
  MyInt64::from_int64(self).op_div(MyInt64::from_int64(other)).to_int64()
}

pub fn Int64::op_mod(self : Int64, other : Int64) -> Int64 {
  MyInt64::from_int64(self).op_mod(MyInt64::from_int64(other)).to_int64()
}

pub fn Int64::lnot(self : Int64) -> Int64 {
  MyInt64::from_int64(self).lnot().to_int64()
}

pub fn Int64::land(self : Int64, other : Int64) -> Int64 {
  MyInt64::from_int64(self).land(MyInt64::from_int64(other)).to_int64()
}

pub fn Int64::lor(self : Int64, other : Int64) -> Int64 {
  MyInt64::from_int64(self).lor(MyInt64::from_int64(other)).to_int64()
}

pub fn Int64::lxor(self : Int64, other : Int64) -> Int64 {
  MyInt64::from_int64(self).lxor(MyInt64::from_int64(other)).to_int64()
}

/// @alert deprecated "Use infix operator `<<` instead"
pub fn Int64::lsl(self : Int64, other : Int) -> Int64 {
  MyInt64::from_int64(self).lsl(other).to_int64()
}

/// @alert deprecated "Use infix operator `<<` instead"
pub fn Int64::shl(self : Int64, other : Int) -> Int64 {
  MyInt64::from_int64(self).lsl(other).to_int64()
}

/// @alert deprecated "Use UInt64 type and infix operator `>>` instead"
pub fn Int64::lsr(self : Int64, other : Int) -> Int64 {
  MyInt64::from_int64(self).lsr(other).to_int64()
}

/// @alert deprecated "Use infix operator `>>` instead"
pub fn Int64::shr(self : Int64, other : Int) -> Int64 {
  MyInt64::from_int64(self).asr(other).to_int64()
}

/// @alert deprecated "Use infix operator `>>` instead"
pub fn Int64::asr(self : Int64, other : Int) -> Int64 {
  MyInt64::from_int64(self).asr(other).to_int64()
}

pub fn Int64::op_shr(self : Int64, other : Int) -> Int64 {
  MyInt64::from_int64(self).asr(other).to_int64()
}

pub fn Int64::op_shl(self : Int64, other : Int) -> Int64 {
  MyInt64::from_int64(self).lsl(other).to_int64()
}

pub fn Int64::ctz(self : Int64) -> Int {
  MyInt64::from_int64(self).ctz()
}

pub fn Int64::clz(self : Int64) -> Int {
  MyInt64::from_int64(self).clz()
}

pub fn Int64::popcnt(self : Int64) -> Int {
  MyInt64::from_int64(self).popcnt()
}

pub fn Int64::op_equal(self : Int64, other : Int64) -> Bool {
  MyInt64::from_int64(self) == MyInt64::from_int64(other)
}

pub fn Int64::compare(self : Int64, other : Int64) -> Int {
  MyInt64::compare(MyInt64::from_int64(self), MyInt64::from_int64(other))
}

pub fn Int64::default() -> Int64 {
  0L
}

pub fn Int64::to_int(self : Int64) -> Int {
  MyInt64::from_int64(self).to_int()
}

pub fn Int64::to_uint(self : Int64) -> UInt {
  MyInt64::from_int64(self).to_uint()
}

pub fn Int64::to_double(self : Int64) -> Double {
  Double::convert_int64(self)
}

pub fn Int64::to_byte(self : Int64) -> Byte {
  MyInt64::from_int64(self).to_int().to_byte()
}

pub fn UInt64::extend_uint(value : UInt) -> UInt64 {
  MyInt64::extend_i32_u(value.reinterpret_as_int()).to_uint64()
}

pub fn Int64::reinterpret_as_double(self : Int64) -> Double {
  MyInt64::reinterpret_as_double(MyInt64::from_int64(self))
}

pub fn Int::to_int64(self : Int) -> Int64 {
  MyInt64::from_int(self).to_int64()
}

pub fn Double::to_int64(self : Double) -> Int64 {
  MyInt64::from_double(self).to_int64()
}

pub fn Double::reinterpret_as_i64(self : Double) -> Int64 {
  MyInt64::reinterpret_double(self).to_int64()
}

pub fn Double::reinterpret_as_u64(self : Double) -> UInt64 {
  MyInt64::reinterpret_double(self).to_uint64()
}

pub fn Double::convert_uint64(value : UInt64) -> Double {
  MyInt64::convert_to_double_u(MyInt64::from_uint64(value))
}

pub fn Double::convert_int64(value : Int64) -> Double {
  MyInt64::convert_to_double(MyInt64::from_int64(value))
}

fn MyInt64::to_uint64(self : MyInt64) -> UInt64 = "%identity"

fn MyInt64::from_uint64(value : UInt64) -> MyInt64 = "%identity"

/// @alert deprecated "Use `reinterpret_as_uint64` instead"
pub fn Int64::to_uint64(self : Int64) -> UInt64 = "%identity"

pub fn Int64::reinterpret_as_uint64(self : Int64) -> UInt64 = "%identity"

pub fn UInt64::op_add(self : UInt64, other : UInt64) -> UInt64 {
  MyInt64::from_uint64(self).op_add(MyInt64::from_uint64(other)).to_uint64()
}

pub fn UInt64::op_sub(self : UInt64, other : UInt64) -> UInt64 {
  MyInt64::from_uint64(self).op_sub(MyInt64::from_uint64(other)).to_uint64()
}

pub fn UInt64::op_mul(self : UInt64, other : UInt64) -> UInt64 {
  MyInt64::from_uint64(self).op_mul(MyInt64::from_uint64(other)).to_uint64()
}

pub fn UInt64::op_div(self : UInt64, other : UInt64) -> UInt64 {
  MyInt64::from_uint64(self).div_u(MyInt64::from_uint64(other)).to_uint64()
}

pub fn UInt64::op_mod(self : UInt64, other : UInt64) -> UInt64 {
  MyInt64::from_uint64(self).mod_u(MyInt64::from_uint64(other)).to_uint64()
}

pub fn UInt64::to_int64(self : UInt64) -> Int64 = "%identity"

pub fn UInt64::to_uint(self : UInt64) -> UInt {
  MyInt64::from_uint64(self).to_uint()
}

pub fn UInt64::to_int(self : UInt64) -> Int {
  MyInt64::from_uint64(self).to_int()
}

pub fn UInt64::to_double(self : UInt64) -> Double {
  Double::convert_uint64(self)
}

pub fn UInt64::compare(self : UInt64, other : UInt64) -> Int {
  MyInt64::from_uint64(self).compare_u(MyInt64::from_uint64(other))
}

pub fn UInt64::op_equal(self : UInt64, other : UInt64) -> Bool {
  MyInt64::from_uint64(self).op_equal(MyInt64::from_uint64(other))
}

pub fn UInt64::trunc_double(value : Double) -> UInt64 {
  MyInt64::trunc_double_u(value).to_uint64()
}

pub fn UInt64::land(self : UInt64, other : UInt64) -> UInt64 {
  MyInt64::land(MyInt64::from_uint64(self), MyInt64::from_uint64(other)).to_uint64()
}

pub fn UInt64::lor(self : UInt64, other : UInt64) -> UInt64 {
  MyInt64::lor(MyInt64::from_uint64(self), MyInt64::from_uint64(other)).to_uint64()
}

pub fn UInt64::lxor(self : UInt64, other : UInt64) -> UInt64 {
  MyInt64::lxor(MyInt64::from_uint64(self), MyInt64::from_uint64(other)).to_uint64()
}

pub fn UInt64::lnot(self : UInt64) -> UInt64 {
  MyInt64::lnot(MyInt64::from_uint64(self)).to_uint64()
}

/// @alert deprecated "Use infix operator `<<` instead"
pub fn UInt64::lsl(self : UInt64, shift : Int) -> UInt64 {
  MyInt64::lsl(MyInt64::from_uint64(self), shift).to_uint64()
}

/// @alert deprecated "Use infix operator `<<` instead"
pub fn UInt64::lsr(self : UInt64, shift : Int) -> UInt64 {
  MyInt64::lsr(MyInt64::from_uint64(self), shift).to_uint64()
}

/// @alert deprecated "Use infix operator `>>` instead"
pub fn UInt64::shl(self : UInt64, shift : Int) -> UInt64 {
  MyInt64::lsl(MyInt64::from_uint64(self), shift).to_uint64()
}

/// @alert deprecated "Use infix operator `>>` instead"
pub fn UInt64::shr(self : UInt64, shift : Int) -> UInt64 {
  MyInt64::lsr(MyInt64::from_uint64(self), shift).to_uint64()
}

pub fn UInt64::op_shl(self : UInt64, shift : Int) -> UInt64 {
  MyInt64::lsl(MyInt64::from_uint64(self), shift).to_uint64()
}

pub fn UInt64::op_shr(self : UInt64, shift : Int) -> UInt64 {
  MyInt64::lsr(MyInt64::from_uint64(self), shift).to_uint64()
}

pub fn UInt64::clz(self : UInt64) -> Int {
  MyInt64::from_uint64(self).clz()
}

pub fn UInt64::ctz(self : UInt64) -> Int {
  MyInt64::from_uint64(self).ctz()
}

pub fn UInt64::popcnt(self : UInt64) -> Int {
  MyInt64::from_uint64(self).popcnt()
}

pub fn Int64::to_float(self : Int64) -> Float {
  self.to_double().to_float()
}

pub fn UInt64::to_float(self : UInt64) -> Float {
  Double::convert_uint64(self).to_float()
}
