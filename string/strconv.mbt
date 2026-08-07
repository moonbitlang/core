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

// Thin wrappers over the internal strconv helpers. The internal package
// raises a structured `StrConvError` so in-module callers can match on the
// failure kind; these wrappers translate it back into `Failure` with the
// historical message strings ("value out of range", "invalid syntax",
// "invalid base"), keeping the public error contract unchanged.

///|
fn[T] with_legacy_failure(
  run : () -> T raise @internal/strconv.StrConvError,
) -> T raise {
  run() catch {
    err => raise Failure::Failure(err.message())
  }
}

///|
/// Parses a string as an `Int64` in the given base (0 infers the base from
/// a `0x`/`0o`/`0b` prefix). Raises `Failure` on invalid syntax, invalid
/// base, or out-of-range values.
pub fn parse_int64(str : StringView, base? : Int = 0) -> Int64 raise {
  with_legacy_failure(() => @internal/strconv.parse_int64(str, base~))
}

///|
/// Parses a string as an `Int` in the given base (0 infers the base from
/// a `0x`/`0o`/`0b` prefix). Raises `Failure` on invalid syntax, invalid
/// base, or out-of-range values.
pub fn parse_int(str : StringView, base? : Int = 0) -> Int raise {
  with_legacy_failure(() => @internal/strconv.parse_int(str, base~))
}

///|
/// Parses a string as a `UInt64` in the given base (0 infers the base from
/// a `0x`/`0o`/`0b` prefix). Raises `Failure` on invalid syntax, invalid
/// base, or out-of-range values.
pub fn parse_uint64(str : StringView, base? : Int = 0) -> UInt64 raise {
  with_legacy_failure(() => @internal/strconv.parse_uint64(str, base~))
}

///|
/// Parses a string as a `UInt` in the given base (0 infers the base from
/// a `0x`/`0o`/`0b` prefix). Raises `Failure` on invalid syntax, invalid
/// base, or out-of-range values.
pub fn parse_uint(str : StringView, base? : Int = 0) -> UInt raise {
  with_legacy_failure(() => @internal/strconv.parse_uint(str, base~))
}

///|
/// Parses `"true"` or `"false"` as a `Bool`. Raises `Failure` on any other
/// input.
pub fn parse_bool(str : StringView) -> Bool raise {
  with_legacy_failure(() => @internal/strconv.parse_bool(str))
}

///|
/// Parses a string as a `Double` with correct rounding. Raises `Failure` on
/// invalid syntax or values beyond double range.
pub fn parse_double(str : StringView) -> Double raise {
  with_legacy_failure(() => @internal/strconv.parse_double(str))
}
