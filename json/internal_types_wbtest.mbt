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
test "CharClass::contains/simple_case" {
  let char_class = CharClass::of([('a', 'z')])
  inspect!(char_class.contains('a'), content=true)
  inspect!(char_class.contains('m'), content=true)
  inspect!(char_class.contains('z'), content=true)
  inspect!(char_class.contains('A'), content=false)
}

///|
test "CharClass::contains/multiple_ranges" {
  let char_class = CharClass::of([('a', 'f'), ('m', 'r'), ('x', 'z')])
  inspect!(char_class.contains('a'), content=true)
  inspect!(char_class.contains('p'), content=true)
  inspect!(char_class.contains('y'), content=true)
  inspect!(char_class.contains('g'), content=false)
  inspect!(char_class.contains('w'), content=false)
}

///|
test "CharClass::contains/boundary_case" {
  let char_class = CharClass::of([('a', 'c'), ('e', 'h')])
  inspect!(char_class.contains('a'), content=true)
  inspect!(char_class.contains('c'), content=true)
  inspect!(char_class.contains('e'), content=true)
  inspect!(char_class.contains('h'), content=true)
  inspect!(char_class.contains('d'), content=false)
}
