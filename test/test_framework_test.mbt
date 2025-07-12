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

test "test_framework_new_function" {
  // Test creating a new test instance
  let test_instance = new("test_name")
  
  // Test that the name is set correctly
  assert_eq(test_instance.name, "test_name")
  
  // Test that the buffer is initialized (empty)
  assert_eq(test_instance.buffer.to_string(), "")
  
  // Test creating with different names
  let test1 = new("first_test")
  let test2 = new("second_test")
  
  assert_eq(test1.name, "first_test")
  assert_eq(test2.name, "second_test")
  
  // Test that they have separate buffers
  assert_eq(test1.buffer.to_string(), "")
  assert_eq(test2.buffer.to_string(), "")
  
  // Test with empty string name
  let empty_test = new("")
  assert_eq(empty_test.name, "")
  assert_eq(empty_test.buffer.to_string(), "")
  
  // Test with special characters in name
  let special_test = new("test with spaces and symbols!@#$%^&*()")
  assert_eq(special_test.name, "test with spaces and symbols!@#$%^&*()")
  assert_eq(special_test.buffer.to_string(), "")
}

test "test_framework_new_with_long_names" {
  // Test with very long names
  let long_name = "a".repeat(1000)
  let long_test = new(long_name)
  
  assert_eq(long_test.name, long_name)
  assert_eq(long_test.buffer.to_string(), "")
  
  // Test with unicode characters
  let unicode_test = new("测试名称🧪🔬")
  assert_eq(unicode_test.name, "测试名称🧪🔬")
  assert_eq(unicode_test.buffer.to_string(), "")
}

test "test_framework_new_independence" {
  // Test that multiple test instances are independent
  let test_a = new("test_a")
  let test_b = new("test_b")
  
  // Write to one buffer
  test_a.buffer.write_string("content for test A")
  
  // Check that the other buffer is still empty
  assert_eq(test_b.buffer.to_string(), "")
  assert_eq(test_a.buffer.to_string(), "content for test A")
  
  // Write to the other buffer
  test_b.buffer.write_string("content for test B")
  
  // Check that they remain independent
  assert_eq(test_a.buffer.to_string(), "content for test A")
  assert_eq(test_b.buffer.to_string(), "content for test B")
}

test "test_framework_new_buffer_functionality" {
  // Test that the buffer created by new() is functional
  let test_instance = new("buffer_test")
  
  // Test writing to the buffer
  test_instance.buffer.write_string("Hello")
  assert_eq(test_instance.buffer.to_string(), "Hello")
  
  // Test appending to the buffer
  test_instance.buffer.write_string(" World")
  assert_eq(test_instance.buffer.to_string(), "Hello World")
  
  // Test writing characters
  test_instance.buffer.write_char('!')
  assert_eq(test_instance.buffer.to_string(), "Hello World!")
  
  // Test that name remains unchanged
  assert_eq(test_instance.name, "buffer_test")
}

test "test_framework_new_with_newlines" {
  // Test with names containing newlines
  let newline_test = new("test\nwith\nnewlines")
  assert_eq(newline_test.name, "test\nwith\nnewlines")
  assert_eq(newline_test.buffer.to_string(), "")
  
  // Test with tabs
  let tab_test = new("test\twith\ttabs")
  assert_eq(tab_test.name, "test\twith\ttabs")
  assert_eq(tab_test.buffer.to_string(), "")
}

test "test_framework_new_edge_cases" {
  // Test with various edge case names
  let edge_cases = [
    "test_with_underscores",
    "test-with-dashes",
    "test.with.dots",
    "test/with/slashes",
    "test\\with\\backslashes",
    "test\"with\"quotes",
    "test'with'apostrophes",
    "test{with}braces",
    "test[with]brackets",
    "test(with)parentheses",
  ]
  
  for name in edge_cases {
    let test_instance = new(name)
    assert_eq(test_instance.name, name)
    assert_eq(test_instance.buffer.to_string(), "")
  }
}

test "test_framework_new_multiple_instances" {
  // Test creating many instances
  let instances = []
  for i in 0..<100 {
    let instance = new("test_" + i.to_string())
    instances.push(instance)
  }
  
  // Verify all instances are correctly created
  for i in 0..<instances.length() {
    assert_eq(instances[i].name, "test_" + i.to_string())
    assert_eq(instances[i].buffer.to_string(), "")
  }
  
  // Test that they remain independent
  for i in 0..<instances.length() {
    instances[i].buffer.write_string("content_" + i.to_string())
  }
  
  // Verify each has its own content
  for i in 0..<instances.length() {
    assert_eq(instances[i].buffer.to_string(), "content_" + i.to_string())
  }
}

test "test_framework_new_name_immutability" {
  // Test that the name field behaves as expected
  let test_instance = new("original_name")
  let original_name = test_instance.name
  
  // Verify name is set correctly
  assert_eq(test_instance.name, "original_name")
  assert_eq(original_name, "original_name")
  
  // The name should remain the same throughout the test lifecycle
  test_instance.buffer.write_string("some content")
  assert_eq(test_instance.name, "original_name")
  
  // Test with different content
  test_instance.buffer.write_string(" more content")
  assert_eq(test_instance.name, "original_name")
  assert_eq(test_instance.buffer.to_string(), "some content more content")
}