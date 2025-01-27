// Copyright 2025 International Digital Economy Academy
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
priv struct ParseContext {
  mut view : @string.StringView
  mut line : Int
  mut column : Int
}

///|
priv struct Builder {
  start_pos : Position
  builder : StringBuilder
}

///|
fn Builder::new(start_pos : Position) -> Builder {
  { start_pos, builder: StringBuilder::new() }
}

///|
fn ParseContext::make(input : String) -> ParseContext {
  { view: input[:], line: 1, column: 0 }
}

///|
priv type CharClass Array[(Char, Char)]

///|
fn CharClass::of(array : Array[(Char, Char)]) -> CharClass {
  CharClass(array)
}

///|
fn CharClass::from_array(array : Array[(Char, Char)]) -> CharClass {
  CharClass(array)
}

///|
fn contains(self : CharClass, c : Char) -> Bool {
  for left = 0, right = self._.length(); left < right; {
    let middle = (left + right) / 2
    let (min, max) = self._[middle]
    if c < min {
      continue left, middle
    } else if c > max {
      continue middle + 1, right
    } else {
      break true
    }
  } else {
    false
  }
}

///|
priv enum Token {
  Null
  True
  False
  Number(Double)
  String(String)
  LBrace
  RBrace
  LBracket
  RBracket
  Comma
  Colon
} derive(Eq, Show)
