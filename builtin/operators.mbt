// Copyright 2025 International Digital Economy Academy
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
  op_add(Self, Self) -> Self
}

///|
/// types implementing this trait can use the `-` operator
pub(open) trait Sub {
  op_sub(Self, Self) -> Self
}

///|
/// types implementing this trait can use the `*` operator
pub(open) trait Mul {
  op_mul(Self, Self) -> Self
}

///|
/// types implementing this trait can use the `/` operator
pub(open) trait Div {
  op_div(Self, Self) -> Self
}

///|
/// types implementing this trait can use the unary `-` operator
pub(open) trait Neg {
  op_neg(Self) -> Self
}

///|
/// types implementing this trait can use the `%` operator
pub(open) trait Mod {
  op_mod(Self, Self) -> Self
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
  op_shl(Self, Int) -> Self
}

///|
/// types implementing this trait can use the `>>` operator
pub(open) trait Shr {
  op_shr(Self, Int) -> Self
}
