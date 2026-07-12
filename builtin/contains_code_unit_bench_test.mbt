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

// Missing and late needles force a full scan; the offset view also exercises
// the backing-string range path used by `StringView::contains_code_unit`.

///|
test "bench contains_code_unit absent n=4" (it : @bench.T) {
  let s = String::make(4, 'a')
  it.bench(() => it.keep(s.contains_code_unit(('z' : UInt16))))
}

///|
test "bench contains_code_unit absent n=8" (it : @bench.T) {
  let s = String::make(8, 'a')
  it.bench(() => it.keep(s.contains_code_unit(('z' : UInt16))))
}

///|
test "bench contains_code_unit present@0 n=8" (it : @bench.T) {
  let s = String::make(8, 'a')
  it.bench(() => it.keep(s.contains_code_unit(('a' : UInt16))))
}

///|
test "bench contains_code_unit absent n=16" (it : @bench.T) {
  let s = String::make(16, 'a')
  it.bench(() => it.keep(s.contains_code_unit(('z' : UInt16))))
}

///|
test "bench contains_code_unit absent n=64" (it : @bench.T) {
  let s = String::make(64, 'a')
  it.bench(() => it.keep(s.contains_code_unit(('z' : UInt16))))
}

///|
test "bench contains_code_unit absent n=256" (it : @bench.T) {
  let s = String::make(256, 'a')
  it.bench(() => it.keep(s.contains_code_unit(('z' : UInt16))))
}

///|
test "bench contains_code_unit present@end n=256" (it : @bench.T) {
  let s = String::make(255, 'a') + "z"
  it.bench(() => it.keep(s.contains_code_unit(('z' : UInt16))))
}

///|
test "bench contains_code_unit present@0 n=256" (it : @bench.T) {
  let s = String::make(256, 'a')
  it.bench(() => it.keep(s.contains_code_unit(('a' : UInt16))))
}

///|
test "bench StringView contains_code_unit absent n=256" (it : @bench.T) {
  let s = "x" + String::make(256, 'a') + "y"
  let view = s[1:257]
  it.bench(() => it.keep(view.contains_code_unit(('z' : UInt16))))
}
