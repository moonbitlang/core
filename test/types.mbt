// Copyright 2025 International Digital Economy Academy
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
#visibility(change_to="abstract")
pub(all) struct T {
  name : String
  buffer : StringBuilder
}

///|
pub fn new(name : String) -> T {
  { name, buffer: StringBuilder::new() }
}

///|
test "T struct construction and usage" {
  // Test basic construction
  let t1 = new("test1")
  assert_eq(t1.name, "test1")

  // Test with different names
  let t2 = new("hello")
  assert_eq(t2.name, "hello")
  let t3 = new("")
  assert_eq(t3.name, "")

  // Test with longer names
  let t4 = new("this is a longer test name")
  assert_eq(t4.name, "this is a longer test name")

  // Test that buffer is properly initialized
  let t5 = new("buffer_test")
  assert_eq(t5.name, "buffer_test")
  // The buffer should be empty initially
  let buffer_str = t5.buffer.to_string()
  assert_eq(buffer_str, "")

  // Test with special characters
  let t6 = new("test!@#$%^&*()")
  assert_eq(t6.name, "test!@#$%^&*()")

  // Test with Unicode characters
  let t7 = new("测试🚀🎯")
  assert_eq(t7.name, "测试🚀🎯")
}
