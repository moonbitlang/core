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
test "bench UTF-16 StringBuilder write string 1M units" (it : @bench.T) {
  let input = "abcdefgh".repeat(131072)
  it.bench(() => {
    let builder = StringBuilder(size_hint=input.length() * 2)
    builder.write_string(input)
    it.keep(builder.to_string())
  })
}

///|
test "bench UTF-16 StringBuilder write view offset 1M units" (it : @bench.T) {
  let input = "prefix!" + "abcdefgh".repeat(131072) + "suffix!"
  let view = input[7:7 + 1048576]
  it.bench(() => {
    let builder = StringBuilder(size_hint=view.length() * 2)
    builder.write_view(view)
    it.keep(builder.to_string())
  })
}

///|
test "bench UTF-16 StringBuilder write chunks 4096x32" (it : @bench.T) {
  let input = "abcdefgh".repeat(4)
  it.bench(() => {
    let builder = StringBuilder(size_hint=4096 * input.length() * 2)
    for _ in 0..<4096 {
      builder.write_string(input)
    }
    it.keep(builder.to_string())
  })
}

///|
test "bench UTF-16 StringBuilder short write 7 units" (it : @bench.T) {
  it.bench(() => {
    let builder = StringBuilder(size_hint=14)
    builder.write_string("abcdefg")
    it.keep(builder.to_string())
  })
}

///|
test "bench UTF-16 StringBuilder block write 8 units" (it : @bench.T) {
  it.bench(() => {
    let builder = StringBuilder(size_hint=16)
    builder.write_string("abcdefgh")
    it.keep(builder.to_string())
  })
}

///|
test "bench UTF-16 StringBuilder write char control 4096" (it : @bench.T) {
  it.bench(() => {
    let builder = StringBuilder(size_hint=8192)
    for _ in 0..<4096 {
      builder.write_char('x')
    }
    it.keep(builder.to_string())
  })
}

///|
test "bench UTF-16 JSON stringify plain string 128k units" (it : @bench.T) {
  let value = @json.to_json("plain-json-text-".repeat(8192))
  it.bench(() => it.keep(value.stringify()))
}

///|
test "bench UTF-16 JSON stringify 1000 strings 128 units" (it : @bench.T) {
  let text = "plain-json-text-".repeat(8)
  let value = @json.to_json(Array::makei(1000, i => text + i.to_string()))
  it.bench(() => it.keep(value.stringify()))
}

///|
test "bench UTF-16 JSON stringify 64 prose strings with newline" (it : @bench.T) {
  let text = "The quick brown fox jumps over the lazy dog. ".repeat(45)
  let value = @json.to_json(Array::makei(64, i => "\{i}\n" + text))
  it.bench(() => it.keep(value.stringify()))
}
