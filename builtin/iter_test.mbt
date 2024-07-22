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
  let exb = Buffer::new(size_hint=0)
  iter.each(fn { x => exb.write_char(x) })
  exb.expect!()
}

test "singleton" {
  let iter = Iter::singleton('1')
  let exb = Buffer::new(size_hint=0)
  iter.each(fn { x => exb.write_char(x) })
  exb.expect!(content="1")
}

test "repeat" {
  let iter = Iter::repeat('1')
  let exb = Buffer::new(size_hint=0)
  iter.take(3).each(fn { x => exb.write_char(x) })
  exb.expect!(content="111")
}

test "count" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  @test.eq!(iter.count(), 5)
}

test "take" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::new(size_hint=0)
  iter.take(3).each(fn { x => exb.write_char(x) })
  exb.expect!(content="123")
}

test "take2" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::new(size_hint=0)
  iter.take(10).concat(Iter::repeat('6').take(1)).each(
    fn { x => exb.write_char(x) },
  )
  exb.expect!(content="123456")
}

test "take_while" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::new(size_hint=0)
  iter.take_while(fn { x => x != '4' }).each(fn { x => exb.write_char(x) })
  exb.expect!(content="123")
}

test "take_while2" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::new(size_hint=0)
  iter.take_while(fn { x => x != '4' }).concat(singleton('6')).each(
    fn { x => exb.write_char(x) },
  )
  exb.expect!(content="1236")
}

test "take_while3" {
  let iter = test_from_array([1, 2, 3])
  let res = iter.take_while(fn { x => x != 4 }).concat(singleton(4)).find_first(
    fn { x => x % 2 == 0 },
  )
  inspect!(res, content="Some(2)")
}

test "take_while4" {
  let iter = test_from_array([1, 2, 3, 4, 5, 6])
  let res = iter.take_while(fn { x => x <= 5 }).take(4).fold(
    init=0,
    fn(x, y) { x + y },
  )
  inspect!(res, content="10")
}

test "take_while5" {
  let iter = test_from_array([1, 2, 3, 4, 5, 6])
  let res = iter.take(4).take_while(fn { x => x >= 5 }).fold(
    fn(x, y) { x + y },
    init=0,
  )
  inspect!(res, content="0")
}

test "drop" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::new(size_hint=0)
  iter.drop(3).each(fn { x => exb.write_char(x) })
  exb.expect!(content="45")
}

test "drop_while" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::new(size_hint=0)
  iter.drop_while(fn { x => x != '4' }).each(fn { x => exb.write_char(x) })
  exb.expect!(content="45")
}

test "drop_while2" {
  let iter = test_from_array([1, 2, 3, 4, 5])
  let res = iter.drop_while(fn { x => x <= 3 }).concat(singleton(6)).find_first(
    fn { x => x % 3 == 0 },
  )
  inspect!(res, content="Some(6)")
}

test "drop_while3" {
  let iter = test_from_array([1, 2, 3, 4, 5])
  let exb = Buffer::new(size_hint=0)
  let res = iter.drop_while(fn { x => x < 3 }).concat(singleton(6)).find_first(
    fn {
      x => {
        exb.write_char('x')
        x % 3 == 0
      }
    },
  )
  // make sure the predicate in find_first is called only once
  exb.expect!(content="x")
  inspect!(res, content="Some(3)")
}

test "drop_while4" {
  let iter = test_from_array([1, 2, 3, 4, 5])
  let res = iter.drop_while(fn { x => x <= 3 }).concat(singleton(6)).drop(3).find_first(
    fn { x => x % 3 == 0 },
  )
  inspect!(res, content="None")
}

test "filter" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::new(size_hint=0)
  iter.filter(fn { x => x != '4' }).each(fn { x => exb.write_char(x) })
  exb.expect!(content="1235")
}

test "map" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::new(size_hint=0)
  iter.map(fn { x => Char::from_int(x.to_int() + 1) }).each(
    fn { x => exb.write_char(x) },
  )
  exb.expect!(content="23456")
}

test "flat_map" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::new(size_hint=0)
  iter.flat_map(fn { x => Iter::repeat(x).take(2) }).each(
    fn { x => exb.write_char(x) },
  )
  exb.expect!(content="1122334455")
}

test "flat_map2" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::new(size_hint=0)
  iter.flat_map(fn { x => Iter::singleton(x) }).each(
    fn { x => exb.write_char(x) },
  )
  exb.expect!(content="12345")
}

test "fold" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let result = Char::from_int(
    iter.fold(fn { acc, x => acc + x.to_int() }, init=0) / 5,
  )
  @test.eq!(result, '3')
}

test "find_first" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let result = iter.find_first(fn { x => x > '3' })
  @test.eq!(result, Some('4'))
  let result2 = iter.find_first(fn { x => x > '5' })
  @test.eq!(result2, None)
}

test "find_first2" {
  let iter = test_from_array([1, 2, 3]).concat(test_from_array([4, 5, 6]))
  let result = iter.find_first(fn { x => x % 2 == 0 })
  inspect!(result, content="Some(2)")
}

test "tap" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::new(size_hint=0)
  iter.tap(fn { x => exb.write_char(x) }).each(fn { x => exb.write_char(x) })
  exb.expect!(content="1234512345")
}

test "prepend" {
  let iter = test_from_array(['0', '1', '2', '3', '4', '5'])
  let exb = Buffer::new(size_hint=0)
  iter.prepend('X').each(fn { x => exb.write_char(x) })
  exb.expect!(content="X012345")
}

test "append" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::new(size_hint=0)
  iter.append('6').each(fn { x => exb.write_char(x) })
  exb.expect!(content="123456")
}

test "concat" {
  let iter1 = test_from_array(['1', '2', '3'])
  let iter2 = test_from_array(['4', '5', '6'])
  let combined_iter = Iter::concat(iter1, iter2)
  let exb = Buffer::new(size_hint=0)
  combined_iter.each(fn { x => exb.write_char(x) })
  exb.expect!(content="123456")
}

test "collect" {
  let arr = ['1', '2', '3', '4', '5']
  let iter = Iter::new(
    fn(yield) {
      for i = 0, len = arr.length(); i < len; i = i + 1 {
        yield(arr[i]) |> ignore
      }
      IterContinue
    },
  )
  let vec = iter.collect()
  @test.eq!(vec, ['1', '2', '3', '4', '5'])
}

test "range" {
  // edge cases
  inspect!((0).until(10).take(100), content="[0, 1, 2, 3, 4, 5, 6, 7, 8, 9]")
  inspect!((100).until(10).take(100), content="[]")
  inspect!((100).until(101, step=4), content="[100]")
  inspect!((1).until(2, step=0), content="[]")
  inspect!(1.0.until(2.0, step=0), content="[]")
  inspect!(0L.until(10, step=0), content="[]")
  // until
  inspect!(
    (0).until(10).take(5).concat((0).until(2)),
    content="[0, 1, 2, 3, 4, 0, 1]",
  )
  inspect!(
    0x80000000L.until(0x80000000L + 10L).take(5).concat(
      (0x80000000L + 10L).until(0x80000000L + 20L).take(3),
    ),
    content="[2147483648, 2147483649, 2147483650, 2147483651, 2147483652, 2147483658, 2147483659, 2147483660]",
  )
  inspect!(
    0.0.until(10.0).take(5).concat(0.0.until(2.0)),
    content="[0.0, 1.0, 2.0, 3.0, 4.0, 0.0, 1.0]",
  )
  inspect!(
    (-50).until(50, step=10).take(100),
    content="[-50, -40, -30, -20, -10, 0, 10, 20, 30, 40]",
  )
  inspect!(
    0.1.until(0.4, step=0.1).take(5),
    content="[0.1, 0.2, 0.30000000000000004]",
  )
  inspect!(0.1.until(0.3, step=0.1), content="[0.1, 0.2]")
  inspect!(
    0.1.until(0.4, step=0.1).take(5),
    content="[0.1, 0.2, 0.30000000000000004]",
  )
  inspect!(
    0x80000000L.until(0x80000000L + 10L, step=2L),
    content="[2147483648, 2147483650, 2147483652, 2147483654, 2147483656]",
  )
  // step < 0
  inspect!((10).until(0, step=-1).take(5), content="[10, 9, 8, 7, 6]")
  inspect!(
    0x80000000L.until(0x80000000L - 10L, step=-2L).take(5),
    content="[2147483648, 2147483646, 2147483644, 2147483642, 2147483640]",
  )
  inspect!(
    0.0.until(-1.0, step=-0.1).take(5),
    content="[0.0, -0.1, -0.2, -0.30000000000000004, -0.4]",
  )
}

test "each" {
  let iter = test_from_array(['1', '2', '3', '4', '5'])
  let exb = Buffer::new(size_hint=5)
  iter.each(fn { x => exb.write_char(x) })
  exb.expect!(content="12345")
}

test "eachi" {
  let iter = test_from_array([1, 2, 3, 4, 5])
  let exb = Buffer::new(size_hint=5)
  iter.eachi(fn { i, x => exb.write_string((x + i).to_string()) })
  exb.expect!(content="13579")
}

// For testing purposes
fn test_from_array[T](arr : Array[T]) -> Iter[T] {
  Iter::new(
    fn {
      yield =>
        for i = 0; i < arr.length(); i = i + 1 {
          if yield(arr[i]) == IterEnd {
            break IterEnd
          }
        } else {
          IterContinue
        }
    },
  )
}
