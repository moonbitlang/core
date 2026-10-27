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
test "unsafe_view agrees with exact_view on every valid array range" {
  let arr = [1, 2, 3]
  let fixed : FixedArray[Int32] = [1, 2, 3]
  let ro : ReadOnlyArray[Int32] = [1, 2, 3]
  let nested = [0, 1, 2, 3, 4][1:4]
  let mutable = [0, 1, 2, 3, 4].mut_view(start=1, end=4)
  let raw = @builtin.UninitializedArray::make(3)
  for i in 0..<3 {
    raw[i] = i + 1
  }
  for start in 0..<=3 {
    for end in start..<=3 {
      let expected = arr.exact_view(start~, end~).to_owned()
      for
        result in [
          arr.unsafe_view(start~, end~),
          fixed.unsafe_view(start~, end~),
          ro.unsafe_view(start~, end~),
          nested.unsafe_view(start~, end~),
          mutable.unsafe_view(start~, end~),
          raw.unsafe_view(start~, end~),
        ] {
        assert_eq(result.to_owned(), expected)
        assert_eq(result.unsafe_view().to_owned(), expected)
      }
      assert_eq(nested.unsafe_view(start~, end~).start_offset(), 1 + start)
      assert_eq(mutable.unsafe_view(start~, end~).start_offset(), 1 + start)
    }
  }
  for
    result in [
      arr.unsafe_view(),
      fixed.unsafe_view(),
      ro.unsafe_view(),
      nested.unsafe_view(),
      mutable.unsafe_view(),
      raw.unsafe_view(),
    ] {
    assert_eq(result.to_owned(), [1, 2, 3])
    assert_eq(result.unsafe_view(start=1).to_owned(), [2, 3])
    assert_eq(result.unsafe_view(end=2).to_owned(), [1, 2])
    assert_eq(result.unsafe_view(start=1).unsafe_view(end=1).to_owned(), [2])
  }
  let shared = arr.unsafe_view(start=1)
  arr[1] = 20
  json_inspect(shared.to_owned(), content=[20, 3])
}

///|
test "unsafe_view agrees with exact_view on valid byte ranges" {
  let bytes = b"abc"
  let nested = b"xabcy"[1:4]
  for start in 0..<=3 {
    for end in start..<=3 {
      let expected = bytes.exact_view(start~, end~).to_owned()
      assert_eq(bytes.unsafe_view(start~, end~).to_owned(), expected)
      assert_eq(nested.unsafe_view(start~, end~).to_owned(), expected)
      assert_eq(nested.unsafe_view(start~, end~).start_offset(), 1 + start)
    }
  }
  inspect(bytes.unsafe_view().to_owned(), content="b\"abc\"")
  inspect(nested.unsafe_view().to_owned(), content="b\"abc\"")
  inspect(bytes.unsafe_view(start=1).to_owned(), content="b\"bc\"")
  inspect(bytes.unsafe_view(end=2).to_owned(), content="b\"ab\"")
  inspect(
    nested.unsafe_view(start=1).unsafe_view(end=1).to_owned(),
    content="b\"b\"",
  )
}

///|
test "unsafe_view preserves every valid raw UTF-16 range" {
  let text = "ab😀cd"
  let nested = "xxab😀cdyy"[2:8]
  for start in 0..<=text.length() {
    for end in start..<=text.length() {
      for
        result in [
          text.unsafe_view(start~, end~),
          nested.unsafe_view(start~, end~),
        ] {
        assert_eq(result.length(), end - start)
        for i in 0..<result.length() {
          assert_eq(result.code_unit_at(i), text.code_unit_at(start + i))
        }
      }
      assert_eq(nested.unsafe_view(start~, end~).start_offset(), 2 + start)
      if text.get_view(start~, end~) is Some(expected) {
        assert_eq(text.unsafe_view(start~, end~), expected)
        assert_eq(nested.unsafe_view(start~, end~), expected)
      }
    }
  }
  inspect(text.unsafe_view(), content="ab😀cd")
  inspect(nested.unsafe_view(), content="ab😀cd")
  inspect(text.unsafe_view(start=2), content="😀cd")
  inspect(text.unsafe_view(end=4), content="ab😀")
  inspect(nested.unsafe_view(start=2).unsafe_view(end=2), content="😀")
}

///|
test "unsafe_view supports empty containers" {
  let arr : Array[Int32] = []
  let fixed : FixedArray[Int32] = []
  let ro : ReadOnlyArray[Int32] = []
  let raw : @builtin.UninitializedArray[Int32] = @builtin.UninitializedArray::make(
    0,
  )
  for
    result in [
      arr.unsafe_view(),
      fixed.unsafe_view(),
      ro.unsafe_view(),
      arr[:].unsafe_view(),
      arr.mut_view().unsafe_view(),
      raw.unsafe_view(),
    ] {
    assert_eq(result.length(), 0)
  }
  inspect(b"".unsafe_view().length(), content="0")
  inspect(b""[:].unsafe_view().length(), content="0")
  inspect("".unsafe_view().length(), content="0")
  inspect(""[:].unsafe_view().length(), content="0")
}

///|
#warnings("-deprecated")
test "legacy view aliases retain exact array and byte behavior" {
  let arr = [1, 2, 3]
  let fixed : FixedArray[Int32] = [1, 2, 3]
  let ro : ReadOnlyArray[Int32] = [1, 2, 3]
  for
    result in [
      arr.view(start=1),
      fixed.view(start=1),
      ro.view(start=1),
      arr[:].view(start=1),
      arr.mut_view().view(start=1),
    ] {
    assert_eq(result.to_owned(), [2, 3])
  }
  inspect(b"abc".view(start=1).to_owned(), content="b\"bc\"")
  inspect(b"xabc"[1:].view(start=1).to_owned(), content="b\"bc\"")
  json_inspect(arr.iter().view(start=-1, end=100).collect(), content=[1, 2, 3])
}

///|
#warnings("-deprecated")
test "panic legacy array view still validates bounds" {
  ignore([1, 2, 3].view(end=100))
}

///|
#warnings("-deprecated")
test "panic legacy byte view still validates bounds" {
  ignore(b"abc".view(end=100))
}
