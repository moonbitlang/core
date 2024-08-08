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

// Float primitive
pub fn Float::op_neg(self : Float) -> Float = "%f32.neg"

pub fn Float::op_add(self : Float, other : Float) -> Float = "%f32.add"

pub fn Float::op_sub(self : Float, other : Float) -> Float = "%f32.sub"

pub fn Float::op_mul(self : Float, other : Float) -> Float = "%f32.mul"

pub fn Float::op_div(self : Float, other : Float) -> Float = "%f32.div"

pub fn Float::op_mod(self : Float, other : Float) -> Float = "%f32.mod"

pub fn Float::sqrt(self : Float) -> Float = "%f32.sqrt"

pub fn Float::op_equal(self : Float, other : Float) -> Bool = "%f32.eq"

pub fn Float::op_neq(self : Float, other : Float) -> Bool = "%f32.ne"

pub fn Float::compare(self : Float, other : Float) -> Int = "%f32.compare"

pub fn Float::to_double(self : Float) -> Double = "%identity"

pub fn Float::reinterpret_as_int(self : Float) -> Int = "%f32.to_i32_reinterpret"

pub fn Int::to_float(self : Int) -> Float = "%i32.to_f32"

pub fn Int::reinterpret_as_float(self : Int) -> Float = "%i32.to_f32_reinterpret"

pub fn Byte::to_float(self : Byte) -> Float = "%byte.to_f32"

pub fn Double::to_float(self : Double) -> Float = "%f64.to_f32"

pub fn UInt::to_float(self : UInt) -> Float = "%u32.to_f32"

pub fn Int64::to_float(self : Int64) -> Float {
  self.to_double().to_float()
}

pub fn UInt64::to_float(self : UInt64) -> Float {
  Double::convert_uint64(self).to_float()
}
