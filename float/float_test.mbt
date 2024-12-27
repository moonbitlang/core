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

test "show" {
  let f : Float = 3.14159
  inspect!(f, content="3.141590118408203")
}

test {
  assert_eq!(Float::abs(1.0), 1.0)
  assert_eq!(Float::abs(-1.0), 1.0)
  let f : Float = Float::default()
  inspect!(f.to_string(), content="0")
}

test "abs" {
  inspect!(1.0.abs(), content="1")
  inspect!((-1.0).abs(), content="1")
  inspect!(0.0.abs().reinterpret_as_uint64(), content="0")
  inspect!((-0.0).abs().reinterpret_as_uint64(), content="0")
  inspect!(@double.not_a_number.abs(), content="NaN")
  inspect!((-@double.not_a_number).abs(), content="NaN")
  inspect!(@double.infinity.abs(), content="Infinity")
  inspect!(@double.neg_infinity.abs(), content="Infinity")
}

test "Float::to_int" {
  inspect!((0.0 : Float).to_int(), content="0")
  inspect!((1.0 : Float).to_int(), content="1")
  inspect!((1.5 : Float).to_int(), content="1")
  inspect!((1.9 : Float).to_int(), content="1")
  inspect!((2.0 : Float).to_int(), content="2")
  inspect!((2.5 : Float).to_int(), content="2")
  inspect!((2.9 : Float).to_int(), content="2")
  inspect!((-1.0 : Float).to_int(), content="-1")
  inspect!((-1.5 : Float).to_int(), content="-1")
  inspect!((-1.9 : Float).to_int(), content="-1")
  inspect!((-2.0 : Float).to_int(), content="-2")
  inspect!((-2.5 : Float).to_int(), content="-2")
  inspect!((-2.9 : Float).to_int(), content="-2")
  inspect!(((0.0 : Float) / 0.0).to_int(), content="0")
  inspect!(@float.not_a_number.to_int(), content="0")
  inspect!(((1.0 : Float) / 0.0).to_int(), content="2147483647")
  inspect!(@float.infinity.to_int(), content="2147483647")
  inspect!(((-1.0 : Float) / 0.0).to_int(), content="-2147483648")
  inspect!(@float.neg_infinity.to_int(), content="-2147483648")
  inspect!((2147483647.0 : Float).to_int(), content="2147483647")
  inspect!((-2147483648.0 : Float).to_int(), content="-2147483648")
  inspect!((2147483648.0 : Float).to_int(), content="2147483647")
  inspect!((-2147483649.0 : Float).to_int(), content="-2147483648")
}

test "Hash" {
  struct A {
    a : Float
  } derive(Hash)
  let a = A::{ a: 1.0 }
  inspect!(a.hash(), content="1986884538")
  inspect!(a.a.hash(), content="749479517")
  inspect!((2.0 : Float).hash(), content="-1861484393")
}
