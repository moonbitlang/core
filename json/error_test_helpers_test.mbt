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
fn[E : Error] expect_error(
  f : () -> Unit raise E,
  msg : String,
  loc~ : SourceLoc,
) -> E raise Failure {
  try f() catch {
    err => err
  } noraise {
    _ => fail(msg, loc~)
  }
}

///|
#callsite(autofill(loc))
fn expect_parse_error(
  input : StringView,
  msg : String,
  loc~ : SourceLoc,
) -> @json.ParseError raise Failure {
  expect_error(() => @json.parse(input) |> ignore, msg, loc~)
}

///|
#callsite(autofill(loc))
fn expect_json_decode_error(
  f : () -> Unit raise @json.JsonDecodeError,
  msg : String,
  loc~ : SourceLoc,
) -> @json.JsonDecodeError raise Failure {
  expect_error(f, msg, loc~)
}
