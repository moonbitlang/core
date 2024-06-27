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

pub fn Int::to_int64(self : Int) -> Int64 = "%i32_to_i64"

pub fn Double::to_int64(self : Double) -> Int64 = "%f64_to_i64"

pub fn Double::reinterpret_as_i64(self : Double) -> Int64 = "%f64_to_i64_reinterpret"

pub fn Double::convert_i64_u(val : Int64) -> Double = "%i64_to_f64_u"

pub fn Int64::to_uint64(self : Int64) -> UInt64 = "%i64.to_u64_reinterpret"

pub fn UInt64::to_int64(self : UInt64) -> Int64 = "%u64.to_i64_reinterpret"

pub fn UInt64::op_add(self : UInt64, other : UInt64) -> UInt64 = "%u64.add"

pub fn UInt64::op_sub(self : UInt64, other : UInt64) -> UInt64 = "%u64.sub"

pub fn UInt64::op_mul(self : UInt64, other : UInt64) -> UInt64 = "%u64.mul"

pub fn UInt64::op_div(self : UInt64, other : UInt64) -> UInt64 = "%u64.div"

pub fn UInt64::op_mod(self : UInt64, other : UInt64) -> UInt64 = "%u64.mod"

pub fn UInt64::compare(self : UInt64, other : UInt64) -> Int = "%u64.compare"

pub fn UInt64::op_equal(self : UInt64, other : UInt64) -> Bool = "%u64.eq"

