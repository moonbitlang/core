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

// Integer literals beyond 2^53 - 1 must parse to the correctly rounded
// double (like every mainstream JSON implementation), with the exact source
// text preserved in `repr` so `stringify` stays lossless. The infinity
// sentinel is reserved for values genuinely beyond double range.
//
// Previously `lex_integer_end` conflated "cannot be represented exactly in
// 2^53" with "out of double range": any integer-shaped literal above
// 2^53 - 1 collapsed to `Number(Infinity, repr=...)`, so the same value
// parsed differently in integer and exponent form ("10000000000000000000"
// vs "1e19"), all such numbers compared equal, and `from_json : Double`
// raised on values doubles represent fine.

///|
test "big integer literals parse to correctly rounded doubles" {
  // 1e19 is exactly representable as a double.
  let parsed = @json.parse("10000000000000000000")
  assert_true(parsed is Number(1.0e19, repr=Some("10000000000000000000")))
  inspect(parsed.stringify(), content="10000000000000000000")

  // 2^53 + 1 rounds (ties to even) down to 2^53; the text is preserved.
  let parsed = @json.parse("9007199254740993")
  assert_true(
    parsed is Number(9007199254740992.0, repr=Some("9007199254740993")),
  )
  inspect(parsed.stringify(), content="9007199254740993")

  // 2^53 itself is exactly representable.
  let parsed = @json.parse("9007199254740992")
  assert_true(
    parsed is Number(9007199254740992.0, repr=Some("9007199254740992")),
  )

  // A 29-digit literal rounds to the nearest double.
  let parsed = @json.parse("12345678901234567890123456789")
  assert_true(
    parsed
    is Number(1.2345678901234568e28, repr=Some("12345678901234567890123456789")),
  )
  inspect(parsed.stringify(), content="12345678901234567890123456789")

  // Negative values round symmetrically.
  let parsed = @json.parse("-10000000000000000000")
  assert_true(parsed is Number(-1.0e19, repr=Some("-10000000000000000000")))
  inspect(parsed.stringify(), content="-10000000000000000000")
}

///|
test "integer and exponent spellings of the same value parse equal" {
  assert_eq(@json.parse("10000000000000000000"), @json.parse("1e19"))
  assert_eq(@json.parse("-10000000000000000000"), @json.parse("-1e19"))
}

///|
test "distinct big integers do not compare equal" {
  assert_not_eq(
    @json.parse("9007199254740993"),
    @json.parse("99999999999999999999"),
  )
  assert_not_eq(
    @json.parse("10000000000000000000"),
    @json.parse("-10000000000000000000"),
  )
}

///|
test "from_json decodes big integer texts as Double" {
  let value : Double = @json.from_json(@json.parse("10000000000000000000"))
  inspect(value, content="10000000000000000000")
  let value : Double = @json.from_json(@json.parse("9007199254740993"))
  inspect(value, content="9007199254740992")
}

///|
test "only integers beyond double range keep the infinity sentinel" {
  let huge = "9".repeat(400)
  let parsed = @json.parse(huge)
  assert_true(
    parsed is Number(sentinel, repr=Some(repr)) &&
    sentinel == @double.infinity &&
    repr == huge,
  )
  inspect(parsed.stringify().length(), content="400")
  let negative_huge = "-" + huge
  let parsed = @json.parse(negative_huge)
  assert_true(
    parsed is Number(sentinel, repr=Some(repr)) &&
    sentinel == @double.neg_infinity &&
    repr == negative_huge,
  )
  // The sentinel still refuses to decode as a Double.
  try (@json.from_json(parsed) : Double) |> ignore catch {
    _ => ()
  } noraise {
    _ => fail("expected out-of-range sentinel to fail Double decoding")
  }
}
