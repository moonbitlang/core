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

pub trait Loadable {
  op_get(Self, Int) -> Int // XXX: -> Byte?
  length(Self) -> Int
  load_int(Self, Int, Endian) -> Int
  load_int64(Self, Int, Endian) -> Int64
  // XXX: needs the capability to use labelled params in trait
  // https://github.com/moonbitlang/moonbit-docs/issues/190
  // op_as_view(Self, ~start: Int, ~end: Int) -> Loadable
}

impl Loadable::load_int(self : Self, index : Int, endian : Endian) -> Int {
  let bytes = 4
  let idx = match endian {
    Little => fn(i) { index + i }
    Big => {
      let start = index + bytes - 1
      fn(i) { start - i }
    }
  }
  for i = 0, rv = 0; i < bytes; {
    continue i + 1, rv.lor(self[idx(i)].lsl(8 * i))
  } else {
    rv
  }
}

impl Loadable::load_int64(self : Self, index : Int, endian : Endian) -> Int64 {
  let bytes = 8
  let idx = match endian {
    Little => fn(i) { index + i }
    Big => {
      let start = index + bytes - 1
      fn(i) { start - i }
    }
  }
  for i = 0, rv = 0L; i < bytes; {
    continue i + 1, rv.lor(self[idx(i)].to_int64().lsl(8 * i))
  } else {
    rv
  }
}
