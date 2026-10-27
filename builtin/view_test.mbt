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
test "view clamps consistently across array types and matches slicing" {
  let arr = [1, 2, 3]
  let fixed : FixedArray[Int32] = [1, 2, 3]
  let ro : ReadOnlyArray[Int32] = [1, 2, 3]
  let nested = [0, 1, 2, 3, 4][1:4]
  let mutable = [0, 1, 2, 3, 4].mut_view(start=1, end=4)
  let raw = @builtin.UninitializedArray::make(3)
  for i in 0..<3 {
    raw[i] = i + 1
  }
  let cases : ReadOnlyArray[(Int32, Int32, Array[Int32])] = [
    (1, 2, [2]),
    (-1, 2, [1, 2]),
    (1, 100, [2, 3]),
    (2, 1, []),
    (-9, -3, []),
    (100, 100, []),
    (@int.MIN_VALUE, @int.MAX_VALUE, [1, 2, 3]),
    (@int.MAX_VALUE, @int.MIN_VALUE, []),
  ]
  for (start, end, expected) in cases {
    for
      result in [
        arr.view(start~, end~),
        fixed.view(start~, end~),
        ro.view(start~, end~),
        nested.view(start~, end~),
        mutable.view(start~, end~),
        raw.view(start~, end~),
        arr[start:end],
        fixed[start:end],
        ro[start:end],
        nested[start:end],
        mutable[start:end],
        raw[start:end],
      ] {
      assert_eq(result.to_owned(), expected)
    }
    assert_eq(arr.iter().view(start~, end~).collect(), expected)
    assert_eq(arr.iter()[start:end].collect(), expected)
  }
  for
    result in [
      arr.view(),
      fixed.view(),
      ro.view(),
      nested.view(),
      mutable.view(),
      raw.view(),
    ] {
    assert_eq(result.to_owned(), [1, 2, 3])
    assert_eq(result.view(start=1).to_owned(), [2, 3])
    assert_eq(result.view(end=2).to_owned(), [1, 2])
    assert_eq(result.view(start=1).view(start=-1, end=100).to_owned(), [2, 3])
  }
  let shared = arr.view(start=1, end=100)
  arr[1] = 20
  json_inspect(shared.to_owned(), content=[20, 3])
}

///|
test "view clamps byte bounds and preserves relative offsets" {
  let bytes = b"abc"
  let nested = b"xabcy"[1:4]
  let cases : ReadOnlyArray[(Int32, Int32, Bytes)] = [
    (1, 2, b"b"),
    (-1, 2, b"ab"),
    (1, 100, b"bc"),
    (2, 1, b""),
    (-9, -3, b""),
    (100, 100, b""),
    (@int.MIN_VALUE, @int.MAX_VALUE, b"abc"),
    (@int.MAX_VALUE, @int.MIN_VALUE, b""),
  ]
  for (start, end, expected) in cases {
    for
      result in [
        bytes.view(start~, end~),
        nested.view(start~, end~),
        bytes[start:end],
        nested[start:end],
      ] {
      assert_eq(result.to_owned(), expected)
    }
  }
  inspect(bytes.view().to_owned(), content="b\"abc\"")
  inspect(nested.view().to_owned(), content="b\"abc\"")
  inspect(nested.view(start=1).to_owned(), content="b\"bc\"")
  inspect(nested.view(end=2).to_owned(), content="b\"ab\"")
  inspect(nested.view(start=100).start_offset(), content="4")
}

///|
test "view clamps strings and snaps surrogate boundaries like slicing" {
  let text = "ab😀cd"
  let nested = "xxab😀cdyy"[2:8]
  let cases : ReadOnlyArray[(Int32, Int32, String)] = [
    (1, 3, "b"),
    (3, 5, "c"),
    (2, 4, "😀"),
    (3, 3, ""),
    (4, 2, ""),
    (-9, -3, ""),
    (100, 100, ""),
    (@int.MIN_VALUE, @int.MAX_VALUE, "ab😀cd"),
    (@int.MAX_VALUE, @int.MIN_VALUE, ""),
  ]
  for (start, end, expected) in cases {
    for
      result in [
        text.view(start~, end~),
        nested.view(start~, end~),
        text[start:end],
        nested[start:end],
      ] {
      assert_eq(result.to_owned(), expected)
    }
    assert_eq(
      text.view(start_offset=start, end_offset=end).to_owned(),
      expected,
    )
    assert_eq(
      nested.view(start_offset=start, end_offset=end).to_owned(),
      expected,
    )
  }
  inspect(text.view(), content="ab😀cd")
  inspect(nested.view(), content="ab😀cd")
  inspect(text.view(start=3), content="cd")
  inspect(nested.view(end=3), content="ab")
  inspect(nested.view(start=1).view(end=2), content="b")
  inspect(
    text.view(start=0, end=6, start_offset=2, end_offset=4),
    content="😀",
  )
  inspect(
    nested.view(start=0, end=6, start_offset=2, end_offset=4),
    content="😀",
  )
}

///|
test "view supports compiler-generated Unicode lexmatch captures" {
  let text = "ab😀cd"
  let from_string = lexmatch text {
    (re"😀+" as matched, before=prefix, after=suffix) =>
      (prefix.to_owned(), matched.to_owned(), suffix.to_owned())
    _ => ("", "", "")
  }
  debug_inspect(from_string, content="(\"ab\", \"😀\", \"cd\")")
  let nested = "xxab😀cdyy"[2:8]
  let from_view = lexmatch nested {
    (re"😀+" as matched, before=prefix, after=suffix) =>
      (prefix.to_owned(), matched.to_owned(), suffix.to_owned())
    _ => ("", "", "")
  }
  debug_inspect(from_view, content="(\"ab\", \"😀\", \"cd\")")
}
