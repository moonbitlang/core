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

///-----------------------------------------------------------------------------
pub fn ignore[T](t : T) -> Unit = "%ignore"

///-----------------------------------------------------------------------------
pub fn physical_equal[T](a : T, b : T) -> Bool = "%refeq"

///-----------------------------------------------------------------------------
pub fn abort[T](msg : String) -> T {
  ignore(msg)
  panic()
}

///-----------------------------------------------------------------------------
pub fn panic[T]() -> T = "%panic"

// Bool primitive ops

///-----------------------------------------------------------------------------
pub fn Bool::not(self : Bool) -> Bool = "%bool_not"

///-----------------------------------------------------------------------------
pub fn Bool::op_equal(self : Bool, other : Bool) -> Bool = "%bool_eq"

///-----------------------------------------------------------------------------
pub fn Bool::op_compare(self : Bool, other : Bool) -> Int = "%bool_compare"

///-----------------------------------------------------------------------------
pub fn Bool::default() -> Bool = "%bool_default"

// int32 primitive ops

///-----------------------------------------------------------------------------
pub fn Int::op_neg(self : Int) -> Int = "%i32_neg"

///-----------------------------------------------------------------------------
pub fn Int::op_add(self : Int, other : Int) -> Int = "%i32_add"

///-----------------------------------------------------------------------------
pub fn Int::op_sub(self : Int, other : Int) -> Int = "%i32_sub"

///-----------------------------------------------------------------------------
pub fn Int::op_mul(self : Int, other : Int) -> Int = "%i32_mul"

///-----------------------------------------------------------------------------
pub fn Int::op_div(self : Int, other : Int) -> Int = "%i32_div"

///-----------------------------------------------------------------------------
pub fn Int::op_mod(self : Int, other : Int) -> Int = "%i32_mod"

///-----------------------------------------------------------------------------
pub fn Int::lnot(self : Int) -> Int = "%i32_lnot"

///-----------------------------------------------------------------------------
pub fn Int::land(self : Int, other : Int) -> Int = "%i32_land"

///-----------------------------------------------------------------------------
pub fn Int::lor(self : Int, other : Int) -> Int = "%i32_lor"

///-----------------------------------------------------------------------------
pub fn Int::lxor(self : Int, other : Int) -> Int = "%i32_lxor"

///-----------------------------------------------------------------------------
pub fn Int::op_shl(self : Int, other : Int) -> Int = "%i32_shl"

///-----------------------------------------------------------------------------
pub fn Int::op_shr(self : Int, other : Int) -> Int = "%i32_shr"

///-----------------------------------------------------------------------------
/// @alert deprecated "Use infix operator `<<` instead"
pub fn Int::lsl(self : Int, other : Int) -> Int = "%i32_shl"

///-----------------------------------------------------------------------------
/// @alert deprecated "Use infix operator `<<` instead" 
pub fn Int::shl(self : Int, other : Int) -> Int = "%i32_shl"

///-----------------------------------------------------------------------------
/// @alert deprecated "Use UInt type and infix operator `>>` instead"
pub fn Int::lsr(self : Int, other : Int) -> Int {
  (self.reinterpret_as_uint() >> other).reinterpret_as_int()
}

///-----------------------------------------------------------------------------
/// @alert deprecated "Use infix operator `>>` instead"
pub fn Int::asr(self : Int, other : Int) -> Int = "%i32_shr"

///-----------------------------------------------------------------------------
/// @alert deprecated "Use infix operator `>>` instead"
pub fn Int::shr(self : Int, other : Int) -> Int = "%i32_shr"

///-----------------------------------------------------------------------------
pub fn Int::ctz(self : Int) -> Int = "%i32_ctz"

///-----------------------------------------------------------------------------
pub fn Int::clz(self : Int) -> Int = "%i32_clz"

///-----------------------------------------------------------------------------
pub fn Int::popcnt(self : Int) -> Int = "%i32_popcnt"

///-----------------------------------------------------------------------------
pub fn Int::op_equal(self : Int, other : Int) -> Bool = "%i32_eq"

///-----------------------------------------------------------------------------
pub fn Int::compare(self : Int, other : Int) -> Int = "%i32_compare"

///-----------------------------------------------------------------------------
pub fn Int::is_pos(self : Int) -> Bool = "%i32_is_pos"

///-----------------------------------------------------------------------------
pub fn Int::is_neg(self : Int) -> Bool = "%i32_is_neg"

///-----------------------------------------------------------------------------
pub fn Int::is_non_pos(self : Int) -> Bool = "%i32_is_non_pos"

///-----------------------------------------------------------------------------
pub fn Int::is_non_neg(self : Int) -> Bool = "%i32_is_non_neg"

///-----------------------------------------------------------------------------
pub fn Int::default() -> Int = "%i32_default"

///-----------------------------------------------------------------------------
pub fn Int::to_double(self : Int) -> Double = "%i32_to_f64"

///-----------------------------------------------------------------------------
pub fn UInt::trunc_double(val : Double) -> UInt = "%f64.to_u32"

///-----------------------------------------------------------------------------
/// reinterpret the signed int as unsigned int, when the value is 
/// non-negative, i.e, 0..=2^31-1, the value is the same. When the 
/// value is negative, it turns into a large number, 
/// for example, -1 turns into 2^32-1
pub fn Int::reinterpret_as_uint(self : Int) -> UInt = "%i32.to_u32_reinterpret"

///-----------------------------------------------------------------------------
/// @alert deprecated "Use `reinterpret_as_uint` instead"
pub fn Int::to_uint(self : Int) -> UInt = "%i32.to_u32_reinterpret"
// Double primitive ops

///-----------------------------------------------------------------------------
pub fn Int::to_uint64(self : Int) -> UInt64 {
  self.to_int64().reinterpret_as_uint64()
}

///-----------------------------------------------------------------------------
pub fn Double::op_neg(self : Double) -> Double = "%f64_neg"

///-----------------------------------------------------------------------------
pub fn Double::op_add(self : Double, other : Double) -> Double = "%f64_add"

///-----------------------------------------------------------------------------
pub fn Double::op_sub(self : Double, other : Double) -> Double = "%f64_sub"

///-----------------------------------------------------------------------------
pub fn Double::op_mul(self : Double, other : Double) -> Double = "%f64_mul"

///-----------------------------------------------------------------------------
pub fn Double::op_div(self : Double, other : Double) -> Double = "%f64_div"

///-----------------------------------------------------------------------------
pub fn Double::sqrt(self : Double) -> Double = "%f64_sqrt"

///-----------------------------------------------------------------------------
pub fn Double::op_equal(self : Double, other : Double) -> Bool = "%f64_eq"

///-----------------------------------------------------------------------------
pub fn Double::op_neq(self : Double, other : Double) -> Bool = "%f64_ne"

///-----------------------------------------------------------------------------
pub fn Double::compare(self : Double, other : Double) -> Int = "%f64_compare"

///-----------------------------------------------------------------------------
pub fn Double::default() -> Double = "%f64_default"

///-----------------------------------------------------------------------------
pub fn Double::to_int(self : Double) -> Int = "%f64_to_i32"

///-----------------------------------------------------------------------------
pub fn Double::convert_uint(val : UInt) -> Double = "%u32.to_f64"

// Char primitive ops

///-----------------------------------------------------------------------------
pub fn Char::to_int(self : Char) -> Int = "%char_to_int"

///-----------------------------------------------------------------------------
pub fn Char::to_uint(self : Char) -> UInt {
  self.to_int().reinterpret_as_uint()
}

///-----------------------------------------------------------------------------
pub fn Char::from_int(val : Int) -> Char = "%char_from_int"

///-----------------------------------------------------------------------------
pub fn Char::op_equal(self : Char, other : Char) -> Bool = "%char_eq"

///-----------------------------------------------------------------------------
pub fn Char::compare(self : Char, other : Char) -> Int = "%char_compare"

///-----------------------------------------------------------------------------
pub fn Char::default() -> Char = "%char_default"

// Bytes primitive ops

///-----------------------------------------------------------------------------
pub fn Bytes::op_get(self : Bytes, idx : Int) -> Byte = "%bytes_get"

///-----------------------------------------------------------------------------
pub fn Bytes::op_set(self : Bytes, idx : Int, val : Byte) -> Unit = "%bytes_set"

///-----------------------------------------------------------------------------
pub fn Bytes::length(self : Bytes) -> Int = "%bytes_length"

///-----------------------------------------------------------------------------
pub fn Bytes::make(len : Int, init : Byte) -> Bytes = "%bytes_make"

///-----------------------------------------------------------------------------
/// The init value of Bytes is 0.
pub fn Bytes::new(len : Int) -> Bytes {
  Bytes::make(len, b'\x00')
}

///-----------------------------------------------------------------------------
pub fn Int::to_byte(self : Int) -> Byte = "%i32_to_byte"

///-----------------------------------------------------------------------------
pub fn UInt64::to_byte(self : UInt64) -> Byte {
  self.to_int().to_byte()
}

// FixedArray primitive ops

///-----------------------------------------------------------------------------
pub fn FixedArray::op_get[T](self : FixedArray[T], idx : Int) -> T = "%fixedarray.get"

///-----------------------------------------------------------------------------
pub fn FixedArray::get[T](self : FixedArray[T], idx : Int) -> T = "%fixedarray.get"

///-----------------------------------------------------------------------------
pub fn FixedArray::op_set[T](self : FixedArray[T], idx : Int, val : T) -> Unit = "%fixedarray.set"

///-----------------------------------------------------------------------------
pub fn FixedArray::set[T](self : FixedArray[T], idx : Int, val : T) -> Unit = "%fixedarray.set"

///-----------------------------------------------------------------------------
pub fn FixedArray::length[T](self : FixedArray[T]) -> Int = "%fixedarray.length"

///-----------------------------------------------------------------------------
pub fn FixedArray::make[T](len : Int, init : T) -> FixedArray[T] = "%fixedarray.make"

// String primitive ops

///-----------------------------------------------------------------------------
pub fn String::length(self : String) -> Int = "%string_length"

///-----------------------------------------------------------------------------
pub fn String::op_get(self : String, idx : Int) -> Char = "%string_get"

///-----------------------------------------------------------------------------
pub fn String::get(self : String, idx : Int) -> Char = "%string_get"

///-----------------------------------------------------------------------------
pub fn String::op_add(self : String, other : String) -> String = "%string_add"

///-----------------------------------------------------------------------------
pub fn String::op_equal(self : String, other : String) -> Bool = "%string_eq"

///-----------------------------------------------------------------------------
pub fn String::to_string(self : String) -> String = "%string_to_string"

///-----------------------------------------------------------------------------
pub fn String::to_js_string(self : String) -> Js_string = "%string_to_jsstring"

///-----------------------------------------------------------------------------
// For internal use only
pub type UnsafeMaybeUninit[_]

///-----------------------------------------------------------------------------
// Byte primitive
pub fn Byte::to_int(self : Byte) -> Int = "%byte_to_int"

///-----------------------------------------------------------------------------
pub fn Byte::to_int64(self : Byte) -> Int64 {
  self.to_int().to_int64()
}

///-----------------------------------------------------------------------------
/// reinterpret the unsigned int as signed int
/// For number within the range of 0..=2^31-1, 
/// the value is the same. For number within the range of 2^31..=2^32-1,
/// the value is negative
pub fn UInt::reinterpret_as_int(self : UInt) -> Int = "%u32.to_i32_reinterpret"

///-----------------------------------------------------------------------------
/// @alert deprecated "Use `reinterpret_as_int` instead"
pub fn UInt::to_int(self : UInt) -> Int = "%u32.to_i32_reinterpret"

///-----------------------------------------------------------------------------
pub fn UInt::op_add(self : UInt, other : UInt) -> UInt = "%u32.add"

///-----------------------------------------------------------------------------
pub fn UInt::op_sub(self : UInt, other : UInt) -> UInt = "%u32.sub"

///-----------------------------------------------------------------------------
pub fn UInt::op_mul(self : UInt, other : UInt) -> UInt = "%u32.mul"

///-----------------------------------------------------------------------------
pub fn UInt::op_div(self : UInt, other : UInt) -> UInt = "%u32.div"

///-----------------------------------------------------------------------------
pub fn UInt::op_mod(self : UInt, other : UInt) -> UInt = "%u32.mod"

///-----------------------------------------------------------------------------
pub fn UInt::op_equal(self : UInt, other : UInt) -> Bool = "%u32.eq"

///-----------------------------------------------------------------------------
pub fn UInt::op_neq(self : UInt, other : UInt) -> Bool = "%u32.ne"

///-----------------------------------------------------------------------------
pub fn UInt::compare(self : UInt, other : UInt) -> Int = "%u32.compare"

///-----------------------------------------------------------------------------
pub fn UInt::land(self : UInt, other : UInt) -> UInt = "%u32.bitand"

///-----------------------------------------------------------------------------
pub fn UInt::lor(self : UInt, other : UInt) -> UInt = "%u32.bitor"

///-----------------------------------------------------------------------------
pub fn UInt::lxor(self : UInt, other : UInt) -> UInt = "%u32.bitxor"

///-----------------------------------------------------------------------------
pub fn UInt::lnot(self : UInt) -> UInt = "%u32.bitnot"

///-----------------------------------------------------------------------------
/// @alert deprecated "Use infix operator `<<` instead"
pub fn UInt::lsl(self : UInt, shift : Int) -> UInt = "%u32.shl"

///-----------------------------------------------------------------------------
/// @alert deprecated "Use infix operator `<<` instead"
pub fn UInt::shl(self : UInt, shift : Int) -> UInt = "%u32.shl"

///-----------------------------------------------------------------------------
/// @alert deprecated "Use infix operator `>>` instead"
pub fn UInt::lsr(self : UInt, shift : Int) -> UInt = "%u32.shr"

///-----------------------------------------------------------------------------
/// @alert deprecated "Use infix operator `>>` instead"
pub fn UInt::shr(self : UInt, shift : Int) -> UInt = "%u32.shr"

///-----------------------------------------------------------------------------
pub fn UInt::op_shl(self : UInt, shift : Int) -> UInt = "%u32.shl"

///-----------------------------------------------------------------------------
pub fn UInt::op_shr(self : UInt, shift : Int) -> UInt = "%u32.shr"

///-----------------------------------------------------------------------------
pub fn UInt::clz(self : UInt) -> Int = "%u32.clz"

///-----------------------------------------------------------------------------
pub fn UInt::ctz(self : UInt) -> Int = "%u32.ctz"

///-----------------------------------------------------------------------------
pub fn UInt::popcnt(self : UInt) -> Int = "%u32.popcnt"

///-----------------------------------------------------------------------------
pub fn UInt::to_uint64(self : UInt) -> UInt64 {
  UInt64::extend_uint(self)
}

///-----------------------------------------------------------------------------
pub fn UInt::to_byte(self : UInt) -> Byte {
  self.reinterpret_as_int().to_byte()
}

///-----------------------------------------------------------------------------
// Float primitive
pub fn Float::op_neg(self : Float) -> Float = "%f32.neg"

///-----------------------------------------------------------------------------
pub fn Float::op_add(self : Float, other : Float) -> Float = "%f32.add"

///-----------------------------------------------------------------------------
pub fn Float::op_sub(self : Float, other : Float) -> Float = "%f32.sub"

///-----------------------------------------------------------------------------
pub fn Float::op_mul(self : Float, other : Float) -> Float = "%f32.mul"

///-----------------------------------------------------------------------------
pub fn Float::op_div(self : Float, other : Float) -> Float = "%f32.div"

///-----------------------------------------------------------------------------
pub fn Float::sqrt(self : Float) -> Float = "%f32.sqrt"

///-----------------------------------------------------------------------------
pub fn Float::op_equal(self : Float, other : Float) -> Bool = "%f32.eq"

///-----------------------------------------------------------------------------
pub fn Float::op_neq(self : Float, other : Float) -> Bool = "%f32.ne"

///-----------------------------------------------------------------------------
pub fn Float::compare(self : Float, other : Float) -> Int = "%f32.compare"

///-----------------------------------------------------------------------------
pub fn Float::to_double(self : Float) -> Double = "%f32.to_f64"

///-----------------------------------------------------------------------------
pub fn Float::reinterpret_as_int(self : Float) -> Int = "%f32.to_i32_reinterpret"

///-----------------------------------------------------------------------------
pub fn Float::reinterpret_as_uint(self : Float) -> UInt = "%f32.to_i32_reinterpret"

///-----------------------------------------------------------------------------
pub fn Int::to_float(self : Int) -> Float = "%i32.to_f32"

///-----------------------------------------------------------------------------
pub fn Int::reinterpret_as_float(self : Int) -> Float = "%i32.to_f32_reinterpret"

///-----------------------------------------------------------------------------
pub fn Byte::to_float(self : Byte) -> Float = "%byte.to_f32"

///-----------------------------------------------------------------------------
pub fn Double::to_float(self : Double) -> Float = "%f64.to_f32"

///-----------------------------------------------------------------------------
pub fn UInt::to_float(self : UInt) -> Float = "%u32.to_f32"
