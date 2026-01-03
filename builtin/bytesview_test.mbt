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
test "BytesView sub with end None" {
  let view = b"\x01\x02\x03"[:]
  let sub = view[1:]
  inspect(sub.length(), content="2")
}

///|
test "BytesView::to_bytes full view" {
  let bytes = b"abc"
  let view = bytes[:]
  inspect(view.to_bytes(), content="b\"abc\"")
}

///|
test "BytesView::to_bytes partial view" {
  let bytes = b"abcd"
  let view = bytes[1:3]
  inspect(view.to_bytes(), content="b\"bc\"")
}

///|
test "panic BytesView out of bounds" {
  let view = b"\x01\x02"[:]
  let _ = view[2]

}

///|
test "panic Bytes sub invalid index" {
  let _ = b"\x01\x02"[2:1]

}

///|
test "panic BytesView sub invalid index" {
  let view = b"\x01\x02"[:]
  let _ = view[2:1]

}
