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

pub trait Storable {
  op_set(Self, Int, Int) -> Unit // XXX: take Byte?
  store_int(Self, Int, Int, Endian) -> Unit
  store_int64(Self, Int, Int64, Endian) -> Unit
}

impl Storable::store_int(self : Self, index : Int, value : Int, endian : Endian) -> Unit {
  let bytes = 4
  let idx = match endian {
    Little => fn(i) { index + i }
    Big => {
      let start = index + bytes - 1
      fn(i) { start - i }
    }
  }
  for i = 0, v = value; i < bytes; {
    self[idx(i)] = v.land(0xff)
    continue i + 1, v.lsr(8)
  }
}

impl Storable::store_int64(
  self : Self,
  index : Int,
  value : Int64,
  endian : Endian
) -> Unit {
  let bytes = 8
  let idx = match endian {
    Little => fn(i) { index + i }
    Big => {
      let start = index + bytes - 1
      fn(i) { start - i }
    }
  }
  for i = 0, v = value; i < bytes; {
    self[idx(i)] = v.land(0xffL).to_int()
    continue i + 1, v.lsr(8)
  }
}
