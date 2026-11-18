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
test "matching snapshots consume the buffer and continue" {
  let t = Test("manual context")
  t.write("he\rllo\r\n")
  t.snapshot(filename="test.txt")
  inspect(t.buffer.to_string(), content="")
  t.writeln("hello")
  t.snapshot(filename="test.txt")
  inspect(t.buffer.to_string(), content="")
}

///|
test "snapshot mismatch preserves the buffer and protocol" {
  let t = Test("mismatch")
  t.write("different")
  guard expect_error(() => t.snapshot(filename="test.txt"))
    is SnapshotError(message) else {
    fail("expected legacy snapshot error")
  }
  assert_true(message.has_prefix("@SNAPSHOT_TESTING "))
  inspect(t.buffer.to_string(), content="different")
}

///|
test "snapshot I/O errors preserve the buffer" {
  let t = Test("I/O failure")
  t.write("hello")
  let error = expect_error(() => t.snapshot(filename="\u0000"))
  assert_false(error is SnapshotError(_))
  inspect(t.buffer.to_string(), content="hello")
}

///|
test "missing snapshots follow Moon's empty text semantics" {
  let t = Test("empty")
  t.write("\r\r")
  t.snapshot(filename="missing-empty-snapshot.txt")
  inspect(t.buffer.to_string(), content="")
}
