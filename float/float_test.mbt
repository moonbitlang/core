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
test "show" {
  let f : Float = 3.14159
  inspect(f, content="3.141590118408203")
}

///|
test {
  assert_eq(Float::abs(1.0), 1.0)
  assert_eq(Float::abs(-1.0), 1.0)
  let f : Float = Float::default()
  inspect(f.to_string(), content="0")
}

///|
test "abs" {
  inspect(1.0.abs(), content="1")
  inspect((-1.0).abs(), content="1")
  inspect(0.0.abs().reinterpret_as_uint64(), content="0")
  inspect((-0.0).abs().reinterpret_as_uint64(), content="0")
  inspect(@double.not_a_number.abs(), content="NaN")
  inspect((-@double.not_a_number).abs(), content="NaN")
  inspect(@double.infinity.abs(), content="Infinity")
  inspect(@double.neg_infinity.abs(), content="Infinity")
}

///|
test "Float::to_int" {
  inspect((0.0 : Float).to_int(), content="0")
  inspect((1.0 : Float).to_int(), content="1")
  inspect((1.5 : Float).to_int(), content="1")
  inspect((1.9 : Float).to_int(), content="1")
  inspect((2.0 : Float).to_int(), content="2")
  inspect((2.5 : Float).to_int(), content="2")
  inspect((2.9 : Float).to_int(), content="2")
  inspect((-1.0 : Float).to_int(), content="-1")
  inspect((-1.5 : Float).to_int(), content="-1")
  inspect((-1.9 : Float).to_int(), content="-1")
  inspect((-2.0 : Float).to_int(), content="-2")
  inspect((-2.5 : Float).to_int(), content="-2")
  inspect((-2.9 : Float).to_int(), content="-2")
  inspect(((0.0 : Float) / 0.0).to_int(), content="0")
  inspect(@float.not_a_number.to_int(), content="0")
  inspect(((1.0 : Float) / 0.0).to_int(), content="2147483647")
  inspect(@float.infinity.to_int(), content="2147483647")
  inspect(((-1.0 : Float) / 0.0).to_int(), content="-2147483648")
  inspect(@float.neg_infinity.to_int(), content="-2147483648")
  inspect((2147483647.0 : Float).to_int(), content="2147483647")
  inspect((-2147483648.0 : Float).to_int(), content="-2147483648")
  inspect((2147483648.0 : Float).to_int(), content="2147483647")
  inspect((-2147483649.0 : Float).to_int(), content="-2147483648")
}

///|
test "Hash" {
  struct A {
    a : Float
  } derive(Hash)
  let a = A::{ a: 1.0 }
  inspect(Hasher::new(seed=0)..combine(a).finalize(), content="1986884538")
  inspect(Hasher::new(seed=0)..combine(a.a).finalize(), content="1986884538")
  inspect(
    Hasher::new(seed=0)..combine((2.0 : Float)).finalize(),
    content="250978825",
  )
}

///|
test "Float::is_inf/special_values" {
  inspect(@float.infinity.is_inf(), content="true")
  inspect(@float.neg_infinity.is_inf(), content="true")
  inspect(@float.not_a_number.is_inf(), content="false")
  inspect((0.0 : Float).is_inf(), content="false")
  inspect(@float.max_value.is_inf(), content="false")
  inspect(@float.min_value.is_inf(), content="false")
  inspect(@float.min_positive.is_inf(), content="false")
}

///|
test "@float.Float::is_pos_inf/special_values" {
  inspect(@float.infinity.is_pos_inf(), content="true")
  inspect(@float.neg_infinity.is_pos_inf(), content="false")
  inspect(@float.not_a_number.is_pos_inf(), content="false")
  inspect(@float.max_value.is_pos_inf(), content="false")
  inspect((-@float.max_value).is_pos_inf(), content="false")
  inspect(@float.min_positive.is_pos_inf(), content="false")
  inspect((0.0 : Float).is_pos_inf(), content="false")
  inspect((1.0 : Float).is_pos_inf(), content="false")
  inspect((-1.0 : Float).is_pos_inf(), content="false")
}

///|
test "@float.Float::is_neg_inf" {
  inspect((-1.0 : Float).is_neg_inf(), content="false")
  inspect((0.0 : Float).is_neg_inf(), content="false")
  inspect((1.0 : Float).is_neg_inf(), content="false")
  inspect(@float.neg_infinity.is_neg_inf(), content="true")
  inspect(@float.infinity.is_neg_inf(), content="false")
  inspect(@float.not_a_number.is_neg_inf(), content="false")
  inspect(@float.min_value.is_neg_inf(), content="false")
  inspect((@float.min_value - 1.0e38).is_neg_inf(), content="true")
}

///|
test "@float.Float::is_nan" {
  inspect((0.0 : Float).is_nan(), content="false")
  inspect((1.0 : Float).is_nan(), content="false")
  inspect((-1.0 : Float).is_nan(), content="false")
  inspect(@float.not_a_number.is_nan(), content="true")
  inspect(@float.infinity.is_nan(), content="false")
  inspect(@float.neg_infinity.is_nan(), content="false")
  inspect(@float.max_value.is_nan(), content="false")
  inspect(@float.min_value.is_nan(), content="false")
  inspect(@float.min_positive.is_nan(), content="false")
}

///|
test "Float::default()" {
  inspect(Float::default(), content="0")
}

///|
test "Float::to_be_bytes with various values" {
  let f1 : Float = 0.0
  inspect(f1.to_be_bytes(), content="b\"\\x00\\x00\\x00\\x00\"")
  let f2 : Float = -1.0
  inspect(f2.to_be_bytes(), content="b\"\\xbf\\x80\\x00\\x00\"")
  let f3 : Float = @float.infinity
  inspect(f3.to_be_bytes(), content="b\"\\x7f\\x80\\x00\\x00\"")
  let f4 : Float = @float.not_a_number
  inspect(f4.to_be_bytes(), content="b\"\\x7f\\xc0\\x00\\x00\"")
}

///|
test "to_le_bytes for zero" {
  inspect(
    (0.0 : Float).to_le_bytes(),
    content=(
      #|b"\x00\x00\x00\x00"
    ),
  )
  inspect(
    (-0.0 : Float).to_le_bytes(),
    content=(
      #|b"\x00\x00\x00\x80"
    ),
  )
}

///|
test "Float::is_close - infinity should return false" {
  inspect(@float.infinity.is_close(1.0), content="false")
}

///|
test "panic Float::is_close negative tolerance" {
  ignore((1.0 : Float).is_close(1.0, relative_tolerance=-1.0))
}

///|
test "Float::until basics" {
  inspect((0.0 : Float).until(1.0, step=0.5).collect(), content="[0, 0.5]")
  inspect((0.0 : Float).until(1.0, step=0.0).collect(), content="[]")
  inspect(
    (1.0 : Float).until(-1.0, step=-0.5).take(2).collect(),
    content="[1, 0.5]",
  )
}

///|
test "Float::until with NaN step" {
  let values = []
  for x in (1.0 : Float).until(1.0, step=@float.not_a_number, inclusive=true) {
    values.push(x)
  }
  inspect(values, content="[1]")
}
