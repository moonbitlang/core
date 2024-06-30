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

test "Bucket" {
  let b0 : Bucket[_] = Just_One(0, 0)
  inspect((b0.find(0), b0.find(1), b0.size()), content="(Some(0), None, 1)")?
  let b1 = b0.add(1, 1)
  inspect((b1.find(0), b1.find(1), b1.size()), content="(Some(0), Some(1), 2)")?
  let b2 = b1.add(0, 2)
  inspect((b2.find(0), b2.find(1), b2.size()), content="(Some(2), Some(1), 2)")?
  let b3 = b2.remove(0)
  {
    let b1 = b3.unwrap()
    inspect((b1.find(0), b1.find(1)), content="(None, Some(1))")?
  }
  let b4 = b2.remove(1)
  let b1 = b4.unwrap() // b4 ? --> return Option instead of Result
  inspect((b1.find(0), b1.find(1)), content="(Some(2), None)")?
}

test "Bucket::iter" {
  let b : Bucket[_] = More(0, 0, More(1, 1, Just_One(31, 31)))
  let buf = Buffer::new(size_hint=0)
  let mut is_first = true
  b.each(
    fn(k, v) {
      if is_first {
        is_first = false
      } else {
        buf.write_string(", ")
      }
      buf.write_string("\(k) => \(v)")
    },
  )
  inspect(buf.to_string(), content="0 => 0, 1 => 1, 31 => 31")?
}

test "Bucket::iter" {
  let b : Bucket[_] = More(0, 0, More(1, 1, Just_One(31, 31)))
  let buf = Buffer::new(size_hint=0)
  let mut is_first = true
  b.iter().each(
    fn {
      (k, v) => {
        // weird syntax conventions that
        // braces needed here
        if is_first {
          is_first = false
        } else {
          buf.write_string(", ")
        }
        buf.write_string("\(k) => \(v)")
      }
    },
  )
  inspect(buf.to_string(), content="0 => 0, 1 => 1, 31 => 31")?
}
