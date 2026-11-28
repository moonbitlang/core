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
/// Create a unique, empty candidate. The containing directory belongs to Moon.
pub fn create(path : String) -> Unit raise {
  guard !path.contains("\u0000") else { fail("NUL in snapshot path") }
  let handle = open(path, write=true, exclusive=true).unwrap()
  handle.close()
}

///|
/// Compare regular files in bounded memory. -1 means equal, -2 means missing
/// baseline; otherwise the result is the first differing byte offset.
pub fn compare(actual : String, expected : String) -> Int64 raise {
  guard open(actual) is Some(a) else { fail("missing candidate: \{actual}") }
  defer a.close()
  guard open(expected) is Some(b) else { return -2 }
  defer b.close()
  let ab : FixedArray[Byte] = FixedArray::make(65536, 0)
  let bb : FixedArray[Byte] = FixedArray::make(65536, 0)
  for position = 0L {
    // Fill each chunk independently: short reads are not necessarily EOF.
    let an = for n = 0; n < ab.length(); {
      let count = a.read(ab, n, ab.length() - n, position + n.to_int64())
      if count == 0 {
        break n
      }
      continue n + count
    } nobreak {
      ab.length()
    }
    let bn = for n = 0; n < bb.length(); {
      let count = b.read(bb, n, bb.length() - n, position + n.to_int64())
      if count == 0 {
        break n
      }
      continue n + count
    } nobreak {
      bb.length()
    }
    let common = if an < bn { an } else { bn }
    for i = 0; i < common; i = i + 1 {
      if ab[i] != bb[i] {
        return position + i.to_int64()
      }
    }
    if an != bn {
      return position + common.to_int64()
    }
    if an == 0 {
      break -1
    }
    continue position + an.to_int64()
  }
}
