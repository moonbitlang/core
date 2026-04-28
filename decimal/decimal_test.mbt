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
fn dec(s : StringView) -> @decimal.Decimal raise @decimal.DecimalError {
  @decimal.Decimal::from_string(s)
}

///|
test "parse and canonical formatting" {
  inspect(dec("0"), content="0")
  inspect(dec("-0.000"), content="0")
  inspect(dec("+00123.4500"), content="123.45")
  inspect(dec(".123"), content="0.123")
  inspect(dec("123."), content="123")
  inspect(dec("1e-3"), content="0.001")
  inspect(dec("1_23.45_00e+1_2"), content="123450000000000")
  inspect(dec("1e-2147483648").exponent(), content="-2147483648")
  inspect(
    dec("999999999999999999999999999999999999.000"),
    content="999999999999999999999999999999999999",
  )
}

///|
test "parse invalid syntax" {
  inspect(
    try? @decimal.Decimal::from_string(""),
    content="Err(InvalidSyntax(\"\"))",
  )
  inspect(
    try? @decimal.Decimal::from_string("."),
    content="Err(InvalidSyntax(\".\"))",
  )
  inspect(
    try? @decimal.Decimal::from_string("-"),
    content="Err(InvalidSyntax(\"-\"))",
  )
  inspect(
    try? @decimal.Decimal::from_string("_1"),
    content="Err(InvalidSyntax(\"_1\"))",
  )
  inspect(
    try? @decimal.Decimal::from_string("1__2"),
    content="Err(InvalidSyntax(\"1__2\"))",
  )
  inspect(
    try? @decimal.Decimal::from_string("1_.2"),
    content="Err(InvalidSyntax(\"1_.2\"))",
  )
  inspect(
    try? @decimal.Decimal::from_string("1.2_e3"),
    content="Err(InvalidSyntax(\"1.2_e3\"))",
  )
  inspect(
    try? @decimal.Decimal::from_string("1e+_2"),
    content="Err(InvalidSyntax(\"1e+_2\"))",
  )
  inspect(
    try? @decimal.Decimal::from_string("1e2147483648"),
    content="Err(InvalidSyntax(\"1e2147483648\"))",
  )
  inspect(
    try? @decimal.Decimal::from_string("10e2147483647"),
    content="Err(InvalidSyntax(\"10e2147483647\"))",
  )
}

///|
test "constructors and accessors canonicalize" {
  let n = @decimal.Decimal::from_bigint(
    @bigint.BigInt::from_string("1234500"),
    exponent=-4,
  )
  inspect(n, content="123.45")
  inspect(n.coefficient(), content="12345")
  inspect(n.exponent(), content="-2")
  inspect(@decimal.Decimal::from_int(-42), content="-42")
  inspect(@decimal.Decimal::from_int64(1234567890123L), content="1234567890123")
  inspect(@decimal.Decimal::from_uint(42U), content="42")
  inspect(@decimal.Decimal::from_uint64(42UL), content="42")
  inspect(@decimal.Decimal::default().is_zero(), content="true")
  inspect(dec("-12.5").abs(), content="12.5")
}

///|
test "arithmetic" {
  inspect(dec("1.2") + dec("3.45"), content="4.65")
  inspect(dec("3.45") - dec("1.2"), content="2.25")
  inspect(dec("-3.45") + dec("1.20"), content="-2.25")
  inspect(dec("12.5") * dec("-0.2"), content="-2.5")
  inspect(-dec("12.500"), content="-12.5")
  inspect(
    dec("1000000000000000000000000.01") + dec("0.09"),
    content="1000000000000000000000000.1",
  )
}

///|
test "equality compare and hash use canonical value" {
  let a = dec("1.50")
  let b = dec("1.5")
  let c = dec("1.500e0")
  inspect(a == b, content="true")
  inspect(b == c, content="true")
  inspect(a.compare(dec("1.49")), content="1")
  inspect(a.compare(dec("1.50")), content="0")
  inspect(a.compare(dec("1.51")), content="-1")
  inspect(Hash::hash(a) == Hash::hash(b), content="true")
}

///|
test "rounding modes" {
  inspect(dec("2.5").round(scale=0, mode=HalfEven), content="2")
  inspect(dec("3.5").round(scale=0, mode=HalfEven), content="4")
  inspect(dec("-2.5").round(scale=0, mode=HalfEven), content="-2")
  inspect(dec("2.5").round(scale=0, mode=HalfTowardZero), content="2")
  inspect(dec("-2.5").round(scale=0, mode=HalfTowardZero), content="-2")
  inspect(dec("2.5").round(scale=0, mode=HalfAwayFromZero), content="3")
  inspect(dec("-2.5").round(scale=0, mode=HalfAwayFromZero), content="-3")
  inspect(dec("2.1").round(scale=0, mode=AwayFromZero), content="3")
  inspect(dec("-2.1").round(scale=0, mode=AwayFromZero), content="-3")
  inspect(dec("2.9").round(scale=0, mode=TowardZero), content="2")
  inspect(dec("-2.9").round(scale=0, mode=TowardZero), content="-2")
  inspect(dec("2.1").round(scale=0, mode=TowardPositiveInfinity), content="3")
  inspect(dec("-2.1").round(scale=0, mode=TowardPositiveInfinity), content="-2")
  inspect(dec("2.1").round(scale=0, mode=TowardNegativeInfinity), content="2")
  inspect(dec("-2.1").round(scale=0, mode=TowardNegativeInfinity), content="-3")
  inspect(dec("12.345").round(scale=2, mode=HalfEven), content="12.34")
  inspect(dec("12.355").round(scale=2, mode=HalfEven), content="12.36")
  inspect(dec("1.005").round(scale=2, mode=HalfEven), content="1")
  inspect(dec("149").round(scale=-1, mode=HalfEven), content="150")
  inspect(dec("145").round(scale=-1, mode=HalfEven), content="140")
}

///|
test "division" {
  inspect(dec("1").div_exact(dec("2")), content="0.5")
  inspect(dec("1.5").div_exact(dec("0.25")), content="6")
  inspect(dec("-1").div_exact(dec("8")), content="-0.125")
  inspect(
    try? dec("1").div_exact(dec("3")),
    content="Err(NonTerminatingDivision)",
  )
  inspect(try? dec("1").div_exact(dec("0")), content="Err(DivisionByZero)")
  inspect(dec("1").div_round(dec("3"), scale=2), content="0.33")
  inspect(
    dec("2").div_round(dec("3"), scale=0, mode=HalfAwayFromZero),
    content="1",
  )
  inspect(
    dec("-2").div_round(dec("3"), scale=0, mode=HalfAwayFromZero),
    content="-1",
  )
  inspect(dec("1").div_round(dec("4"), scale=4), content="0.25")
  inspect(
    try? dec("1").div_round(dec("0"), scale=2),
    content="Err(DivisionByZero)",
  )
}

///|
test "exact bigint conversion" {
  inspect(dec("1200").to_bigint_exact(), content="1200")
  inspect(dec("12.00").to_bigint_exact(), content="12")
  inspect(try? dec("12.01").to_bigint_exact(), content="Err(InexactConversion)")
}

///|
test "json conversion" {
  let value = dec("12345678901234567890.125")
  inspect(value.to_json(), content="String(\"12345678901234567890.125\")")
  let decoded : @decimal.Decimal = @json.from_json(value.to_json())
  inspect(decoded, content="12345678901234567890.125")
  inspect(
    try? (@json.from_json(Json::number(1.5)) : @decimal.Decimal),
    content=(
      #|Err(JsonDecodeError((, "Decimal::from_json: expected decimal in string representation")))
    ),
  )
  inspect(
    try? (@json.from_json(Json::string("not-decimal")) : @decimal.Decimal),
    content=(
      #|Err(JsonDecodeError((, "Decimal::from_json: invalid decimal string")))
    ),
  )
}

///|
test "panic decimal round scale out of range" {
  dec("1").round(scale=-2147483648) |> ignore
}

///|
test "panic decimal exponent overflow in constructor" {
  @decimal.Decimal::from_bigint(
    @bigint.BigInt::from_int(10),
    exponent=2147483647,
  )
  |> ignore
}
