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

test "byte_to_string" {
  let b1 = b'\x00'
  let b2 = b'\x0F'
  let b3 = b'\xFF'
  @core_test.is_true(b1.to_string() == "b'\\x00'")!
  @core_test.is_true(b2.to_string() == "b'\\x0F'")!
  @core_test.is_true(b3.to_string() == "b'\\xFF'")!
}

test "byte_debug_write" {
  let b1 = b'\x00'
  let b2 = b'\x0F'
  let b3 = b'\xFF'
  let buf = Buffer::new(size_hint=10)
  b1.debug_write(buf)
  @core_test.is_true(buf.to_string() == "b'\\x00'")!
  buf.reset()
  b2.debug_write(buf)
  @core_test.is_true(buf.to_string() == "b'\\x0F'")!
  buf.reset()
  b3.debug_write(buf)
  @core_test.is_true(buf.to_string() == "b'\\xFF'")!
}

test "byte_compare" {
  let b1 = b'\x00'
  let b2 = b'\x0F'
  let b3 = b'\xFF'
  @core_test.is_true(b1.compare(b1) == 0)!
  @core_test.is_true(b1.compare(b2) < 0)!
  @core_test.is_true(b2.compare(b1) > 0)!
  @core_test.is_true(b2.compare(b3) < 0)!
  @core_test.is_true(b3.compare(b2) > 0)!
  @core_test.is_true(b3.compare(b3) == 0)!
}

test "byte_op_equal" {
  let b1 = b'\x00'
  let b2 = b'\x0F'
  let b3 = b'\xFF'
  @core_test.is_true(b1.op_equal(b1))!
  @core_test.is_true(b1.op_equal(b2) |> not)!
  @core_test.is_true(b2.op_equal(b1) |> not)!
  @core_test.is_true(b2.op_equal(b2))!
  @core_test.is_true(b2.op_equal(b3) |> not)!
  @core_test.is_true(b3.op_equal(b2) |> not)!
  @core_test.is_true(b3.op_equal(b3))!
}
