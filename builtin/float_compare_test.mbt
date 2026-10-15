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
fn[T : Compare] check_float_order(values : Array[T]) -> Unit raise {
  for i, x in values {
    for j, y in values {
      assert_eq(compare(x, y), i.compare(j))
      assert_eq(compare(x, y), -compare(y, x))
      for z in values {
        if compare(x, y) <= 0 && compare(y, z) <= 0 {
          assert_true(compare(x, z) <= 0)
        }
      }
    }
  }
}

///|
test "floating comparison orders NaNs first and preserves IEEE operators" {
  let nan = @double.not_a_number
  check_float_order([
    nan, @double.neg_infinity, -1.0, 0.0, 1.0, @double.infinity,
  ])
  check_float_order([
    @float.not_a_number,
    @float.neg_infinity,
    Float(-1),
    Float(0),
    Float(1),
    @float.infinity,
  ])
  inspect(nan.compare(-nan), content="0")
  inspect((-0.0).compare(0.0), content="0")
  inspect(nan == nan, content="false")
  inspect(nan < 0.0, content="false")
  inspect(nan <= nan, content="false")
  inspect(nan > 0.0, content="false")
  inspect(nan >= nan, content="false")
  let fnan = @float.not_a_number
  inspect(fnan.compare(-fnan), content="0")
  inspect(Float(-0.0).compare(Float(0.0)), content="0")
  inspect(fnan == fnan, content="false")
  inspect(fnan < Float(0), content="false")
  inspect(fnan <= fnan, content="false")
  inspect(fnan > Float(0), content="false")
  inspect(fnan >= fnan, content="false")
  let payload_nan = Float::reinterpret_from_uint(0x7fc00001U)
  inspect(fnan.compare(payload_nan), content="0")
  inspect(nan.compare(payload_nan.to_double()), content="0")
}

///|
test "float sorting and binary search agree on comparison equality" {
  let nan = @double.not_a_number
  let arr = [3.0, 1.0, nan, 2.0, 0.0, -1.0]
  inspect(arr.is_sorted(), content="false")
  arr.sort()
  inspect(arr.map(x => x.to_string()).join(","), content="NaN,-1,0,1,2,3")
  inspect(arr.is_sorted(), content="true")
  debug_inspect(arr.binary_search(nan), content="Ok(0)")
  debug_inspect(arr.binary_search(2.0), content="Ok(4)")
  debug_inspect(arr.binary_search(-2.0), content="Err(1)")
  inspect([1.0, nan].is_sorted(), content="false")
  let floats = [Float(1), @float.not_a_number, Float(-1)]
  floats.sort()
  inspect(floats.map(x => x.to_string()).join(","), content="NaN,-1,1")
  debug_inspect(floats.binary_search(@float.not_a_number), content="Ok(0)")
}

///|
test "large float sorts agree with explicit comparator and stable NaN order" {
  for size in [0, 1, 16, 20, 21, 64, 257] {
    let arr = Array::makei(size, i => {
      if i % 7 == 0 {
        @double.not_a_number
      } else {
        ((size - i) % 23).to_double()
      }
    })
    let expected = arr.copy()
    expected.sort_by(compare)
    let stable = arr.copy()
    stable.mut_view().stable_sort()
    arr.sort()
    assert_eq(arr.map(x => x.to_string()), expected.map(x => x.to_string()))
    assert_eq(stable.map(x => x.to_string()), expected.map(x => x.to_string()))
    let floats = arr.map(x => Float::from_double(x)).rev()
    floats.sort()
    assert_eq(floats.map(x => x.to_string()), expected.map(x => x.to_string()))
  }
  let zeros = [-0.0, 0.0, -0.0, 0.0]
  let bits = zeros.map(x => x.reinterpret_as_int64())
  zeros.mut_view().stable_sort()
  inspect(zeros.map(x => x.reinterpret_as_int64()) == bits, content="true")
  inspect(
    (@double.not_a_number, 1).compare((@double.not_a_number, 2)),
    content="-1",
  )
  inspect([@double.not_a_number].compare([@double.not_a_number]), content="0")
}

///|
priv struct FloatSortEntry {
  key : Double
  index : Int32
} derive(Eq)

///|
impl Compare for FloatSortEntry with fn compare(self, other) {
  self.key.compare(other.key)
}

///|
priv struct DerivedFloatOrder {
  key : Double
  index : Int32
} derive(Eq, Compare)

///|
test "stable sort preserves NaN ties and derived comparison reaches later fields" {
  let nan = @double.not_a_number
  let entries = Array::makei(128, index => FloatSortEntry::{
    key: if index % 3 == 0 {
      nan
    } else {
      (20 - index % 20).to_double()
    },
    index,
  })
  let nan_indices = entries.filter(x => x.key.is_nan()).map(x => x.index)
  entries.mut_view().stable_sort()
  inspect(
    entries[:nan_indices.length()].map(x => x.index) == nan_indices,
    content="true",
  )
  for i in 1..<entries.length() {
    let a = entries[i - 1]
    let b = entries[i]
    assert_true(a.key.compare(b.key) <= 0)
    if a.key.compare(b.key) == 0 {
      assert_true(a.index < b.index)
    }
  }
  let a = DerivedFloatOrder::{ key: nan, index: 1, }
  let b = DerivedFloatOrder::{ key: nan, index: 2, }
  inspect(compare(a, b), content="-1")
  inspect(compare(a, a), content="0")
  inspect(a == a, content="false")
  debug_inspect([a, b].binary_search(a), content="Ok(0)")
  debug_inspect([0.0, 1.0].binary_search(nan), content="Err(0)")
  debug_inspect([nan, nan, -0.0, 0.0].binary_search(0.0), content="Ok(2)")
}
