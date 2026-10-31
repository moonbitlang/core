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
pub impl Debug for @json.Json with fn to_repr(self) {
  match self {
    Null => Repr::ctor("Null", [])
    True => Repr::ctor("True", [])
    False => Repr::ctor("False", [])
    Number(number, repr~) =>
      match repr {
        None => Repr::ctor("Number", [(None, Repr(number))])
        Some(_) =>
          Repr::ctor("Number", [
            (None, Repr(number)),
            (Some("repr"), Repr(repr)),
          ])
      }
    String(string) => Repr::ctor("String", [(None, Repr(string))])
    Array(array) => Repr::ctor("Array", [(None, Repr(array))])
    Object(object) => Repr::ctor("Object", [(None, Repr(object))])
  }
}

///|
pub impl Debug for @json.Position with fn to_repr(self) {
  Repr::record({ "line": Repr(self.line), "column": Repr(self.column) })
}

///|
pub impl Debug for @json.ParseError with fn to_repr(self) {
  match self {
    InvalidChar(position, char) =>
      Repr::ctor("InvalidChar", [(None, Repr(position)), (None, Repr(char))])
    InvalidEof => Repr::ctor("InvalidEof", [])
    InvalidNumber(position, number) =>
      Repr::ctor("InvalidNumber", [(None, Repr(position)), (None, Repr(number))])
    InvalidIdentEscape(position) =>
      Repr::ctor("InvalidIdentEscape", [(None, Repr(position))])
    DuplicateKey(position, key) =>
      Repr::ctor("DuplicateKey", [(None, Repr(position)), (None, Repr(key))])
    DepthLimitExceeded => Repr::ctor("DepthLimitExceeded", [])
  }
}

///|
pub impl Debug for @json.JsonPath with fn to_repr(self) {
  // JsonPath's mutable nodes are private to the decoder. Its public JSON
  // Pointer representation gives debugging a stable view of the path.
  Repr::opaque_("JsonPath", Repr(self.to_string()))
}

///|
pub impl Debug for @json.JsonDecodeError with fn to_repr(self) {
  let JsonDecodeError(contents) = self
  Repr::ctor("JsonDecodeError", [(None, Repr(contents))])
}

///|
pub impl Debug for @json.Replacer with fn to_repr(_self) {
  Repr::record({ "f": Repr::opaque_("function", Repr::omitted()) })
}
