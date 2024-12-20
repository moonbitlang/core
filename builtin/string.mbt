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

///|
/// @intrinsic %string.substring
fn unsafe_substring(str : String, start : Int, end : Int) -> String {
  let len = end - start
  let bytes = FixedArray::make(len * 2, Byte::default())
  bytes.blit_from_string(0, str, start, len)
  bytes.unsafe_to_bytes().to_unchecked_string()
}

///|
/// Returns a new string containing characters from the original string starting
/// at `start` index up to (but not including) `end` index.
///
/// Parameters:
///
/// * `string` : The source string from which to extract the substring.
/// * `start` : The starting index of the substring (inclusive). Defaults to 0.
/// * `end` : The ending index of the substring (exclusive). Defaults to the
/// length of the string.
///
/// Returns a new string containing the specified substring.
///
/// Example:
///
/// ```moonbit
/// test "substring/basic" {
///   let s = "Hello world"
///   inspect!(s.substring(start=0, end=5), content="Hello")
///   inspect!(s.substring(start=6, end=11), content="world")
///   inspect!(s.substring(), content="Hello world")
/// }
/// 
/// test "substring/empty" {
///   let s = "test"
///   inspect!(s.substring(start=2, end=2), content="")
///   inspect!("".substring(), content="")
/// }
/// 
/// test "panic substring/invalid_range" {
///   let s = "test"
///   ignore(s.substring(start=-1))
///   ignore(s.substring(end=5))
///   ignore(s.substring(start=3, end=2))
/// }
/// ```
pub fn substring(self : String, start~ : Int = 0, end? : Int) -> String {
  let len = self.length()
  let end = match end {
    Some(end) => end
    None => len
  }
  guard start >= 0 && start <= end && end <= len
  unsafe_substring(self, start, end)
}

test "substring/basic" {
  let s = "hello, world"
  inspect!(s.substring(start=0, end=5), content="hello")
  inspect!(s.substring(start=7, end=12), content="world")
  inspect!(s.substring(), content="hello, world")
}

test "substring/empty" {
  let s = "test"
  inspect!(s.substring(start=2, end=2), content="")
  inspect!(s.substring(start=4, end=4), content="")
  inspect!("".substring(), content="")
}

test "panic substring/invalid_range" {
  let s = "test"
  ignore(s.substring(start=-1))
  ignore(s.substring(end=5))
  ignore(s.substring(start=3, end=2))
}

test "substring/basic" {
  inspect!("Hello world".substring(start=0, end=5), content="Hello")
  inspect!("Hello world".substring(start=6, end=11), content="world")
  inspect!("Hello world".substring(start=0), content="Hello world")
  inspect!("Hello world".substring(start=6), content="world")
}

test "substring/boundary" {
  inspect!("".substring(start=0, end=0), content="")
  inspect!("a".substring(start=0, end=1), content="a")
  inspect!("abc".substring(start=0), content="abc")
  inspect!("abc".substring(start=1), content="bc")
  inspect!("abc".substring(start=0, end=3), content="abc")
}

test "panic substring/out_of_bounds" {
  ignore("hello".substring(start=-1, end=4))
  ignore("hello".substring(start=6, end=4))
  ignore("hello".substring(start=0, end=6))
}
