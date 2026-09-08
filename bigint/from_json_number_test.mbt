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
#callsite(autofill(loc))
fn decode(json : Json, loc~ : SourceLoc) -> @bigint.BigInt raise Failure {
  @json.from_json(json) catch {
    err => fail("unexpected decode failure: \{err}", loc~)
  }
}

///|
#callsite(autofill(loc))
fn decode_error(json : Json, loc~ : SourceLoc) -> String raise Failure {
  let err = try ignore((@json.from_json(json) : @bigint.BigInt)) catch {
    err => err
  } noraise {
    _ => fail("expected a decode failure", loc~)
  }
  let JsonDecodeError((_, message)) = err
  message
}

///|
test "BigInt from_json keeps every digit of a big integer literal" {
  // The literal outruns the exact-integer range of a double, so the parser
  // preserves its text; decoding the rounded double instead would lose the
  // last six digits.
  let json = @json.parse("12345678901234567890123")
  assert_true(json is Number(1.2345678901234568e22, repr=Some(_)))
  inspect(decode(json), content="12345678901234567890123")
  inspect(
    decode(@json.parse("-98765432109876543210987")),
    content="-98765432109876543210987",
  )
}

///|
test "BigInt from_json decodes plain numbers exactly" {
  inspect(decode(Json::number(0)), content="0")
  inspect(decode(Json::number(-0.0)), content="0")
  inspect(decode(Json::number(42)), content="42")
  inspect(decode(Json::number(-42)), content="-42")
  inspect(decode(@json.parse("9007199254740992")), content="9007199254740992")
  inspect(decode(@json.parse("9007199254740993")), content="9007199254740993")
  // 2^63 is one past the top of Int64 (though its negation still fits), so
  // decoding has to go through the significand and exponent rather than a
  // fixed-width integer.
  inspect(
    decode(Json::number(9223372036854775808.0)),
    content="9223372036854775808",
  )
  inspect(
    decode(Json::number(-9223372036854775808.0)),
    content="-9223372036854775808",
  )
  inspect(
    decode(Json::number(18446744073709551616.0)),
    content="18446744073709551616",
  )
  // 2^52 + 1: the first integer needing all 53 significand bits.
  inspect(decode(Json::number(4503599627370497.0)), content="4503599627370497")
  // The largest finite double is (2^53 - 1) * 2^971, the widest shift the
  // conversion ever performs.
  let max_double = decode(Json::number(@double.max_value))
  assert_eq(max_double, (2N.pow(53N) - 1N) << 971)
  inspect(max_double.to_string().length(), content="309")
}

///|
test "BigInt from_json decodes a double no fixed-width integer can hold" {
  // 1e300 is neither an integer literal nor out of the range of a double, so
  // the parser keeps no text for it and the double itself is decoded. That
  // double is not exactly 10^300 but the nearest double to it, and that is the
  // integer that comes out.
  let json = @json.parse("1e300")
  assert_true(json is Number(1.0e300, repr=None))
  let decoded = decode(json)
  inspect(decoded.to_string().length(), content="301")
  inspect(
    decoded.to_string().view(end_offset=20),
    content="10000000000000000525",
  )
  assert_eq(decoded % 2N, 0N)
}

///|
test "BigInt from_json round trips its own encoding" {
  let values = [0N, 1N, -1N, 12345678901234567890N, -12345678901234567890N]
  for value in values {
    assert_eq(decode(value.to_json()), value)
  }
}

///|
test "BigInt from_json rejects numbers that are not integers" {
  inspect(
    decode_error(Json::number(1.5)),
    content="BigInt::from_json: number is not an integer",
  )
  inspect(
    decode_error(Json::number(@double.not_a_number)),
    content="BigInt::from_json: number is not finite",
  )
  // Every non-zero subnormal is a proper fraction, so none of them decode.
  inspect(
    decode_error(Json::number(@double.min_positive / 2.0)),
    content="BigInt::from_json: number is not an integer",
  )
  inspect(
    decode_error(Json::number(@double.infinity)),
    content="BigInt::from_json: number is not finite",
  )
  // An exponent-form literal beyond the range of a double keeps its text, and
  // that text is authoritative: it is not a plain integer literal, so it is
  // rejected rather than decoded from the infinity it rounded to.
  inspect(
    decode_error(@json.parse("1e400")),
    content=(
      #|BigInt::from_json: `1e400` is not a plain integer literal
    ),
  )
  inspect(
    decode_error(Json::number(1, repr="oops")),
    content=(
      #|BigInt::from_json: `oops` is not a plain integer literal
    ),
  )
  inspect(
    decode_error(Json("not-a-number")),
    content="BigInt::from_json: invalid number in string representation",
  )
  inspect(
    decode_error(Json(true)),
    content="BigInt::from_json: expected a number or its string representation",
  )
}
