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
test {
  struct Data {
    val : String
  } derive(Show)
  let data = Data::{ val: "Hello, 世界\t\n!" }
  // TODO: the data type annotation is not needed
  inspect(
    data,
    content=(
      #|{val: "Hello, 世界\t\n!"}
    ),
  )
  let v = "\u{00AD}Hello, \u{2060}世界\t\n!\u{1D173}"
  inspect(
    repr(v),
    content=(
      #|"­Hello, ⁠世界\t\n!𝅳"
    ),
  )
  // FIXME:The output is not ideal, we would prefer
  // to see the Unicode code points, e.g.
}
