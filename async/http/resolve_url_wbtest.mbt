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
test "resolve_url" {
  fn to_owned(result : (_, _, StringView)) {
    let (a, b, c) = result
    (a, b, c.to_owned())
  }
  @debug.debug_inspect(
    to_owned(resolve_url("http://www.example.org")),
    content=(
      #|(Http, "www.example.org", "/")
    ),
  )
  @debug.debug_inspect(
    to_owned(resolve_url("http://www.example.org/path/to")),
    content=(
      #|(Http, "www.example.org", "/path/to")
    ),
  )
  @debug.debug_inspect(
    to_owned(resolve_url("https://www.example.org/path/to?search=q")),
    content=(
      #|(Https, "www.example.org", "/path/to?search=q")
    ),
  )
  @debug.debug_inspect(
    @test.expect_error(() => to_owned(resolve_url("ftp://www.example.org"))),
    content=(
      #|UnsupportedProtocol("ftp")
    ),
  )
  @debug.debug_inspect(
    to_owned(resolve_url("http://www.example.org:10042")),
    content=(
      #|(Http, "www.example.org:10042", "/")
    ),
  )
  @debug.debug_inspect(
    to_owned(resolve_url("http://www.example.org:10042/path")),
    content=(
      #|(Http, "www.example.org:10042", "/path")
    ),
  )
}

///|
test "resolve_host" {
  fn to_owned(result : (StringView, _)) {
    let (a, b) = result
    (a.to_owned(), b)
  }

  @debug.debug_inspect(
    to_owned(resolve_host("www.example.org", protocol=Http)),
    content=(
      #|("www.example.org", 80)
    ),
  )
  @debug.debug_inspect(
    to_owned(resolve_host("www.example.org", protocol=Https)),
    content=(
      #|("www.example.org", 443)
    ),
  )
  @debug.debug_inspect(
    to_owned(resolve_host("www.example.org:42", protocol=Http)),
    content=(
      #|("www.example.org", 42)
    ),
  )
  @debug.debug_inspect(
    to_owned(resolve_host("www.example.org:42", protocol=Https)),
    content=(
      #|("www.example.org", 42)
    ),
  )
  @debug.debug_inspect(
    @test.expect_error(() => {
      to_owned(resolve_host("www.example.org:0", protocol=Https))
    }),
    content=(
      #|InvalidFormat
    ),
  )
  @debug.debug_inspect(
    @test.expect_error(() => {
      to_owned(resolve_host("www.example.org:100042", protocol=Https))
    }),
    content=(
      #|InvalidFormat
    ),
  )
}
