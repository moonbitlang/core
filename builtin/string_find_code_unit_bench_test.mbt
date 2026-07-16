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
test "bench find one code unit absent n=4" (it : @bench.T) {
  let str = String::make(4, 'a')
  it.bench(() => it.keep(str.find("z")))
}

///|
test "bench find one code unit absent n=8" (it : @bench.T) {
  let str = String::make(8, 'a')
  it.bench(() => it.keep(str.find("z")))
}

///|
test "bench find one code unit present@0 n=8" (it : @bench.T) {
  let str = String::make(8, 'a')
  it.bench(() => it.keep(str.find("a")))
}

///|
test "bench find one code unit absent n=64" (it : @bench.T) {
  let str = String::make(64, 'a')
  it.bench(() => it.keep(str.find("z")))
}

///|
test "bench find one code unit absent n=256" (it : @bench.T) {
  let str = String::make(256, 'a')
  it.bench(() => it.keep(str.find("z")))
}

///|
test "bench find one code unit present@end n=256" (it : @bench.T) {
  let str = String::make(255, 'a') + "z"
  it.bench(() => it.keep(str.find("z")))
}

///|
test "bench rev_find one code unit absent n=256" (it : @bench.T) {
  let str = String::make(256, 'a')
  it.bench(() => it.keep(str.rev_find("z")))
}

///|
test "bench rev_find one code unit present@start n=256" (it : @bench.T) {
  let str = "z" + String::make(255, 'a')
  it.bench(() => it.keep(str.rev_find("z")))
}

///|
test "bench rev_find one code unit present@end n=8" (it : @bench.T) {
  let str = String::make(7, 'a') + "z"
  it.bench(() => it.keep(str.rev_find("z")))
}

///|
test "bench StringView find one code unit absent n=256" (it : @bench.T) {
  let str = "x" + String::make(256, 'a') + "y"
  let view = str[1:257]
  it.bench(() => it.keep(view.find("z")))
}

///|
test "bench StringView rev_find one code unit absent n=256" (it : @bench.T) {
  let str = "x" + String::make(256, 'a') + "y"
  let view = str[1:257]
  it.bench(() => it.keep(view.rev_find("z")))
}
