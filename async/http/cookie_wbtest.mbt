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
test "bench Set-Cookie parsing" (b : @bench.T) {
  let cases = [
    ("plain", "sid=abc"),
    ("long cookie", "sid=" + "x".repeat(1024)),
    ("flags", "sid=abc; Secure; HttpOnly"),
    ("lowercase", "sid=abc; path=/api; domain=example.com; secure; httponly"),
    (
      "mixed case", "sid=abc; Path=/api; Domain=example.com; Max-Age=3600; Secure; HttpOnly",
    ),
    ("extensions", "sid=abc; SameSite=Lax; Partitioned; Priority=High"),
    ("long value", "sid=abc; Path=/" + "x".repeat(256) + "; HttpOnly"),
  ]
  for (name, line) in cases {
    b.bench(name~, () => b.keep(Cookie::parse(line)))
  }
}

///|
test "parse cookie success" {
  @debug.debug_inspect(
    Cookie::parse("Cookie=value"),
    content=(
      #|Some(
      #|  {
      #|    name: "Cookie",
      #|    value: "value",
      #|    path: None,
      #|    expires_raw: None,
      #|    max_age: None,
      #|    domain: None,
      #|    secure: false,
      #|    http_only: false,
      #|    extensions: [],
      #|  },
      #|)
    ),
  )
  @debug.debug_inspect(
    Cookie::parse("Cookie="),
    content=(
      #|Some(
      #|  {
      #|    name: "Cookie",
      #|    value: "",
      #|    path: None,
      #|    expires_raw: None,
      #|    max_age: None,
      #|    domain: None,
      #|    secure: false,
      #|    http_only: false,
      #|    extensions: [],
      #|  },
      #|)
    ),
  )
  @debug.debug_inspect(
    Cookie::parse(
      "Cookie2=value2;path=/path/to/xxx; EXPIRES=Sun, 06 Nov 1994 08:49:37 GMT;Max-age=420000; domain=example.moonbitlang.com;SECURE; httponly; whatever=whatever",
    ),
    content=(
      #|Some(
      #|  {
      #|    name: "Cookie2",
      #|    value: "value2",
      #|    path: Some("/path/to/xxx"),
      #|    expires_raw: Some("Sun, 06 Nov 1994 08:49:37 GMT"),
      #|    max_age: Some(420000),
      #|    domain: Some("example.moonbitlang.com"),
      #|    secure: true,
      #|    http_only: true,
      #|    extensions: ["whatever=whatever"],
      #|  },
      #|)
    ),
  )
}

///|
test "cookie attribute boundaries and spelling" {
  guard Cookie::parse(
      "a=b; pAtH= ; \tDOMAIN= x=y \r; Secure=1; HttpOnlyX; ſecure; Path =x; Path; Max-Age=2; MAX-AGE=bad; SameSite=Lax",
    )
    is Some(cookie) else {
    fail("expected cookie")
  }
  @debug.debug_inspect(cookie.path, content="Some(\"\")")
  @debug.debug_inspect(cookie.domain, content="Some(\" x=y\")")
  @debug.debug_inspect(cookie.max_age, content="Some(2)")
  inspect(cookie.secure || cookie.http_only, content="false")
  @debug.debug_inspect(
    cookie.extensions,
    content=(
      #|["Secure=1", "HttpOnlyX", "ſecure", "Path =x", "Path", "SameSite=Lax"]
    ),
  )
}

///|
test "cookie scanner handles delimiters and source views" {
  let cases = [
    ("=", "", "", []),
    ("sid=a=b;", "sid", "a=b", []),
    ("sid=a;;", "sid", "a", ["", ""]),
    ("sid=a; Secure;;", "sid", "a", ["", ""]),
    (" 名 = 😀 ; Path=/图; x=y=z ", " 名 ", " 😀 ", ["x=y=z"]),
  ]
  for (line, name, value, extensions) in cases {
    let wrapped = "😀" + line + "😀"
    guard Cookie::parse(wrapped[2:2 + line.length()]) is Some(cookie) else {
      fail(line)
    }
    @test.assert_eq(cookie.name, name)
    @test.assert_eq(cookie.value, value)
    @test.assert_eq(cookie.extensions, extensions)
  }
  @debug.debug_inspect(Cookie::parse("without; flag=value"), content="None")
}

///|
test "parse cookie ignores what RFC 6265 ignores" {
  // No `=` in the name-value pair: the whole line is ignored.
  @debug.debug_inspect(Cookie::parse("Cookie"), content="None")
  @debug.debug_inspect(Cookie::parse("Cookie; Path=/"), content="None")
  // A `Max-Age` that is not `-?DIGIT+` is ignored, as RFC 6265 requires, and
  // so is one that does not fit in `Int64`.
  for max_age in ["xxx", "soon", "+60", "", "3600, c=d", "99999999999999999999"] {
    guard Cookie::parse("Cookie=value; Max-Age=\{max_age}") is Some(cookie) else {
      fail("cookie with Max-Age=\{max_age} was dropped")
    }
    @debug.debug_inspect(cookie.max_age, content="None")
  }
  guard Cookie::parse("Cookie=value; Max-Age=-1") is Some(cookie) else {
    fail("cookie with Max-Age=-1 was dropped")
  }
  @debug.debug_inspect(cookie.max_age, content="Some(-1)")
}
