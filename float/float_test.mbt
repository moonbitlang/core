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
  let f : Float = (Default::default() : Float)
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
  inspect(Float(0.0).to_int(), content="0")
  inspect(Float(1.0).to_int(), content="1")
  inspect(Float(1.5).to_int(), content="1")
  inspect(Float(1.9).to_int(), content="1")
  inspect(Float(2.0).to_int(), content="2")
  inspect(Float(2.5).to_int(), content="2")
  inspect(Float(2.9).to_int(), content="2")
  inspect(Float(-1.0).to_int(), content="-1")
  inspect(Float(-1.5).to_int(), content="-1")
  inspect(Float(-1.9).to_int(), content="-1")
  inspect(Float(-2.0).to_int(), content="-2")
  inspect(Float(-2.5).to_int(), content="-2")
  inspect(Float(-2.9).to_int(), content="-2")
  inspect((Float(0.0) / 0.0).to_int(), content="0")
  inspect(@float.not_a_number.to_int(), content="0")
  inspect((Float(1.0) / 0.0).to_int(), content="2147483647")
  inspect(@float.infinity.to_int(), content="2147483647")
  inspect((Float(-1.0) / 0.0).to_int(), content="-2147483648")
  inspect(@float.neg_infinity.to_int(), content="-2147483648")
  inspect(Float(2147483647.0).to_int(), content="2147483647")
  inspect(Float(-2147483648.0).to_int(), content="-2147483648")
  inspect(Float(2147483648.0).to_int(), content="2147483647")
  inspect(Float(-2147483649.0).to_int(), content="-2147483648")
}

///|
priv struct FloatHashInput {
  a : Float
} derive(Hash)

///|
test "Hash" {
  let a = FloatHashInput::{ a: 1.0, }
  let h1 = Hasher(seed=0)
  h1.combine(a)
  inspect(h1.finalize(), content="1986884538")
  let h2 = Hasher(seed=0)
  h2.combine(a.a)
  inspect(h2.finalize(), content="1986884538")
  let h3 = Hasher(seed=0)
  h3.combine(Float(2.0))
  inspect(h3.finalize(), content="250978825")
}

///|
test "Float::is_inf/special_values" {
  inspect(@float.infinity.is_inf(), content="true")
  inspect(@float.neg_infinity.is_inf(), content="true")
  inspect(@float.not_a_number.is_inf(), content="false")
  inspect(Float(0.0).is_inf(), content="false")
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
  inspect(Float(0.0).is_pos_inf(), content="false")
  inspect(Float(1.0).is_pos_inf(), content="false")
  inspect(Float(-1.0).is_pos_inf(), content="false")
}

///|
test "@float.Float::is_neg_inf" {
  inspect(Float(-1.0).is_neg_inf(), content="false")
  inspect(Float(0.0).is_neg_inf(), content="false")
  inspect(Float(1.0).is_neg_inf(), content="false")
  inspect(@float.neg_infinity.is_neg_inf(), content="true")
  inspect(@float.infinity.is_neg_inf(), content="false")
  inspect(@float.not_a_number.is_neg_inf(), content="false")
  inspect(@float.min_value.is_neg_inf(), content="false")
  inspect((@float.min_value - 1.0e38).is_neg_inf(), content="true")
}

///|
test "@float.Float::is_nan" {
  inspect(Float(0.0).is_nan(), content="false")
  inspect(Float(1.0).is_nan(), content="false")
  inspect(Float(-1.0).is_nan(), content="false")
  inspect(@float.not_a_number.is_nan(), content="true")
  inspect(@float.infinity.is_nan(), content="false")
  inspect(@float.neg_infinity.is_nan(), content="false")
  inspect(@float.max_value.is_nan(), content="false")
  inspect(@float.min_value.is_nan(), content="false")
  inspect(@float.min_positive.is_nan(), content="false")
}

///|
test "Float::default()" {
  inspect((Default::default() : Float), content="0")
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
    Float(0.0).to_le_bytes(),
    content=(
      #|b"\x00\x00\x00\x00"
    ),
  )
  inspect(
    Float(-0.0).to_le_bytes(),
    content=(
      #|b"\x00\x00\x00\x80"
    ),
  )
}

///|
test "Float::clamp" {
  inspect(Float(0.5).clamp(min=0.0, max=1.0), content="0.5")
  inspect(Float(-1.0).clamp(min=0.0, max=1.0), content="0")
  inspect(Float(2.0).clamp(min=0.0, max=1.0), content="1")
}

///|
test "panic Float::clamp with invalid range" {
  ignore(Float(0.5).clamp(min=1.0, max=0.0))
}

///|
test "Float::lerp" {
  inspect(Float(0.0).lerp(target=10.0, t=0.25), content="2.5")
  inspect(Float(5.0).lerp(target=15.0, t=0.0), content="5")
  inspect(Float(5.0).lerp(target=15.0, t=1.0), content="15")
}

///|
test "Float::is_close - infinity should return false" {
  inspect(@float.infinity.is_close(1.0), content="false")
}

///|
test "panic Float::is_close negative tolerance" {
  ignore(Float(1.0).is_close(1.0, relative_tolerance=-1.0))
}

///|
#warnings("-deprecated")
test "Float::until basics" {
  debug_inspect(Float(0.0).until(1.0, step=0.5).collect(), content="[0, 0.5]")
  debug_inspect(Float(0.0).until(1.0, step=0.0).collect(), content="[]")
  debug_inspect(
    Float(1.0).until(-1.0, step=-0.5).take(2).collect(),
    content="[1, 0.5]",
  )
}

///|
#warnings("-deprecated")
test "Float::until with NaN step" {
  let values = []
  for x in Float(1.0).until(1.0, step=@float.not_a_number, inclusive=true) {
    values.push(x)
  }
  debug_inspect(values, content="[1]")
}

///|
test "Float::min and Float::max" {
  assert_eq(Float(1.0).min(2.0), 1.0)
  assert_eq(Float(2.0).min(1.0), 1.0)
  assert_eq(Float(1.0).max(2.0), 2.0)
  assert_eq(Float(2.0).max(1.0), 2.0)
}

///|
test "Float::min and Float::max with NaN" {
  assert_eq(@float.not_a_number.min(1.0), 1.0)
  assert_eq(Float(1.0).min(@float.not_a_number), 1.0)
  assert_eq(@float.not_a_number.max(1.0), 1.0)
  assert_eq(Float(1.0).max(@float.not_a_number), 1.0)
  assert_true(@float.not_a_number.min(@float.not_a_number).is_nan())
  assert_true(@float.not_a_number.max(@float.not_a_number).is_nan())
}

///|
test "Float::signum" {
  assert_eq(Float(-2.0).signum(), -1.0)
  assert_eq(Float(1.0).signum(), 1.0)
  assert_eq(Float(0.0).signum(), 0.0)
  assert_true(@float.not_a_number.signum().is_nan())
}

///|
test "Float constructor syntax" {
  inspect(Float(3), content="3")
  inspect(Float(-3.5), content="-3.5")
  inspect(Float(3.2), content="3.200000047683716")
  let x : Float = 42
  inspect(Float(x), content="42")
}

///|
test "equal signed zero values hash equally" {
  inspect(Hash::hash(0.0F) == Hash::hash(-0.0F), content="true")
  let map : Map[Float, Int] = { 0.0F: 42 }
  inspect(map.get(-0.0F) == Some(42), content="true")
}
