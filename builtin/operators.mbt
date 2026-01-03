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
/// types implementing this trait can use the `+` operator
pub(open) trait Add {
  add(Self, Self) -> Self = _
  #deprecated("use `add` instead", skip_current_package=true)
  op_add(Self, Self) -> Self = _
}

///|
/// types implementing this trait can use the `-` operator
pub(open) trait Sub {
  sub(Self, Self) -> Self = _
  #deprecated("use `sub` instead", skip_current_package=true)
  op_sub(Self, Self) -> Self = _
}

///|
/// types implementing this trait can use the `*` operator
pub(open) trait Mul {
  mul(Self, Self) -> Self = _
  #deprecated("use `mul` instead", skip_current_package=true)
  op_mul(Self, Self) -> Self = _
}

///|
/// types implementing this trait can use the `/` operator
pub(open) trait Div {
  div(Self, Self) -> Self = _
  #deprecated("use `div` instead", skip_current_package=true)
  op_div(Self, Self) -> Self = _
}

///|
/// types implementing this trait can use the unary `-` operator
pub(open) trait Neg {
  neg(Self) -> Self = _
  #deprecated("use `neg` instead", skip_current_package=true)
  op_neg(Self) -> Self = _
}

///|
/// types implementing this trait can use the `%` operator
pub(open) trait Mod {
  mod(Self, Self) -> Self = _
  #deprecated("use `mod` instead", skip_current_package=true)
  op_mod(Self, Self) -> Self = _
}

///|
/// types implementing this trait can use the `&` operator
pub(open) trait BitAnd {
  land(Self, Self) -> Self
}

///|
/// types implementing this trait can use the `|` operator
pub(open) trait BitOr {
  lor(Self, Self) -> Self
}

///|
/// types implementing this trait can use the `^` operator
pub(open) trait BitXOr {
  lxor(Self, Self) -> Self
}

///|
/// types implementing this trait can use the `<<` operator
pub(open) trait Shl {
  shl(Self, Int) -> Self = _
  #deprecated("use `shl` instead", skip_current_package=true)
  op_shl(Self, Int) -> Self = _
}

///|
/// types implementing this trait can use the `>>` operator
pub(open) trait Shr {
  shr(Self, Int) -> Self = _
  #deprecated("use `shr` instead", skip_current_package=true)
  op_shr(Self, Int) -> Self = _
}

///|
#deprecated("replace `impl op_add` with `impl add`")
impl Add with add(self, other) {
  Add::op_add(self, other)
}

///|
impl Add with op_add(self, other) {
  Add::add(self, other)
}

///|
#deprecated("replace `impl op_sub` with `impl sub`")
impl Sub with sub(self, other) {
  Sub::op_sub(self, other)
}

///|
impl Sub with op_sub(self, other) {
  Sub::sub(self, other)
}

///|
#deprecated("replace `impl op_mul` with `impl mul`")
impl Mul with mul(self, other) {
  Mul::op_mul(self, other)
}

///|
impl Mul with op_mul(self, other) {
  Mul::mul(self, other)
}

///|
#deprecated("replace `impl op_div` with `impl div`")
impl Div with div(self, other) {
  Div::op_div(self, other)
}

///|
impl Div with op_div(self, other) {
  Div::div(self, other)
}

///|
#deprecated("replace `impl op_neg` with `impl neg`")
impl Neg with neg(self) {
  Neg::op_neg(self)
}

///|
impl Neg with op_neg(self) {
  Neg::neg(self)
}

///|
#deprecated("replace `impl op_mod` with `impl mod`")
impl Mod with mod(self, other) {
  Mod::op_mod(self, other)
}

///|
impl Mod with op_mod(self, other) {
  Mod::mod(self, other)
}

///|
#deprecated("replace `impl op_shl` with `impl shl`")
impl Shl with shl(self, i) {
  Shl::op_shl(self, i)
}

///|
impl Shl with op_shl(self, i) {
  Shl::shl(self, i)
}

///|
#deprecated("replace `impl op_shr` with `impl shr`")
impl Shr with shr(self, i) {
  Shr::op_shr(self, i)
}

///|
impl Shr with op_shr(self, i) {
  Shr::shr(self, i)
}
