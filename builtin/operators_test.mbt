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
test "deprecated operator helpers" {
  inspect(Add::op_add(1, 2), content="3")
  inspect(Sub::op_sub(5, 3), content="2")
  inspect(Mul::op_mul(2, 3), content="6")
  inspect(Div::op_div(8, 2), content="4")
  inspect(Mod::op_mod(7, 4), content="3")
  inspect(Neg::op_neg(5), content="-5")
  inspect(Shl::op_shl(1, 3), content="8")
  inspect(Shr::op_shr(8, 2), content="2")
}
