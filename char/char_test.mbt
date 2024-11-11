// Copyright 2024 International Digital Economy Academy
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

test "to_string" {
  assert_eq!('a'.to_string(), "a")
}

test "show output" {
  fn repr(chr) {
    let buf = StringBuilder::new(size_hint=0)
    Show::output(chr, buf)
    buf.to_string()
  }

  assert_eq!(repr('a'), "'a'")
  assert_eq!(repr('\''), "'\\''")
  assert_eq!(repr('"'), "'\"'")
  assert_eq!(repr('\\'), "'\\\\'")
  assert_eq!(repr('\n'), "'\\n'")
  assert_eq!(repr('\r'), "'\\r'")
  assert_eq!(repr('\b'), "'\\b'")
  assert_eq!(repr('\t'), "'\\t'")
  assert_eq!(repr(Char::from_int(0)), "'\\x00'")
}

///|
struct TestHash {
  x : Char
} derive(Hash, Eq, Show)

test "Char hash function with struct" {
  let m = {}
  m[{ x: 'a' }] = '3'
  m[{ x: 'b' }] = '3'
  inspect!(m, content="{{x: 'a'}: '3', {x: 'b'}: '3'}")
}

test "Char hash" {
  let m = {}
  m['a'] = '3'
  m['b'] = '3'
  inspect!(m, content="{'a': '3', 'b': '3'}")
}
