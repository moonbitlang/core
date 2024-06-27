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
  let b0 : Bucket[_] = Just_One(0)
  inspect((b0.find(0), b0.find(1), b0.size()), content="(true, false, 1)")?
  let b1 = b0.add(1)
  inspect((b1.find(0), b1.find(1), b1.size()), content="(true, true, 2)")?
  let b2 = b1.add(2)
  inspect((b2.find(0), b2.find(1), b2.size()), content="(true, true, 3)")?
  let b3 = b2.remove(0)
  {
    let b1 = b3.unwrap()
    inspect((b1.find(0), b1.find(1)), content="(false, true)")?
  }
  let b4 = b2.remove(1)
  let b1 = b4.unwrap() // b4 ? --> return Option instead of Result
  inspect((b1.find(0), b1.find(1)), content="(true, false)")?
}

test "Bucket::iter" {
  let b : Bucket[_] = More(0, More(1, Just_One(31)))
  let buf = Buffer::new(size_hint=0)
  let mut is_first = true
  b.each(
    fn(k) {
      if is_first {
        is_first = false
      } else {
        buf.write_string(", ")
      }
      buf.write_string("\(k)")
    },
  )
  inspect(buf.to_string(), content="0, 1, 31")?
}

test "Bucket::as_iter" {
  let b : Bucket[_] = More(0, More(1, Just_One(31)))
  let buf = Buffer::new(size_hint=0)
  let mut is_first = true
  b.as_iter().each(
    fn {
      k => {
        // weird syntax conventions that
        // braces needed here
        if is_first {
          is_first = false
        } else {
          buf.write_string(", ")
        }
        buf.write_string("\(k)")
      }
    },
  )
  inspect(buf.to_string(), content="0, 1, 31")?
}

test "Bucket add and remove" {
  let b0 : Bucket[_] = Just_One(0)
  let b1 = b0.add(1)
  let b2 = b1.add(2)
  let b3 = b2.remove(0).unwrap()
  let b4 = b2.remove(1).unwrap()
  let b5 = b2.remove(2).unwrap()
  @assertion.assert_eq(b0.find(0), true)?
  @assertion.assert_eq(b0.find(1), false)?
  @assertion.assert_eq(b1.find(0), true)?
  @assertion.assert_eq(b1.find(1), true)?
  @assertion.assert_eq(b2.find(0), true)?
  @assertion.assert_eq(b2.find(1), true)?
  @assertion.assert_eq(b2.find(2), true)?
  @assertion.assert_eq(b3.find(0), false)?
  @assertion.assert_eq(b3.find(1), true)?
  @assertion.assert_eq(b3.find(2), true)?
  @assertion.assert_eq(b4.find(0), true)?
  @assertion.assert_eq(b4.find(1), false)?
  @assertion.assert_eq(b4.find(2), true)?
  @assertion.assert_eq(b5.find(0), true)?
  @assertion.assert_eq(b5.find(1), true)?
  @assertion.assert_eq(b5.find(2), false)?
}

test "Bucket size" {
  let b0 : Bucket[_] = Just_One(0)
  let b1 = b0.add(1)
  let b2 = b1.add(2)
  let b3 = b2.remove(0).unwrap()
  let b4 = b2.remove(1).unwrap()
  let b5 = b2.remove(2).unwrap()
  @assertion.assert_eq(b0.size(), 1)?
  @assertion.assert_eq(b1.size(), 2)?
  @assertion.assert_eq(b2.size(), 3)?
  @assertion.assert_eq(b3.size(), 2)?
  @assertion.assert_eq(b4.size(), 2)?
  @assertion.assert_eq(b5.size(), 2)?
}

test "Bucket iter" {
  let b0 : Bucket[_] = Just_One(0)
  let b1 = b0.add(1)
  let b2 = b1.add(2)
  let buf = Buffer::new(size_hint=0)
  let mut is_first = true
  b2.each(
    fn(k) {
      if is_first {
        is_first = false
      } else {
        buf.write_string(", ")
      }
      buf.write_string("\(k)")
    },
  )
  inspect(buf, content="1, 2, 0")?
}

test "Bucket as_iter" {
  let b0 : Bucket[_] = Just_One(0)
  let b1 = b0.add(1)
  let b2 = b1.add(2)
  let buf = Buffer::new(size_hint=0)
  let mut is_first = true
  b2.as_iter().each(
    fn {
      k => {
        if is_first {
          is_first = false
        } else {
          buf.write_string(", ")
        }
        buf.write_string("\(k)")
      }
    },
  )
  inspect(buf, content="1, 2, 0")?
}
