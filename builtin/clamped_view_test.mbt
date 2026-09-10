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
test "clamped_view on BMP text behaves like plain slicing" {
  let s = "hello world"
  inspect(s.clamped_view(end=5), content="hello")
  inspect(s.clamped_view(start=6), content="world")
  inspect(s.clamped_view(start=3, end=8), content="lo wo")
  inspect(s.clamped_view(), content="hello world")
}

///|
test "clamped_view snaps surrogate-splitting offsets inward" {
  let s = "ab😀cd" // 😀 occupies units 2 and 3
  inspect(s.clamped_view(end=3), content="ab")
  inspect(s.clamped_view(start=3), content="cd")
  inspect(s.clamped_view(end=4), content="ab😀")
  inspect(s.clamped_view(start=2), content="😀cd")
  inspect(s.clamped_view(start=3, end=3), content="")
  // never contains content outside the requested range
  inspect(s.clamped_view(start=1, end=3), content="b")
}

///|
test "clamped_view clamps out-of-range and inverted offsets" {
  let s = "ab😀cd"
  inspect(s.clamped_view(end=100), content="ab😀cd")
  inspect(s.clamped_view(start=-5), content="ab😀cd")
  inspect(s.clamped_view(start=100), content="")
  inspect(s.clamped_view(start=4, end=2), content="")
  inspect("".clamped_view(end=10), content="")
}

///|
test "clamped_view passes unpaired surrogates through unchanged" {
  // A lone trailing surrogate is a boundary: nothing to snap around.
  let lone = "😀".unsafe_substring(start=1, end=2)
  let s = "a" + lone + "b"
  inspect(s.clamped_view(end=2).length(), content="2")
  inspect(s.clamped_view(start=1).length(), content="2")
  inspect(s.clamped_view(start=1, end=2).length(), content="1")
}

///|
test "clamped_view chunking loop reassembles the original" {
  let s = "😀😁😂😃 mixed 😄 text 😅"
  let parts = StringBuilder()
  let mut pos = 0
  while pos < s.length() {
    let chunk = s.clamped_view(start=pos, end=pos + 4)
    parts.write_view(chunk)
    pos += chunk.length()
  }
  inspect(parts.to_string() == s, content="true")
}

///|
test "StringView::clamped_view uses view-relative offsets" {
  let v = "xx ab😀cd".exact_view(start=3) // "ab😀cd", 😀 at units 2-3
  inspect(v.clamped_view(end=3), content="ab")
  inspect(v.clamped_view(start=3), content="cd")
  inspect(v.clamped_view(start=3, end=3), content="")
  inspect(v.clamped_view(end=100), content="ab😀cd")
  // nested truncation
  inspect(v.clamped_view(start=1).clamped_view(end=2), content="b")
}

///|
test "Array::clamped_view clamps out-of-range and inverted offsets" {
  let arr = [1, 2, 3, 4, 5]
  json_inspect(arr.clamped_view().to_owned(), content=[1, 2, 3, 4, 5])
  json_inspect(arr.clamped_view(start=1, end=4).to_owned(), content=[2, 3, 4])
  json_inspect(arr.clamped_view(end=100).to_owned(), content=[1, 2, 3, 4, 5])
  json_inspect(arr.clamped_view(start=-5).to_owned(), content=[1, 2, 3, 4, 5])
  json_inspect(arr.clamped_view(start=100).to_owned(), content=[])
  json_inspect(arr.clamped_view(start=4, end=1).to_owned(), content=[])
  json_inspect(arr.clamped_view(start=-9, end=-3).to_owned(), content=[])
  json_inspect(([] : Array[Int]).clamped_view(end=10).to_owned(), content=[])
}

///|
test "Array::clamped_view agrees with get_view on valid ranges" {
  let arr = [1, 2, 3, 4, 5]
  for start in -1..<=6 {
    for end in -1..<=6 {
      // get_view rejects out-of-range and inverted ranges; clamped_view
      // answers the same on every range get_view accepts.
      guard arr.get_view(start~, end~) is Some(v) else { continue }
      json_inspect(
        arr.clamped_view(start~, end~).to_owned(),
        content=v.to_owned().to_json(),
      )
    }
  }
}

///|
test "ArrayView::clamped_view uses view-relative offsets" {
  let view = [1, 2, 3, 4, 5][1:4] // [2, 3, 4]
  json_inspect(view.clamped_view().to_owned(), content=[2, 3, 4])
  json_inspect(view.clamped_view(start=1, end=100).to_owned(), content=[3, 4])
  json_inspect(view.clamped_view(start=-3, end=2).to_owned(), content=[2, 3])
  json_inspect(view.clamped_view(start=3, end=1).to_owned(), content=[])
  // nested truncation stays inside the original view
  json_inspect(view.clamped_view(start=1).clamped_view(end=100).to_owned(), content=[
    3, 4,
  ])
}

///|
test "Array::clamped_view aliases the backing array" {
  let arr = [1, 2, 3, 4, 5]
  let v = arr.clamped_view(start=1, end=100)
  arr[1] = 20
  json_inspect(v.to_owned(), content=[20, 3, 4, 5])
}

///|
test "Bytes::clamped_view clamps out-of-range and inverted offsets" {
  let bs = b"\x00\x01\x02\x03\x04\x05"
  inspect(bs.clamped_view() == bs, content="true")
  inspect(bs.clamped_view(start=4, end=100) == b"\x04\x05", content="true")
  inspect(bs.clamped_view(start=-5, end=2) == b"\x00\x01", content="true")
  inspect(bs.clamped_view(start=100).length(), content="0")
  inspect(bs.clamped_view(start=4, end=1).length(), content="0")
  inspect(bs.clamped_view(start=-9, end=-3).length(), content="0")
  inspect(b"".clamped_view(end=10).length(), content="0")
}

///|
test "Bytes::clamped_view agrees with get_view on valid ranges" {
  let bs = b"\x00\x01\x02\x03\x04\x05"
  for start in -1..<=7 {
    for end in -1..<=7 {
      guard bs.get_view(start~, end~) is Some(v) else { continue }
      inspect(bs.clamped_view(start~, end~) == v, content="true")
    }
  }
}

///|
test "BytesView::clamped_view uses view-relative offsets" {
  let bv = b"\x00\x01\x02\x03\x04\x05"[1:4] // 0x01 0x02 0x03
  inspect(bv.clamped_view() == bv, content="true")
  inspect(bv.clamped_view(start=1, end=100) == b"\x02\x03", content="true")
  inspect(bv.clamped_view(start=-3, end=2) == b"\x01\x02", content="true")
  inspect(bv.clamped_view(start=3, end=1).length(), content="0")
  // nested truncation stays inside the original view
  inspect(
    bv.clamped_view(start=1).clamped_view(end=100) == b"\x02\x03",
    content="true",
  )
}

///|
test "clamped_view positions an empty result at the clamped start" {
  let arr = [1, 2, 3, 4, 5]
  inspect(arr.clamped_view(start=4, end=1).start_offset(), content="4")
  inspect(arr.clamped_view(start=100).start_offset(), content="5")
  inspect(arr.clamped_view(start=-9, end=-3).start_offset(), content="0")
  let view = arr[1:4] // [2, 3, 4]
  // view-relative offsets, but start_offset() is absolute in the array
  inspect(view.clamped_view(start=2, end=1).start_offset(), content="3")
  inspect(view.clamped_view(start=100).start_offset(), content="4")
  let bs = b"\x00\x01\x02\x03\x04\x05"
  inspect(bs.clamped_view(start=4, end=1).start_offset(), content="4")
  inspect(bs.clamped_view(start=100).start_offset(), content="6")
  let bv = bs[1:4] // 0x01 0x02 0x03
  inspect(bv.clamped_view(start=2, end=1).start_offset(), content="3")
  inspect(bv.clamped_view(start=100).start_offset(), content="4")
}

///|
test "clamped_view saturates at the extremes of Int" {
  let lo = @int.MIN_VALUE
  let hi = @int.MAX_VALUE
  let arr = [1, 2, 3, 4, 5]
  json_inspect(arr.clamped_view(start=lo, end=hi).to_owned(), content=[
    1, 2, 3, 4, 5,
  ])
  json_inspect(arr.clamped_view(start=hi, end=lo).to_owned(), content=[])
  json_inspect(arr.clamped_view(start=lo, end=lo).to_owned(), content=[])
  json_inspect(arr.clamped_view(start=hi, end=hi).to_owned(), content=[])
  let view = arr[1:4]
  json_inspect(view.clamped_view(start=lo, end=hi).to_owned(), content=[2, 3, 4])
  inspect(view.clamped_view(start=hi, end=lo).start_offset(), content="4")
  let bs = b"\x00\x01\x02\x03\x04\x05"
  inspect(bs.clamped_view(start=lo, end=hi) == bs, content="true")
  inspect(bs.clamped_view(start=hi, end=lo).length(), content="0")
  let bv = bs[1:4]
  inspect(bv.clamped_view(start=lo, end=hi) == bv, content="true")
  inspect(bv.clamped_view(start=hi, end=lo).start_offset(), content="4")
}

///|
test "FixedArray::clamped_view clamps out-of-range and inverted offsets" {
  let arr : FixedArray[Int] = [1, 2, 3, 4, 5]
  json_inspect(arr.clamped_view().to_owned(), content=[1, 2, 3, 4, 5])
  json_inspect(arr.clamped_view(start=1, end=4).to_owned(), content=[2, 3, 4])
  json_inspect(arr.clamped_view(end=100).to_owned(), content=[1, 2, 3, 4, 5])
  json_inspect(arr.clamped_view(start=-5).to_owned(), content=[1, 2, 3, 4, 5])
  json_inspect(arr.clamped_view(start=100).to_owned(), content=[])
  json_inspect(arr.clamped_view(start=4, end=1).to_owned(), content=[])
  json_inspect(arr.clamped_view(start=-9, end=-3).to_owned(), content=[])
  json_inspect(
    arr.clamped_view(start=@int.MIN_VALUE, end=@int.MAX_VALUE).to_owned(),
    content=[1, 2, 3, 4, 5],
  )
  json_inspect(
    arr.clamped_view(start=@int.MAX_VALUE, end=@int.MIN_VALUE).to_owned(),
    content=[],
  )
  json_inspect(([] : FixedArray[Int]).clamped_view(end=10).to_owned(), content=[])
  // empty results sit at the clamped start
  inspect(arr.clamped_view(start=4, end=1).start_offset(), content="4")
  inspect(arr.clamped_view(start=100).start_offset(), content="5")
  inspect(arr.clamped_view(start=-9, end=-3).start_offset(), content="0")
}

///|
test "FixedArray::clamped_view aliases the backing array" {
  let arr : FixedArray[Int] = [1, 2, 3, 4, 5]
  let v = arr.clamped_view(start=1, end=100)
  arr[1] = 20
  json_inspect(v.to_owned(), content=[20, 3, 4, 5])
}

///|
test "ReadOnlyArray::clamped_view clamps out-of-range and inverted offsets" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
  json_inspect(arr.clamped_view().to_owned(), content=[1, 2, 3, 4, 5])
  json_inspect(arr.clamped_view(start=1, end=4).to_owned(), content=[2, 3, 4])
  json_inspect(arr.clamped_view(end=100).to_owned(), content=[1, 2, 3, 4, 5])
  json_inspect(arr.clamped_view(start=-5).to_owned(), content=[1, 2, 3, 4, 5])
  json_inspect(arr.clamped_view(start=100).to_owned(), content=[])
  json_inspect(arr.clamped_view(start=4, end=1).to_owned(), content=[])
  json_inspect(arr.clamped_view(start=-9, end=-3).to_owned(), content=[])
  json_inspect(
    arr.clamped_view(start=@int.MIN_VALUE, end=@int.MAX_VALUE).to_owned(),
    content=[1, 2, 3, 4, 5],
  )
  json_inspect(
    arr.clamped_view(start=@int.MAX_VALUE, end=@int.MIN_VALUE).to_owned(),
    content=[],
  )
  json_inspect(([] : ReadOnlyArray[Int]).clamped_view(end=10).to_owned(), content=[])
  // the `end=None` arm delegates separately; it must clamp `start` too
  inspect(arr.clamped_view(start=100).start_offset(), content="5")
  inspect(arr.clamped_view(start=4, end=1).start_offset(), content="4")
}

///|
test "clamped_view with `end` omitted forwards `start` unchanged" {
  // `ReadOnlyArray::clamped_view` handles `end=None` in a separate arm, so an
  // interior start is what catches a mangled `start` there: 0 / negative /
  // past-the-end starts all survive a doubled `start`.
  let ro : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
  let fixed : FixedArray[Int] = [1, 2, 3, 4, 5]
  json_inspect(ro.clamped_view(start=1).to_owned(), content=[2, 3, 4, 5])
  json_inspect(fixed.clamped_view(start=1).to_owned(), content=[2, 3, 4, 5])
  for start in -1..<=6 {
    // omitting `end` must equal passing the full length explicitly
    let ro_omitted = ro.clamped_view(start~)
    let ro_explicit = ro.clamped_view(start~, end=5)
    json_inspect(
      ro_omitted.to_owned(),
      content=ro_explicit.to_owned().to_json(),
    )
    inspect(
      ro_omitted.start_offset() == ro_explicit.start_offset(),
      content="true",
    )
    let fixed_omitted = fixed.clamped_view(start~)
    let fixed_explicit = fixed.clamped_view(start~, end=5)
    json_inspect(
      fixed_omitted.to_owned(),
      content=fixed_explicit.to_owned().to_json(),
    )
    inspect(
      fixed_omitted.start_offset() == fixed_explicit.start_offset(),
      content="true",
    )
  }
}

///|
test "FixedArray/ReadOnlyArray clamped_view agree with get_view" {
  let fixed : FixedArray[Int] = [1, 2, 3, 4, 5]
  let ro : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
  for start in -1..<=6 {
    for end in -1..<=6 {
      // get_view rejects out-of-range and inverted ranges; clamped_view
      // answers the same on every range get_view accepts.
      guard fixed.get_view(start~, end~) is Some(v) else { continue }
      json_inspect(
        fixed.clamped_view(start~, end~).to_owned(),
        content=v.to_owned().to_json(),
      )
      json_inspect(
        ro.clamped_view(start~, end~).to_owned(),
        content=v.to_owned().to_json(),
      )
    }
  }
}

///|
test "MutArrayView/UninitializedArray clamped_view bounds and offsets" {
  let lo = @int.MIN_VALUE
  let hi = @int.MAX_VALUE
  let cases : ReadOnlyArray[(Int, Int, Int, Array[Int])] = [
    (-5, 100, 0, [1, 2, 3, 4, 5]),
    (-2, 2, 0, [1, 2]),
    (1, 4, 1, [2, 3, 4]),
    (3, 100, 3, [4, 5]),
    (4, 1, 4, []),
    (-9, -3, 0, []),
    (100, 100, 5, []),
    (lo, hi, 0, [1, 2, 3, 4, 5]),
    (hi, lo, 5, []),
    (lo, lo, 0, []),
    (hi, hi, 5, []),
  ]
  let raw = @builtin.UninitializedArray::make(5)
  for i in 0..<5 {
    raw[i] = i + 1
  }
  let view = [0, 1, 2, 3, 4, 5, 6].mut_view(start=1, end=6)
  for (start, end, offset, expected) in cases {
    let raw_slice = raw.clamped_view(start~, end~)
    let view_slice = view.clamped_view(start~, end~)
    assert_eq(raw_slice.to_owned(), expected)
    assert_eq(raw_slice.start_offset(), offset)
    assert_eq(view_slice.to_owned(), expected)
    assert_eq(view_slice.start_offset(), 1 + offset)
  }
}

///|
test "MutArrayView/UninitializedArray clamped_view omitted bounds" {
  let raw = @builtin.UninitializedArray::make(3)
  for i in 0..<3 {
    raw[i] = i + 1
  }
  let view = [0, 1, 2, 3, 4].mut_view(start=1, end=4)
  for result in [raw.clamped_view(), view.clamped_view()] {
    assert_eq(result.to_owned(), [1, 2, 3])
  }
  for result in [raw.clamped_view(start=1), view.clamped_view(start=1)] {
    assert_eq(result.to_owned(), [2, 3])
  }
  for result in [raw.clamped_view(end=2), view.clamped_view(end=2)] {
    assert_eq(result.to_owned(), [1, 2])
  }
  for result in [raw.clamped_view(start=-1), view.clamped_view(start=-1)] {
    assert_eq(result.to_owned(), [1, 2, 3])
  }
  for result in [raw.clamped_view(start=10), view.clamped_view(start=10)] {
    assert_eq(result.length(), 0)
  }
}

///|
test "MutArrayView/UninitializedArray clamped_view nested views share storage" {
  let arr = [0, 1, 2, 3, 4]
  let mutable = arr.mut_view(start=1, end=4)
  let view = mutable.clamped_view(start=-5, end=100)
  let nested = view.clamped_view(start=1, end=100)
  mutable[1] = 20
  arr[3] = 30
  json_inspect(view.to_owned(), content=[1, 20, 30])
  json_inspect(nested.to_owned(), content=[20, 30])
  inspect(nested.start_offset(), content="2")
  let raw = @builtin.UninitializedArray::make(3)
  for i in 0..<3 {
    raw[i] = i + 1
  }
  let view = raw.clamped_view(start=1, end=100)
  let nested = view.clamped_view(start=1, end=100)
  raw[2] = 30
  json_inspect(view.to_owned(), content=[2, 30])
  json_inspect(nested.to_owned(), content=[30])
  inspect(nested.start_offset(), content="2")
}

///|
test "MutArrayView/UninitializedArray clamped_view empty arrays" {
  let raw : @builtin.UninitializedArray[Int] = @builtin.UninitializedArray::make(
    0,
  )
  let view = ([] : Array[Int]).mut_view()
  for
    (start, end) in [
      (@int.MIN_VALUE, @int.MAX_VALUE),
      (@int.MAX_VALUE, @int.MIN_VALUE),
    ] {
    for
      result in [
        raw.clamped_view(start~, end~),
        view.clamped_view(start~, end~),
      ] {
      assert_eq(result.length(), 0)
      assert_eq(result.start_offset(), 0)
    }
  }
  let view = [0, 1, 2].mut_view(start=1, end=1)
  inspect(view.clamped_view(start=-1, end=100).start_offset(), content="1")
}

///|
test "Iter::clamped_view clamps finite iterator bounds" {
  let arr = [1, 2, 3]
  let cases : ReadOnlyArray[(Int, Int, Array[Int])] = [
    (-5, 100, [1, 2, 3]),
    (-2, 2, [1, 2]),
    (1, 3, [2, 3]),
    (2, 100, [3]),
    (2, 1, []),
    (-9, -3, []),
    (100, 100, []),
    (@int.MIN_VALUE, @int.MAX_VALUE, [1, 2, 3]),
    (@int.MAX_VALUE, @int.MIN_VALUE, []),
    (@int.MIN_VALUE, @int.MIN_VALUE, []),
    (@int.MAX_VALUE, @int.MAX_VALUE, []),
  ]
  for (start, end, expected) in cases {
    let result = arr.iter().clamped_view(start~, end~)
    assert_eq(result.size_hint(), Some(expected.length()))
    assert_eq(result.collect(), expected)
    // Iter::new has no size hint, so it also exercises the streaming path.
    let source = arr.iter()
    assert_eq(
      Iter::new(() => source.next()).clamped_view(start~, end~).collect(),
      expected,
    )
  }
  debug_inspect(arr.iter().clamped_view().collect(), content="[1, 2, 3]")
  debug_inspect(arr.iter().clamped_view(start=1).collect(), content="[2, 3]")
  debug_inspect(arr.iter().clamped_view(end=2).collect(), content="[1, 2]")
  debug_inspect(
    arr.iter().clamped_view(start=-1).collect(),
    content="[1, 2, 3]",
  )
  debug_inspect(arr.iter().clamped_view(start=100).collect(), content="[]")
  let empty : Iter[Int] = Iter::empty()
  debug_inspect(
    empty.clamped_view(start=@int.MIN_VALUE, end=@int.MAX_VALUE).collect(),
    content="[]",
  )
}

///|
test "Iter::clamped_view stays lazy and composes" {
  let mut reads = 0
  let source = Iter::new(fn() {
    reads += 1
    Some(reads)
  })
  let view = source.clamped_view(start=1, end=5).clamped_view(start=1, end=3)
  inspect(reads, content="0")
  debug_inspect(view.collect(), content="[3, 4]")
  inspect(reads, content="4")
}

///|
test "bracket slicing clamps bounds on arrays and bytes" {
  let lo = @int.MIN_VALUE
  let hi = @int.MAX_VALUE
  let cases : ReadOnlyArray[(Int, Int, Int, Array[Int])] = [
    (-5, 100, 0, [1, 2, 3, 4, 5]),
    (-2, 2, 0, [1, 2]),
    (1, 4, 1, [2, 3, 4]),
    (3, 100, 3, [4, 5]),
    (4, 1, 4, []),
    (-9, -3, 0, []),
    (100, 100, 5, []),
    (lo, hi, 0, [1, 2, 3, 4, 5]),
    (hi, lo, 5, []),
    (lo, lo, 0, []),
    (hi, hi, 5, []),
  ]
  let arr = [1, 2, 3, 4, 5]
  let fixed : FixedArray[Int] = [1, 2, 3, 4, 5]
  let ro : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
  let backing = [0, 1, 2, 3, 4, 5, 6]
  let view = backing[1:6]
  let mut_view = backing.mut_view(start=1, end=6)
  let raw = @builtin.UninitializedArray::make(5)
  for i in 0..<5 {
    raw[i] = i + 1
  }
  let bytes = b"\x01\x02\x03\x04\x05"
  let bv = b"\x00\x01\x02\x03\x04\x05\x06"[1:6]
  for (start, end, offset, expected) in cases {
    for
      result in [
        arr[start:end],
        fixed[start:end],
        ro[start:end],
        raw[start:end],
      ] {
      assert_eq(result.to_owned(), expected)
      assert_eq(result.start_offset(), offset)
    }
    for result in [view[start:end], mut_view[start:end]] {
      assert_eq(result.to_owned(), expected)
      assert_eq(result.start_offset(), 1 + offset)
    }
    assert_eq(bytes[start:end].to_array().map(b => b.to_int()), expected)
    assert_eq(bytes[start:end].start_offset(), offset)
    assert_eq(bv[start:end].to_array().map(b => b.to_int()), expected)
    assert_eq(bv[start:end].start_offset(), 1 + offset)
  }
}

///|
test "bracket slicing defaults and nested array views" {
  let arr = [1, 2, 3, 4, 5]
  let fixed : FixedArray[Int] = [1, 2, 3, 4, 5]
  let ro : ReadOnlyArray[Int] = [1, 2, 3, 4, 5]
  let view = [0, 1, 2, 3, 4, 5, 6][1:6]
  let mut_view = [0, 1, 2, 3, 4, 5, 6].mut_view(start=1, end=6)
  let raw = @builtin.UninitializedArray::make(5)
  for i in 0..<5 {
    raw[i] = i + 1
  }
  for
    result in [
      arr[:].to_owned(),
      fixed[:].to_owned(),
      ro[:].to_owned(),
      view[:].to_owned(),
      mut_view[:].to_owned(),
      raw[:].to_owned(),
    ] {
    assert_eq(result, [1, 2, 3, 4, 5])
  }
  for result in [arr[1:], fixed[1:], ro[1:], view[1:], mut_view[1:], raw[1:]] {
    assert_eq(result.to_owned(), [2, 3, 4, 5])
    assert_eq(result[1:][:-1].length(), 0)
    assert_eq(result[1:][-9:100].to_owned(), [3, 4, 5])
  }
  for result in [arr[:2], fixed[:2], ro[:2], view[:2], mut_view[:2], raw[:2]] {
    assert_eq(result.to_owned(), [1, 2])
  }
  for
    result in [
      arr[-1:],
      fixed[-1:],
      ro[-1:],
      view[-1:],
      mut_view[-1:],
      raw[-1:],
    ] {
    assert_eq(result.to_owned(), [1, 2, 3, 4, 5])
  }
  for
    result in [
      arr[:100],
      fixed[:100],
      ro[:100],
      view[:100],
      mut_view[:100],
      raw[:100],
    ] {
    assert_eq(result.to_owned(), [1, 2, 3, 4, 5])
  }
  for
    result in [
      arr[100:],
      fixed[100:],
      ro[100:],
      view[100:],
      mut_view[100:],
      raw[100:],
    ] {
    assert_eq(result.length(), 0)
  }
  for
    result in [
      arr[:-1],
      fixed[:-1],
      ro[:-1],
      view[:-1],
      mut_view[:-1],
      raw[:-1],
    ] {
    assert_eq(result.length(), 0)
  }
}

///|
test "bracket slicing defaults and nested byte views" {
  let bytes = b"abcde"
  let view = b"xabcdex"[1:6]
  inspect(bytes[:].to_owned(), content="b\"abcde\"")
  inspect(view[:].to_owned(), content="b\"abcde\"")
  inspect(bytes[1:].to_owned(), content="b\"bcde\"")
  inspect(view[1:].to_owned(), content="b\"bcde\"")
  inspect(bytes[:2].to_owned(), content="b\"ab\"")
  inspect(view[:2].to_owned(), content="b\"ab\"")
  inspect(bytes[-1:].to_owned(), content="b\"abcde\"")
  inspect(view[-1:].to_owned(), content="b\"abcde\"")
  inspect(bytes[:100].to_owned(), content="b\"abcde\"")
  inspect(view[:100].to_owned(), content="b\"abcde\"")
  inspect(bytes[100:].length(), content="0")
  inspect(view[100:].length(), content="0")
  inspect(bytes[:-1].length(), content="0")
  inspect(view[:-1].length(), content="0")
  inspect(view[1:][-9:100].to_owned(), content="b\"bcde\"")
  inspect(view[1:][100:].start_offset(), content="6")
}

///|
test "bracket slicing clamps UTF-16 bounds and trims surrogate pairs inward" {
  let lo = @int.MIN_VALUE
  let hi = @int.MAX_VALUE
  let cases : ReadOnlyArray[(Int, Int, Int, String)] = [
    (-5, 100, 0, "ab😀cd"),
    (-2, 2, 0, "ab"),
    (1, 3, 1, "b"),
    (3, 5, 4, "c"),
    (2, 4, 2, "😀"),
    (3, 3, 4, ""),
    (4, 2, 4, ""),
    (-9, -3, 0, ""),
    (100, 100, 6, ""),
    (lo, hi, 0, "ab😀cd"),
    (hi, lo, 6, ""),
    (lo, lo, 0, ""),
    (hi, hi, 6, ""),
  ]
  let str = "ab😀cd"
  let view = "xxab😀cdyy"[2:8]
  for (start, end, offset, expected) in cases {
    assert_eq(str[start:end].to_owned(), expected)
    assert_eq(str[start:end].start_offset(), offset)
    assert_eq(view[start:end].to_owned(), expected)
    assert_eq(view[start:end].start_offset(), 2 + offset)
  }
  inspect(str[:], content="ab😀cd")
  inspect(view[:], content="ab😀cd")
  inspect(str[:3], content="ab")
  inspect(view[:3], content="ab")
  inspect(str[3:], content="cd")
  inspect(view[3:], content="cd")
  inspect(str[-1:], content="ab😀cd")
  inspect(view[-1:], content="ab😀cd")
  inspect(str[:100], content="ab😀cd")
  inspect(view[:100], content="ab😀cd")
  inspect(str[100:], content="")
  inspect(view[100:], content="")
  inspect(str[:-1], content="")
  inspect(view[:-1], content="")
  inspect(view[1:][:2], content="b")
  inspect(view[1:][2:100], content="cd")
  let (left, right) = str.split_at(3)
  inspect(left + right, content="ab😀cd")
}

///|
test "bracket slicing preserves unpaired surrogates" {
  let high = "😀".unsafe_substring(start=0, end=1)
  let low = "😀".unsafe_substring(start=1, end=2)
  for lone in [high, low] {
    let str = "a" + lone + "b"
    let view = ("x" + str + "x")[1:4]
    assert_eq(str[1:2].to_owned(), lone)
    assert_eq(view[1:2].to_owned(), lone)
    assert_eq(str[:2].length(), 2)
    assert_eq(view[1:].length(), 2)
  }
}

///|
test "bracket slicing empty containers clamps integer extremes" {
  let lo = @int.MIN_VALUE
  let hi = @int.MAX_VALUE
  let arr : Array[Int] = []
  let fixed : FixedArray[Int] = []
  let ro : ReadOnlyArray[Int] = []
  let view = arr[:]
  let mut_view = arr.mut_view()
  let raw : @builtin.UninitializedArray[Int] = @builtin.UninitializedArray::make(
    0,
  )
  for
    result in [
      arr[lo:hi],
      fixed[lo:hi],
      ro[lo:hi],
      view[lo:hi],
      mut_view[lo:hi],
      raw[lo:hi],
    ] {
    assert_eq(result.length(), 0)
    assert_eq(result.start_offset(), 0)
  }
  inspect(b""[lo:hi].length(), content="0")
  inspect(b""[:][hi:lo].length(), content="0")
  inspect(""[lo:hi], content="")
  inspect(""[:][hi:lo], content="")
}

///|
test "clamped bracket slices share backing storage" {
  let arr = [1, 2, 3, 4, 5]
  let slice = arr[1:100]
  let nested = slice[1:100]
  let mutable = arr.mut_view(start=1, end=4)
  let read_view = mutable[-9:100]
  mutable[1] = 30
  arr[1] = 20
  json_inspect(slice.to_owned(), content=[20, 30, 4, 5])
  json_inspect(nested.to_owned(), content=[30, 4, 5])
  json_inspect(read_view.to_owned(), content=[20, 30, 4])
  let fixed : FixedArray[Int] = [1, 2, 3]
  let slice = fixed[-1:100]
  fixed[1] = 20
  json_inspect(slice.to_owned(), content=[1, 20, 3])
  let raw = @builtin.UninitializedArray::make(2)
  raw[0] = 1
  raw[1] = 2
  let slice = raw[-1:100]
  raw[1] = 20
  json_inspect(slice.to_owned(), content=[1, 20])
}

///|
test "bracket slicing evaluates receiver and bounds once in order" {
  let events = []
  let arr = [1, 2, 3]
  let receiver = fn() {
    events.push("receiver")
    arr
  }
  let bound = fn(name, value) {
    events.push(name)
    value
  }
  json_inspect(receiver()[bound("start", -1):bound("end", 100)].to_owned(), content=[
    1, 2, 3,
  ])
  json_inspect(receiver()[:bound("end", 2)].to_owned(), content=[1, 2])
  json_inspect(receiver()[bound("start", 1):].to_owned(), content=[2, 3])
  json_inspect(receiver()[:].to_owned(), content=[1, 2, 3])
  json_inspect(events, content=[
    "receiver", "start", "end", "receiver", "end", "receiver", "start", "receiver",
  ])
  // Default end is evaluated after the explicit start expression.
  json_inspect(
    arr[{
      arr.push(4)
      1
    }:].to_owned(),
    content=[2, 3, 4],
  )
}

///|
priv struct SliceProbe {
  events : Array[String]
}

///|
#alias("_[_:_]")
fn SliceProbe::slice(
  self : SliceProbe,
  start? : Int = 17,
  end? : Int = 23,
) -> (Int, Int) {
  self.events.push("slice")
  (start, end)
}

///|
test "custom slice operators receive raw bounds and their own defaults" {
  let probe = SliceProbe::{ events: [], }
  debug_inspect(probe[-100:100], content="(-100, 100)")
  debug_inspect(probe[5:2], content="(5, 2)")
  debug_inspect(probe[:], content="(17, 23)")
  debug_inspect(probe[:100], content="(17, 100)")
  debug_inspect(probe[-100:], content="(-100, 23)")
  inspect(probe.events.length(), content="5")
}

///|
test "rest patterns keep exact array byte and Unicode contents" {
  let arr = [1, 2, 3, 4]
  guard arr is [1, .. middle, 4] else { fail("array rest pattern") }
  json_inspect(middle.to_owned(), content=[2, 3])
  guard middle is [2, .. tail] else { fail("nested rest pattern") }
  json_inspect(tail.to_owned(), content=[3])
  guard b"abcd" is [b'a', .. middle, b'd'] else { fail("byte rest pattern") }
  inspect(middle.to_owned(), content="b\"bc\"")
  guard "ab😀cd" is ['a', .. middle, 'd'] else { fail("string rest pattern") }
  inspect(middle, content="b😀c")
  guard middle is ['b', '😀', .. tail] else { fail("Unicode rest pattern") }
  inspect(tail, content="c")
}

///|
test "panic ReadOnlyArray::exact_view rejects negative start with omitted end" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3]
  ignore(arr.exact_view(start=-1))
}

///|
test "panic ReadOnlyArray::exact_view rejects start beyond length with omitted end" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3]
  ignore(arr.exact_view(start=4))
}

///|
test "panic ReadOnlyArray::exact_view rejects end beyond length" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3]
  ignore(arr.exact_view(start=1, end=4))
}

///|
test "panic ReadOnlyArray::exact_view rejects inverted range" {
  let arr : ReadOnlyArray[Int] = [1, 2, 3]
  ignore(arr.exact_view(start=2, end=1))
}
