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

test "empty" {
  let iter = Iter::empty()
  let exb = Buffer::make(0)
  iter.iter(fn {
    x => exb.write_char(x)
  })
  exb.expect()?
}

test "singleton" {
  let iter = Iter::singleton('1')
  let exb = Buffer::make(0)
  iter.iter(fn {
    x => exb.write_char(x)
  })
  exb.expect(~content="1")?
}

test "repeat" {
  let iter = Iter::repeat('1')
  let exb = Buffer::make(0)
  iter.take(3).iter(fn {
    x => exb.write_char(x)
  })
  exb.expect(~content="111")?
}

test "count" {
  let iter = from_array(['1', '2', '3', '4', '5'])
  @assertion.assert_eq(iter.count(), 5)?
}

test "take" {
  let iter = from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::make(0)
  iter.take(3).iter(fn {
    x => exb.write_char(x)
  })
  exb.expect(~content="123")?
}

test "take_while" {
  let iter = from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::make(0)
  iter.take_while(fn { x => x != '4' }).iter(fn {
    x => exb.write_char(x)
  })
  exb.expect(~content="123")?
}

test "drop" {
  let iter = from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::make(0)
  iter.drop(3).iter(fn {
    x => exb.write_char(x)
  })
  exb.expect(~content="45")?
}

test "drop_while" {
  let iter = from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::make(0)
  iter.drop_while(fn { x => x != '4' }).iter(fn {
    x => exb.write_char(x)
  })
  exb.expect(~content="45")?
}

test "filter" {
  let iter = from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::make(0)
  iter.filter(fn { x => x != '4' }).iter(fn {
    x => exb.write_char(x)
  })
  exb.expect(~content="1235")?
}

test "map" {
  let iter = from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::make(0)
  iter.map(fn { x => Char::from_int(x.to_int() + 1) }).iter(fn {
    x => exb.write_char(x)
  })
  exb.expect(~content="23456")?
}

test "flat_map" {
  let iter = from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::make(0)
  iter.flat_map(fn { x => Iter::repeat(x).take(2) }).iter(fn {
    x => exb.write_char(x)
  })
  exb.expect(~content="1122334455")?
}

test "fold" {
  let iter = from_array(['1', '2', '3', '4', '5'])
  let result = Char::from_int(iter.fold(fn { acc, x => acc + x.to_int() }, 0) / 5)
  @assertion.assert_eq(result, '3')?
}

test "find_first" {
  let iter = from_array(['1', '2', '3', '4', '5'])
  let result = iter.find_first(fn { x => x > '3' })
  @assertion.assert_eq(result, Some('4'))?
  let result2 = iter.find_first(fn { x => x > '5' })
  @assertion.assert_eq(result2, None)?
}

test "tap" {
  let iter = from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::make(0)
  iter.tap(fn { x => exb.write_char(x) }).iter(fn {
    x => exb.write_char(x)
  })
  exb.expect(~content="1234512345")?
}

// For testing purposes
fn from_array[T](arr: Array[T]) -> Iter[T] {
  Iter::_unstable_internal_make(fn {
    yield => {
      for i = 0; i < arr.length(); i = i + 1 {
        if yield(arr[i]).not() {
          break
        }
      }
    }
  })
}
