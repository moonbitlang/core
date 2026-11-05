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
fn decode_int64(json : Json) -> String {
  let v : Int64 = @json.from_json(json) catch {
    JsonDecodeError((_, msg)) => return msg
  }
  v.to_string()
}

///|
fn decode_uint64(json : Json) -> String {
  let v : UInt64 = @json.from_json(json) catch {
    JsonDecodeError((_, msg)) => return msg
  }
  v.to_string()
}

///|
fn decode_both(text : String, preserve_number_repr~ : Bool = false) -> String {
  let json = @json.parse(text, preserve_number_repr~) catch {
    _ => abort("bad test input")
  }
  "\{decode_int64(json)} | \{decode_uint64(json)}"
}

///|
test "Int64/UInt64 FromJson accept integral numbers" {
  inspect(decode_both("5"), content="5 | 5")
  inspect(decode_both("0"), content="0 | 0")
  inspect(decode_both("-5"), content="-5 | UInt64::from_json: overflow")
  inspect(decode_both("1e3"), content="1000 | 1000")
  inspect(decode_both("2.0"), content="2 | 2")
  inspect(
    decode_both("9007199254740991"),
    content="9007199254740991 | 9007199254740991",
  )
  inspect(
    decode_both("-9007199254740991"),
    content="-9007199254740991 | UInt64::from_json: overflow",
  )
}

///|
test "Int64/UInt64 FromJson reject non-integral numbers" {
  inspect(
    decode_both("1.5"),
    content="Int64::from_json: expected integer | UInt64::from_json: expected integer",
  )
  inspect(
    decode_both("-0.25"),
    content="Int64::from_json: expected integer | UInt64::from_json: expected integer",
  )
  inspect(
    decode_int64(Json::number(@double.not_a_number)),
    content="Int64::from_json: expected integer",
  )
  inspect(
    decode_uint64(Json::number(@double.not_a_number)),
    content="UInt64::from_json: expected integer",
  )
  inspect(
    decode_int64(Json::number(@double.infinity)),
    content="Int64::from_json: overflow",
  )
  inspect(
    decode_uint64(Json::number(@double.neg_infinity)),
    content="UInt64::from_json: overflow",
  )
}

///|
test "Int64/UInt64 FromJson decode large integers from repr" {
  // `parse` keeps the source text of integers beyond 2^53 - 1 in `repr`.
  inspect(
    decode_both("9007199254740993"),
    content="9007199254740993 | 9007199254740993",
  )
  inspect(
    decode_both("9223372036854775807"),
    content="9223372036854775807 | 9223372036854775807",
  )
  inspect(
    decode_both("-9223372036854775808"),
    content="-9223372036854775808 | UInt64::from_json: overflow",
  )
  inspect(
    decode_both("18446744073709551615"),
    content="Int64::from_json: overflow | 18446744073709551615",
  )
  inspect(
    decode_both("18446744073709551616"),
    content="Int64::from_json: overflow | UInt64::from_json: overflow",
  )
  inspect(
    decode_both("-9223372036854775809"),
    content="Int64::from_json: overflow | UInt64::from_json: overflow",
  )
}

///|
test "Int64/UInt64 FromJson reject large numbers without exact digits" {
  // Without `repr`, 2^53 is ambiguous: 2^53 + 1 parses to the same Double.
  inspect(
    decode_int64(Json::number(9007199254740992.0)),
    content="Int64::from_json: overflow",
  )
  inspect(
    decode_uint64(Json::number(9007199254740992.0)),
    content="UInt64::from_json: overflow",
  )
  inspect(
    decode_int64(Json::number(-9007199254740992.0)),
    content="Int64::from_json: overflow",
  )
  inspect(
    decode_both("1e20"),
    content="Int64::from_json: overflow | UInt64::from_json: overflow",
  )
  inspect(
    decode_both("9007199254740993.0"),
    content="Int64::from_json: overflow | UInt64::from_json: overflow",
  )
}

///|
test "Int64/UInt64 FromJson with preserve_number_repr" {
  inspect(decode_both("5", preserve_number_repr=true), content="5 | 5")
  inspect(
    decode_both("-5", preserve_number_repr=true),
    content="-5 | UInt64::from_json: overflow",
  )
  inspect(decode_both("-0", preserve_number_repr=true), content="0 | 0")
  inspect(decode_both("1e3", preserve_number_repr=true), content="1000 | 1000")
  inspect(
    decode_both("1.5", preserve_number_repr=true),
    content="Int64::from_json: expected integer | UInt64::from_json: expected integer",
  )
  inspect(
    decode_both("12345678901234567890", preserve_number_repr=true),
    content="Int64::from_json: overflow | 12345678901234567890",
  )
  // A `repr` that is not an integer literal is not parsed; the Double decides.
  inspect(decode_int64(Json::number(5.0, repr="0x10")), content="5")
}

///|
test "Int64/UInt64 FromJson still accept strings" {
  inspect(decode_int64(Json("-123")), content="-123")
  inspect(decode_uint64(Json("123")), content="123")
  inspect(
    decode_int64(Json("9223372036854775807")),
    content="9223372036854775807",
  )
  inspect(
    decode_uint64(Json("18446744073709551615")),
    content="18446744073709551615",
  )
  inspect(
    decode_int64(Json::null()),
    content="Int64::from_json: expected number or string",
  )
  inspect(
    decode_uint64(Json::null()),
    content="UInt64::from_json: expected number or string",
  )
}

///|
test "Int64/UInt64 round-trip through ToJson" {
  let i : Int64 = @json.from_json(Json(-9223372036854775808L))
  inspect(i, content="-9223372036854775808")
  let u : UInt64 = @json.from_json(Json(18446744073709551615UL))
  inspect(u, content="18446744073709551615")
}

///|
test "Int64/UInt64 FromJson fall back to the value when repr has no digits" {
  // `Json::number` accepts any `repr`, including one that is not a digit run
  // (a bare sign, or an empty string); the value is used instead.
  let bare_sign = Json::number(7.0, repr="-")
  let empty = Json::number(7.0, repr="")
  inspect(
    "\{decode_int64(bare_sign)} | \{decode_uint64(bare_sign)}",
    content="7 | 7",
  )
  inspect("\{decode_int64(empty)} | \{decode_uint64(empty)}", content="7 | 7")
}
