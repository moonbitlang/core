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
test "parse cookie success" {
  @debug.debug_inspect(
    Cookie::parse("Cookie=value").unwrap(),
    content=(
      #|{
      #|  name: "Cookie",
      #|  value: "value",
      #|  path: None,
      #|  expires_raw: None,
      #|  max_age: None,
      #|  domain: None,
      #|  secure: false,
      #|  http_only: false,
      #|  extensions: [],
      #|}
    ),
  )
  @debug.debug_inspect(
    Cookie::parse("Cookie=").unwrap(),
    content=(
      #|{
      #|  name: "Cookie",
      #|  value: "",
      #|  path: None,
      #|  expires_raw: None,
      #|  max_age: None,
      #|  domain: None,
      #|  secure: false,
      #|  http_only: false,
      #|  extensions: [],
      #|}
    ),
  )
  @debug.debug_inspect(
    Cookie::parse(
      "Cookie2=value2;path=/path/to/xxx; EXPIRES=Sun, 06 Nov 1994 08:49:37 GMT;Max-age=420000; domain=example.moonbitlang.com;SECURE; httponly; whatever=whatever",
    ).unwrap(),
    content=(
      #|{
      #|  name: "Cookie2",
      #|  value: "value2",
      #|  path: Some("/path/to/xxx"),
      #|  expires_raw: Some("Sun, 06 Nov 1994 08:49:37 GMT"),
      #|  max_age: Some(420000),
      #|  domain: Some("example.moonbitlang.com"),
      #|  secure: true,
      #|  http_only: true,
      #|  extensions: ["whatever=whatever"],
      #|}
    ),
  )
}

///|
test "parse cookie ignores malformed lines and attributes" {
  @debug.debug_inspect(Cookie::parse("Cookie"), content="None")
  @debug.debug_inspect(Cookie::parse("Cookie; Path=/"), content="None")
  for
    max_age in [
      "xxx", "soon", "+60", "", "-", "3600, c=d", "99999999999999999999",
    ] {
    let cookie = Cookie::parse("Cookie=value; Max-Age=\{max_age}").unwrap()
    @test.assert_eq(cookie.name, "Cookie")
    @test.assert_eq(cookie.value, "value")
    @test.assert_eq(cookie.max_age, None)
  }
  for
    (max_age, expected) in [
      ("-1", -1L),
      ("0", 0L),
      ("60", 60L),
      ("9223372036854775807", 9223372036854775807L),
      ("-9223372036854775808", -9223372036854775808L),
    ] {
    let cookie = Cookie::parse("Cookie=value; Max-Age=\{max_age}").unwrap()
    @test.assert_eq(cookie.max_age, Some(expected))
  }
  let cookie = Cookie::parse("Cookie=value; Max-Age=60; Max-Age=soon").unwrap()
  @debug.debug_inspect(cookie.max_age, content="Some(60)")
}

///|
test "parse cookie preserves empty attributes" {
  @debug.debug_inspect(
    Cookie::parse("Cookie=value").unwrap().extensions,
    content="[]",
  )
  @debug.debug_inspect(
    Cookie::parse("Cookie=value;").unwrap().extensions,
    content=(
      #|[""]
    ),
  )
  @debug.debug_inspect(
    Cookie::parse("Cookie=value;; secure; ;").unwrap().extensions,
    content=(
      #|["", "", ""]
    ),
  )
}

///|
test "parse cookie preserves equals in values" {
  inspect(Cookie::parse("Cookie=a=b==").unwrap().value, content="a=b==")
  let cookie = Cookie::parse("Cookie=a=b==; path=/a=b; extension=x=y").unwrap()
  inspect(cookie.value, content="a=b==")
  @debug.debug_inspect(
    cookie.path,
    content=(
      #|Some("/a=b")
    ),
  )
  @debug.debug_inspect(
    cookie.extensions,
    content=(
      #|["extension=x=y"]
    ),
  )
}
