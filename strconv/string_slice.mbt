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

/// A slice of a string.
/// TODO: make it a monad
priv struct StringSlice {
  string: String
  start: Int
  end: Int
}

fn slice(s: String, start: Int, end: Int) -> StringSlice {
  {
    string: s,
    start: start,
    end: end
  }
}

fn full_slice(s: String) -> StringSlice {
  {
    string: s,
    start: 0,
    end: s.length()
  }
}

fn subfix(self: StringSlice, start: Int) -> StringSlice {
  {
    string: self.string,
    start: self.start + start,
    end: self.end
  }
}

fn prefix(self: StringSlice, end: Int) -> StringSlice {
  {
    string: self.string,
    start: self.start,
    end: self.start + end
  }
}

fn subslice(self: StringSlice, start: Int, end: Int) -> StringSlice {
  {
    string: self.string,
    start: self.start + start,
    end: self.start + end
  }
}

fn step(self: StringSlice, step: Int) -> StringSlice {
  {
    string: self.string,
    start: self.start + step,
    end: self.end
  }
}

/// Unsafe: make sure index is in bounds
fn op_get(self: StringSlice, index: Int) -> Char {
  self.string[self.start+index]
}

fn length(self: StringSlice) -> Int {
  self.end - self.start
}

fn is_empty(self: StringSlice) -> Bool {
  self.start == self.end
}

fn to_string(self: StringSlice) -> String {
  let buf = Buffer::make(self.length())
  for i = 0; i < self.length(); i = i + 1 {
    buf.write_char(self[i])
  }
  buf.to_string()
}

fn eq_ignore_case(self : StringSlice, s2 : String) -> Bool {
  if self.length() != s2.length() {
    return false
  }
  for i = 0; i < self.length(); i = i + 1 {
    let c1 = self[i]
    let c2 = s2[i]
    if lower(c1) != lower(c2) {
      return false
    }
  }
  true
}

fn lower(c : Char) -> Char {
  if 'A' <= c && c <= 'Z' {
    Char::from_int(c.to_int() + 'a'.to_int() - 'A'.to_int())
  } else {
    c
  }
}
