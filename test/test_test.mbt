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
#warnings("-deprecated")
test " same_object call with the same object" {
  let s = "Hello"
  @test.same_object(s, s)
}

///|
#warnings("-deprecated")
test "panic same_object call with different objects" {
  let a = "1"
  let b = "2"
  @test.same_object(a, b)
}

///|
#warnings("-deprecated")
test "is_not called with the different objects" {
  let a = "1"
  let b = "2"
  @test.not_same_object(a, b)
}

///|
#warnings("-deprecated")
test "panic is_not called with the same object" {
  let s = "Hello"
  @test.not_same_object(s, s)
}

///|
test "Test name" {
  let t = @test.Test("sample")
  inspect(t.name(), content="sample")
}

///|
suberror MyError {
  NotFound(String)
  Invalid(reason~ : String)
} derive(Debug)

///|
pub extend MyError with @debug.Debug::{to_repr}

///|
fn maybe_raise(should_raise : Bool) -> Unit raise MyError {
  if should_raise {
    raise NotFound("file.txt")
  }
}

///|
fn raise_invalid() -> Unit raise MyError {
  raise Invalid(reason="bad input")
}

///|
test "assert_raise passes when the callback raises" {
  @test.assert_raise(() => maybe_raise(true))
}

///|
test "panic assert_raise fails when the callback does not raise" {
  @test.assert_raise(() => maybe_raise(false))
}

///|
test "expect_error returns the raised error" {
  let err = @test.expect_error(() => maybe_raise(true))
  debug_inspect(
    err,
    content=(
      #|NotFound("file.txt")
    ),
  )
}

///|
test "expect_error result composes with guard ... is" {
  guard @test.expect_error(() => maybe_raise(true)) is NotFound(_) else {
    @test.fail("expected NotFound variant")
  }
}

///|
test "expect_error result composes with assert_true(... is ...)" {
  let err = @test.expect_error(raise_invalid)
  assert_true(err is Invalid(reason=_))
}

///|
test "panic expect_error fails when the callback does not raise" {
  let _ = @test.expect_error(() => maybe_raise(false))
}
