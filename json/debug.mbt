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
pub impl @debug.Debug for Json with fn to_repr(self) {
  match self {
    Null => @debug.Repr::ctor("Null", [])
    True => @debug.Repr::ctor("True", [])
    False => @debug.Repr::ctor("False", [])
    Number(number, repr~) =>
      match repr {
        None => @debug.Repr::ctor("Number", [(None, Repr(number))])
        Some(_) =>
          @debug.Repr::ctor("Number", [
            (None, Repr(number)),
            (Some("repr"), Repr(repr)),
          ])
      }
    String(string) => @debug.Repr::ctor("String", [(None, Repr(string))])
    Array(array) => @debug.Repr::ctor("Array", [(None, Repr(array))])
    Object(object) => @debug.Repr::ctor("Object", [(None, Repr(object))])
  }
}
