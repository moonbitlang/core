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

pub fn ignore[T](t : T) -> Unit = "%ignore"

pub fn physical_equal[T](a : T, b : T) -> Bool = "%refeq"

pub fn abort[T](msg : String) -> T {
  ignore(msg)
  panic()
}

pub fn panic[T]() -> T = "%panic"

// Bool primitive ops

pub fn Bool::not(self : Bool) -> Bool = "%bool_not"

pub fn Bool::op_equal(self : Bool, other : Bool) -> Bool = "%bool_eq"

pub fn Bool::op_compare(self : Bool, other : Bool) -> Int = "%bool_compare"

pub fn Bool::default() -> Bool = "%bool_default"

// int32 primitive ops

pub fn Int::op_neg(self : Int) -> Int = "%i32_neg"

pub fn Int::op_add(self : Int, other : Int) -> Int = "%i32_add"

pub fn Int::op_sub(self : Int, other : Int) -> Int = "%i32_sub"

pub fn Int::op_mul(self : Int, other : Int) -> Int = "%i32_mul"

pub fn Int::op_div(self : Int, other : Int) -> Int = "%i32_div"

pub fn Int::op_mod(self : Int, other : Int) -> Int = "%i32_mod"

pub fn Int::lnot(self : Int) -> Int = "%i32_lnot"

pub fn Int::land(self : Int, other : Int) -> Int = "%i32_land"

pub fn Int::lor(self : Int, other : Int) -> Int = "%i32_lor"

pub fn Int::lxor(self : Int, other : Int) -> Int = "%i32_lxor"

pub fn Int::lsl(self : Int, other : Int) -> Int = "%i32_lsl"

pub fn Int::lsr(self : Int, other : Int) -> Int = "%i32_lsr"

pub fn Int::asr(self : Int, other : Int) -> Int = "%i32_asr"

pub fn Int::ctz(self : Int) -> Int = "%i32_ctz"

pub fn Int::clz(self : Int) -> Int = "%i32_clz"

pub fn Int::popcnt(self : Int) -> Int = "%i32_popcnt"

pub fn Int::op_equal(self : Int, other : Int) -> Bool = "%i32_eq"

pub fn Int::compare(self : Int, other : Int) -> Int = "%i32_compare"

pub fn Int::is_pos(self : Int) -> Bool = "%i32_is_pos"

pub fn Int::is_neg(self : Int) -> Bool = "%i32_is_neg"

pub fn Int::is_non_pos(self : Int) -> Bool = "%i32_is_non_pos"

pub fn Int::is_non_neg(self : Int) -> Bool = "%i32_is_non_neg"

pub fn Int::default() -> Int = "%i32_default"

pub fn Int::to_double(self : Int) -> Double = "%i32_to_f64"

pub fn UInt::trunc_double(val : Double) -> UInt = "%f64.to_u32"

pub fn Int::to_uint(self : Int) -> UInt = "%i32.to_u32_reinterpret"

// Double primitive ops

pub fn Double::op_neg(self : Double) -> Double = "%f64_neg"

pub fn Double::op_add(self : Double, other : Double) -> Double = "%f64_add"

pub fn Double::op_sub(self : Double, other : Double) -> Double = "%f64_sub"

pub fn Double::op_mul(self : Double, other : Double) -> Double = "%f64_mul"

pub fn Double::op_div(self : Double, other : Double) -> Double = "%f64_div"

pub fn Double::op_mod(self : Double, other : Double) -> Double = "%f64_mod"

pub fn Double::sqrt(self : Double) -> Double = "%f64_sqrt"

pub fn Double::op_equal(self : Double, other : Double) -> Bool = "%f64_eq"

pub fn Double::op_neq(self : Double, other : Double) -> Bool = "%f64_ne"

pub fn Double::compare(self : Double, other : Double) -> Int = "%f64_compare"

pub fn Double::default() -> Double = "%f64_default"

pub fn Double::to_int(self : Double) -> Int = "%f64_to_i32"

pub fn Double::convert_uint(val : UInt) -> Double = "%u32.to_f64"

// Char primitive ops

pub fn Char::to_int(self : Char) -> Int = "%char_to_int"

pub fn Char::from_int(val : Int) -> Char = "%char_from_int"

pub fn Char::op_equal(self : Char, other : Char) -> Bool = "%char_eq"

pub fn Char::compare(self : Char, other : Char) -> Int = "%char_compare"

pub fn Char::default() -> Char = "%char_default"

// Bytes primitive ops

pub fn Bytes::op_get(self : Bytes, idx : Int) -> Byte = "%bytes_get"

pub fn Bytes::op_set(self : Bytes, idx : Int, val : Byte) -> Unit = "%bytes_set"

pub fn Bytes::length(self : Bytes) -> Int = "%bytes_length"

pub fn Bytes::make(len : Int, init : Byte) -> Bytes = "%bytes_make"

/// The init value of Bytes is 0.
pub fn Bytes::new(len : Int) -> Bytes {
  Bytes::make(len, b'\x00')
}

fn identity[A, B](x : A) -> B = "%identity"

pub fn Int::to_byte(self : Int) -> Byte {
  identity(self.land(0xFF))
}

pub fn Int64::to_byte(self : Int64) -> Byte {
  identity(self.to_int().land(0xFF))
}

pub fn UInt64::to_byte(self : UInt64) -> Byte {
  identity(self.to_int().land(0xFF))
}

// FixedArray primitive ops

pub fn FixedArray::op_get[T](self : FixedArray[T], idx : Int) -> T = "%fixedarray.get"

pub fn FixedArray::get[T](self : FixedArray[T], idx : Int) -> T = "%fixedarray.get"

pub fn FixedArray::op_set[T](self : FixedArray[T], idx : Int, val : T) -> Unit = "%fixedarray.set"

pub fn FixedArray::set[T](self : FixedArray[T], idx : Int, val : T) -> Unit = "%fixedarray.set"

pub fn FixedArray::length[T](self : FixedArray[T]) -> Int = "%fixedarray.length"

pub fn FixedArray::make[T](len : Int, init : T) -> FixedArray[T] = "%fixedarray.make"

// String primitive ops

pub fn String::length(self : String) -> Int = "%string_length"

pub fn String::op_get(self : String, idx : Int) -> Char = "%string_get"

pub fn String::get(self : String, idx : Int) -> Char = "%string_get"

pub fn String::op_add(self : String, other : String) -> String = "%string_add"

pub fn String::op_equal(self : String, other : String) -> Bool = "%string_eq"

pub fn String::to_string(self : String) -> String = "%string_to_string"

pub fn String::to_js_string(self : String) -> Js_string = "%string_to_jsstring"

// For internal use only
pub type UnsafeMaybeUninit[_]

// Byte primitive
pub fn Byte::to_int(self : Byte) -> Int = "%byte_to_int"

pub fn Byte::to_int64(self : Byte) -> Int64 {
  self.to_int().to_int64()
}

// UInt primitive
pub fn UInt::to_int(self : UInt) -> Int = "%u32.to_i32_reinterpret"

pub fn UInt::op_add(self : UInt, other : UInt) -> UInt = "%u32.add"

pub fn UInt::op_sub(self : UInt, other : UInt) -> UInt = "%u32.sub"

pub fn UInt::op_mul(self : UInt, other : UInt) -> UInt = "%u32.mul"

pub fn UInt::op_div(self : UInt, other : UInt) -> UInt = "%u32.div"

pub fn UInt::op_mod(self : UInt, other : UInt) -> UInt = "%u32.mod"

pub fn UInt::op_equal(self : UInt, other : UInt) -> Bool = "%u32.eq"

pub fn UInt::op_neq(self : UInt, other : UInt) -> Bool = "%u32.ne"

pub fn UInt::compare(self : UInt, other : UInt) -> Int = "%u32.compare"

pub fn UInt::land(self : UInt, other : UInt) -> UInt = "%u32.bitand"

pub fn UInt::lor(self : UInt, other : UInt) -> UInt = "%u32.bitor"

pub fn UInt::lxor(self : UInt, other : UInt) -> UInt = "%u32.bitxor"

pub fn UInt::lnot(self : UInt) -> UInt = "%u32.bitnot"

pub fn UInt::lsl(self : UInt, shift : Int) -> UInt = "%u32.shl"

pub fn UInt::lsr(self : UInt, shift : Int) -> UInt = "%u32.shr"

pub fn UInt::to_uint64(self : UInt) -> UInt64 {
  UInt64::extend_uint(self)
}
