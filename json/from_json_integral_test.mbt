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
fn decode_int_and_uint(json : Json) -> String {
  let i = try (@json.from_json(json) : Int32) catch {
    JsonDecodeError((_, msg)) => msg
  } noraise {
    v => v.to_string()
  }
  let u = try (@json.from_json(json) : UInt32) catch {
    JsonDecodeError((_, msg)) => msg
  } noraise {
    v => v.to_string()
  }
  "\{i} | \{u}"
}

///|
test "Int/UInt FromJson accept integral numbers" {
  inspect(
    decode_int_and_uint(@json.parse("5")),
    content=(
      #|5 | 5
    ),
  )
  inspect(
    decode_int_and_uint(@json.parse("2.0")),
    content=(
      #|2 | 2
    ),
  )
  inspect(
    decode_int_and_uint(@json.parse("1e3")),
    content=(
      #|1000 | 1000
    ),
  )
  inspect(
    decode_int_and_uint(@json.parse("-0")),
    content=(
      #|0 | 0
    ),
  )
  inspect(
    decode_int_and_uint(@json.parse("-0.0")),
    content=(
      #|0 | 0
    ),
  )
}

///|
test "Int/UInt FromJson reject non-integral numbers" {
  inspect(
    decode_int_and_uint(@json.parse("1.5")),
    content=(
      #|Int::from_json: expected integer | UInt::from_json: expected integer
    ),
  )
  inspect(
    decode_int_and_uint(@json.parse("-0.25")),
    content=(
      #|Int::from_json: expected integer | UInt::from_json: expected integer
    ),
  )
  inspect(
    decode_int_and_uint(@json.parse("2147483647.5")),
    content=(
      #|Int::from_json: expected integer | UInt::from_json: expected integer
    ),
  )
  inspect(
    decode_int_and_uint(Json::number(@double.not_a_number)),
    content=(
      #|Int::from_json: expected integer | UInt::from_json: expected integer
    ),
  )
  inspect(
    decode_int_and_uint(Json::number(@double.infinity)),
    content=(
      #|Int::from_json: expected number | UInt::from_json: expected number
    ),
  )
}

///|
test "Int64/UInt64 FromJson explain the string encoding" {
  let i = try (@json.from_json(Json::number(5)) : Int64) catch {
    JsonDecodeError((_, msg)) => msg
  } noraise {
    v => v.to_string()
  }
  inspect(
    i,
    content=(
      #|Int64::from_json: expected a string such as "5" (Int64 is encoded as a string to avoid precision loss)
    ),
  )
  let u = try (@json.from_json(Json::number(5)) : UInt64) catch {
    JsonDecodeError((_, msg)) => msg
  } noraise {
    v => v.to_string()
  }
  inspect(
    u,
    content=(
      #|UInt64::from_json: expected a string such as "5" (UInt64 is encoded as a string to avoid precision loss)
    ),
  )
}
