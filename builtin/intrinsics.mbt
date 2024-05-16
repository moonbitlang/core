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

pub fn print_string(s : String) -> Unit = "%print_string"

pub fn abort[T](msg : String) -> T = "%abort"

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

pub fn Int::div_u(self : Int, other : Int) -> Int = "%i32_div_u"

pub fn Int::op_mod(self : Int, other : Int) -> Int = "%i32_mod"

pub fn Int::mod_u(self : Int, other : Int) -> Int = "%i32_mod_u"

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

pub fn Int::compare_u(self : Int, other : Int) -> Int = "%i32_compare_u"

pub fn Int::is_pos(self : Int) -> Bool = "%i32_is_pos"

pub fn Int::is_neg(self : Int) -> Bool = "%i32_is_neg"

pub fn Int::is_non_pos(self : Int) -> Bool = "%i32_is_non_pos"

pub fn Int::is_non_neg(self : Int) -> Bool = "%i32_is_non_neg"

pub fn Int::default() -> Int = "%i32_default"

pub fn Int::to_int64(self : Int) -> Int64 = "%i32_to_i64"

pub fn Int::to_double(self : Int) -> Double = "%i32_to_f64"

pub fn Int::trunc_double_u(val : Double) -> Int = "%f64_to_i32_u"

// Int64 primitive ops

pub fn Int64::op_neg(self : Int64) -> Int64 = "%i64_neg"

pub fn Int64::op_add(self : Int64, other : Int64) -> Int64 = "%i64_add"

pub fn Int64::op_sub(self : Int64, other : Int64) -> Int64 = "%i64_sub"

pub fn Int64::op_mul(self : Int64, other : Int64) -> Int64 = "%i64_mul"

pub fn Int64::op_div(self : Int64, other : Int64) -> Int64 = "%i64_div"

pub fn Int64::div_u(self : Int64, other : Int64) -> Int64 = "%i64_div_u"

pub fn Int64::op_mod(self : Int64, other : Int64) -> Int64 = "%i64_mod"

pub fn Int64::mod_u(self : Int64, other : Int64) -> Int64 = "%i64_mod_u"

pub fn Int64::lnot(self : Int64) -> Int64 = "%i64_lnot"

pub fn Int64::land(self : Int64, other : Int64) -> Int64 = "%i64_land"

pub fn Int64::lor(self : Int64, other : Int64) -> Int64 = "%i64_lor"

pub fn Int64::lxor(self : Int64, other : Int64) -> Int64 = "%i64_lxor"

pub fn Int64::lsl(self : Int64, other : Int) -> Int64 = "%i64_lsl"

pub fn Int64::lsr(self : Int64, other : Int) -> Int64 = "%i64_lsr"

pub fn Int64::asr(self : Int64, other : Int) -> Int64 = "%i64_asr"

pub fn Int64::ctz(self : Int64) -> Int = "%i64_ctz"

pub fn Int64::clz(self : Int64) -> Int = "%i64_clz"

pub fn Int64::popcnt(self : Int64) -> Int = "%i64_popcnt"

pub fn Int64::op_equal(self : Int64, other : Int64) -> Bool = "%i64_eq"

pub fn Int64::compare(self : Int64, other : Int64) -> Int = "%i64_compare"

pub fn Int64::compare_u(self : Int64, other : Int64) -> Int = "%i64_compare_u"

pub fn Int64::default() -> Int64 = "%i64_default"

pub fn Int64::to_int(self : Int64) -> Int = "%i64_to_i32"

pub fn Int64::to_double(self : Int64) -> Double = "%i64_to_f64"

pub fn Int64::extend_i32_u(val : Int) -> Int64 = "%i32_to_i64_u"

pub fn Int64::reinterpret_as_double(self : Int64) -> Double = "%i64_to_f64_reinterpret"

pub fn Int64::trunc_double_u(val : Double) -> Int64 = "%f64_to_i64_u"

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

pub fn Double::to_int64(self : Double) -> Int64 = "%f64_to_i64"

pub fn Double::reinterpret_as_i64(self : Double) -> Int64 = "%f64_to_i64_reinterpret"

pub fn Double::convert_i32_u(val : Int) -> Double = "%i32_to_f64_u"

pub fn Double::convert_i64_u(val : Int64) -> Double = "%i64_to_f64_u"

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

fn identity[A, B](x : A) -> B = "%identity"

pub fn Int::to_byte(self : Int) -> Byte {
  identity(self.land(0xFF))
}

pub fn Int64::to_byte(self : Int64) -> Byte {
  identity(self.to_int().land(0xFF))
}

// Array primitive ops

pub fn Array::op_get[T](self : Array[T], idx : Int) -> T = "%array_get"

pub fn Array::get[T](self : Array[T], idx : Int) -> T = "%array_get"

pub fn Array::op_set[T](self : Array[T], idx : Int, val : T) -> Unit = "%array_set"

pub fn Array::set[T](self : Array[T], idx : Int, val : T) -> Unit = "%array_set"

pub fn Array::length[T](self : Array[T]) -> Int = "%array_length"

pub fn Array::make[T](len : Int, init : T) -> Array[T] = "%array_make"

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
