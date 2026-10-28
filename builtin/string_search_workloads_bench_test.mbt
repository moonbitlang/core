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

// End-to-end split workloads and search dispatch boundaries. Keep fixture
// construction outside timed closures; the split checksum consumes both
// returned views. Long inputs deliberately include a late hit and a miss.
// Run with `moon bench builtin/string_search_workloads_bench_test.mbt --target js`.

///|
let string_search_short_headers : Array[String] = [
  "Content-Type: text/html",
  "host: example.com:8080",
  "key: value",
  "no separator here at all",
  "x: y",
  "Accept-Encoding: gzip, deflate, br",
  "a:b",
  "GET / HTTP/1.1\r\nHost: a\r\n\r\nbody",
  "plain",
  "name: " + String::make(40, 'v'),
]

///|
let string_search_long_headers : Array[String] = [
  String::make(2000, 'x') + ": tail\r\n\r\n",
  String::make(1500, 'y'),
]

///|
fn string_search_split_checksum(inputs : Array[String], sep : String) -> Int32 {
  let mut r = 0
  for s in inputs {
    match s.split_once(sep) {
      Some((b, a)) => r += b.length() * 3 + a.length()
      None => r -= 1
    }
  }
  r
}

///|
test "bench split_once short ':'" (it : @bench.T) {
  it.bench(() => {
    it.keep(string_search_split_checksum(string_search_short_headers, ":"))
  })
}

///|
test "bench split_once short ': '" (it : @bench.T) {
  it.bench(() => {
    it.keep(string_search_split_checksum(string_search_short_headers, ": "))
  })
}

///|
test "bench split_once short crlfcrlf" (it : @bench.T) {
  it.bench(() => {
    it.keep(
      string_search_split_checksum(string_search_short_headers, "\r\n\r\n"),
    )
  })
}

///|
test "bench split_once long ':'" (it : @bench.T) {
  it.bench(() => {
    it.keep(string_search_split_checksum(string_search_long_headers, ":"))
  })
}

///|
test "bench split_once long ': '" (it : @bench.T) {
  it.bench(() => {
    it.keep(string_search_split_checksum(string_search_long_headers, ": "))
  })
}

///|
test "bench split_once long crlfcrlf" (it : @bench.T) {
  it.bench(() => {
    it.keep(
      string_search_split_checksum(string_search_long_headers, "\r\n\r\n"),
    )
  })
}

///|
test "bench find header terminator in builder text" (it : @bench.T) {
  let sb = StringBuilder()
  for i in 0..<40 {
    sb.write_string("header-\{i}: value \{i}\r\n")
  }
  sb.write_string("\r\nbody")
  let str = sb.to_string()
  it.bench(() => it.keep(str.find("\r\n\r\n")))
}

///|
test "bench bounded find z 32 in 1MiB" (it : @bench.T) {
  let text = "x" + String::make(1048576, 'a') + "z"
  let view = text[1:33]
  it.bench(() => it.keep(view.find("z")))
}

///|
test "bench bounded rev_find z 32 in 1MiB" (it : @bench.T) {
  let text = "x" + String::make(1048576, 'a') + "z"
  let view = text[1:33]
  it.bench(() => it.keep(view.rev_find("z")))
}

///|
test "bench bounded find zz 32 in 1MiB" (it : @bench.T) {
  let text = "x" + String::make(1048576, 'a') + "z"
  let view = text[1:33]
  it.bench(() => it.keep(view.find("zz")))
}

///|
test "bench find hit start n=256" (it : @bench.T) {
  let text = String::make(256, 'a')
  it.bench(() => it.keep(text.find("a")))
}

///|
test "bench reverse hit end n=256" (it : @bench.T) {
  let text = String::make(256, 'a')
  it.bench(() => it.keep(text.rev_find("a")))
}

///|
test "bench dense aZ n=65536" (it : @bench.T) {
  let text = String::make(65536, 'a')
  it.bench(() => it.keep(text.find("aZ")))
}

///|
test "bench unicode find miss n=256" (it : @bench.T) {
  let text = String::make(256, '中')
  it.bench(() => it.keep(text.find("文")))
}

///|
test "bench threshold m249 n=65536" (it : @bench.T) {
  let text = String::make(65536, 'a')
  let pattern = String::make(124, 'a') + "Z" + String::make(124, 'a')
  it.bench(() => it.keep(text.find(pattern)))
}

///|
test "bench threshold m250 n=65536" (it : @bench.T) {
  let text = String::make(65536, 'a')
  let pattern = String::make(125, 'a') + "Z" + String::make(124, 'a')
  it.bench(() => it.keep(text.find(pattern)))
}

///|
test "bench threshold m251 n=65536" (it : @bench.T) {
  let text = String::make(65536, 'a')
  let pattern = String::make(125, 'a') + "Z" + String::make(125, 'a')
  it.bench(() => it.keep(text.find(pattern)))
}
