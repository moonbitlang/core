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

///-----------------------------------------------------------------------------
test "to_string" {
  assert_eq!('a'.to_string(), "a")
}

///-----------------------------------------------------------------------------
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

///-----------------------------------------------------------------------------
pub impl Hash for Char with hash(self) { self.to_int() }

///-----------------------------------------------------------------------------
pub impl Hash for Char with hash_combine(self, hasher) -> Unit {
  hasher.combine_char(self)
}
