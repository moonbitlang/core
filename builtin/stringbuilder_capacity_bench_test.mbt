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
test "bench StringBuilder default empty" (it : @bench.T) {
  it.bench(() => it.keep(StringBuilder()))
}

///|
test "bench StringBuilder default 8 ASCII chars" (it : @bench.T) {
  it.bench(() => {
    let builder = StringBuilder()
    for _ in 0..<8 {
      builder.write_char('x')
    }
    it.keep(builder.to_string())
  })
}

///|
test "bench StringBuilder default 4 non-BMP chars" (it : @bench.T) {
  it.bench(() => {
    let builder = StringBuilder()
    for _ in 0..<4 {
      builder.write_char('😀')
    }
    it.keep(builder.to_string())
  })
}

///|
test "bench StringBuilder default single 7-unit string" (it : @bench.T) {
  it.bench(() => {
    let builder = StringBuilder()
    builder.write_string("abcdefg")
    it.keep(builder.to_string())
  })
}

///|
test "bench StringBuilder default single 64k-unit string" (it : @bench.T) {
  let input = "abcdefgh".repeat(8192)
  it.bench(() => {
    let builder = StringBuilder()
    builder.write_string(input)
    it.keep(builder.to_string())
  })
}

///|
test "bench StringBuilder explicit zero 8 ASCII chars" (it : @bench.T) {
  it.bench(() => {
    let builder = StringBuilder(size_hint=0)
    for _ in 0..<8 {
      builder.write_char('x')
    }
    it.keep(builder.to_string())
  })
}

///|
test "bench StringBuilder join 64 strings" (it : @bench.T) {
  let input = FixedArray::make(64, "abcdefg")
  it.bench(() => it.keep(input.join(",")))
}

///|
test "bench StringBuilder default single ASCII char" (it : @bench.T) {
  it.bench(() => {
    let builder = StringBuilder()
    builder.write_char('x')
    it.keep(builder.to_string())
  })
}
