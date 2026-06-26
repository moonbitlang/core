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
fn make_int_array_json(count : Int) -> String {
  let buf = StringBuilder(size_hint=count * 7)
  buf.write_char('[')
  for i in 0..<count {
    if i > 0 {
      buf.write_char(',')
    }
    buf.write_string((i * 2654435).to_string())
  }
  buf.write_char(']')
  buf.to_string()
}

///|
fn make_float_array_json(count : Int) -> String {
  let buf = StringBuilder(size_hint=count * 12)
  buf.write_char('[')
  for i in 0..<count {
    if i > 0 {
      buf.write_char(',')
    }
    buf.write_string((i * 2654435).to_string())
    buf.write_string(".125e-2")
  }
  buf.write_char(']')
  buf.to_string()
}

///|
test "bench json parse int array n=10000" (it : @bench.T) {
  let input = make_int_array_json(10000)
  it.bench(fn() { it.keep(try! @json.parse(input)) })
}

///|
test "bench json parse float array n=10000" (it : @bench.T) {
  let input = make_float_array_json(10000)
  it.bench(fn() { it.keep(try! @json.parse(input)) })
}
