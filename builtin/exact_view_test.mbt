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
test "exact_view uses the same bounds on all array types" {
  let arr = [1, 2, 3, 4]
  let fixed : FixedArray[Int] = [1, 2, 3, 4]
  let ro : ReadOnlyArray[Int] = [1, 2, 3, 4]
  let view = [0, 1, 2, 3, 4, 5][1:5]
  let mutable = arr.mut_view()
  let raw = @builtin.UninitializedArray::make(4)
  for i in 0..<4 {
    raw[i] = i + 1
  }
  for
    result in [
      arr.exact_view(start=1, end=3),
      fixed.exact_view(start=1, end=3),
      ro.exact_view(start=1, end=3),
      view.exact_view(start=1, end=3),
      mutable.exact_view(start=1, end=3),
      raw.exact_view(start=1, end=3),
    ] {
    assert_eq(result.to_owned(), [2, 3])
    assert_eq(result.exact_view().to_owned(), [2, 3])
    assert_eq(result.exact_view(start=1).to_owned(), [3])
    assert_eq(result.exact_view(end=1).to_owned(), [2])
  }
  let result = mutable.exact_view(start=1)
  mutable[1] = 20
  json_inspect(result.to_owned(), content=[20, 3, 4])
}

///|
test "exact_view strings and bytes use start and end" {
  let text = "ab😀cd"
  let view = "xxab😀cdyy"[2:8]
  inspect(text.exact_view(start=2, end=4), content="😀")
  inspect(view.exact_view(start=2, end=4), content="😀")
  inspect(view.exact_view(start=4), content="cd")
  inspect(view.exact_view(end=2), content="ab")
  inspect(view.exact_view(), content="ab😀cd")
  let bytes = b"abcd"
  let view = b"xabcdx"[1:5]
  inspect(bytes.exact_view(start=1, end=3).to_owned(), content="b\"bc\"")
  inspect(view.exact_view(start=1, end=3).to_owned(), content="b\"bc\"")
  inspect(view.exact_view(start=2).to_owned(), content="b\"cd\"")
  inspect(view.exact_view(end=2).to_owned(), content="b\"ab\"")
  inspect(view.exact_view().to_owned(), content="b\"abcd\"")
}

///|
test "panic exact_view rejects a negative array bound" {
  ignore([1, 2, 3].exact_view(start=-1))
}

///|
test "panic exact_view rejects an oversized fixed array bound" {
  let fixed : FixedArray[Int] = [1, 2, 3]
  ignore(fixed.exact_view(end=4))
}

///|
test "panic exact_view rejects an inverted readonly array range" {
  let ro : ReadOnlyArray[Int] = [1, 2, 3]
  ignore(ro.exact_view(start=2, end=1))
}

///|
test "panic exact_view rejects bounds outside an array view" {
  ignore([0, 1, 2, 3][1:3].exact_view(end=3))
}

///|
test "panic exact_view rejects bounds outside a mutable view" {
  ignore([0, 1, 2, 3].mut_view(start=1, end=3).exact_view(end=3))
}

///|
test "panic exact_view rejects uninitialized array bounds" {
  let raw : @builtin.UninitializedArray[Int] = @builtin.UninitializedArray::make(
    3,
  )
  ignore(raw.exact_view(end=4))
}

///|
test "panic exact_view rejects a negative byte bound" {
  ignore(b"abc".exact_view(start=-1))
}

///|
test "panic exact_view rejects bounds outside a byte view" {
  ignore(b"abcd"[1:3].exact_view(end=3))
}

///|
test "panic exact_view rejects a split string surrogate pair" {
  ignore("ab😀cd".exact_view(end=3))
}

///|
test "panic exact_view rejects a split string view surrogate pair" {
  ignore("xxab😀cdyy"[2:8].exact_view(start=3))
}

///|
test "text operations retain raw UTF-16 behavior" {
  // Testing a nonmatching one-unit prefix/suffix must not split the emoji
  // through exact_view and panic before the comparison can return None.
  debug_inspect("😀".strip_prefix("a"), content="None")
  debug_inspect("😀".strip_suffix("a"), content="None")
  let low = "😀".unsafe_substring(start=1, end=2)
  let text = "a" + low + "b"
  let stripped = text.strip_prefix("a").unwrap()
  inspect(stripped.length(), content="2")
  inspect(stripped.code_unit_at(0) == low.code_unit_at(0), content="true")
  inspect(text.replace(old="a", new="x").length(), content="3")
}
