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
async test "RawFd::write rejects source ranges outside the buffer" {
  let (r, w) = @fd_util.pipe(
    read_end_is_async=false,
    write_end_is_async=false,
    context="RawFd::write bounds",
  )
  let r = @raw_fd.RawFd(r)
  defer r.close()
  let w = @raw_fd.RawFd(w)
  defer w.close()
  let src = b"abcd"
  // `len` past the end of `src` used to send heap memory to the fd
  try w.write(src, offset=2, len=64) catch {
    Failure(msg) if msg.contains("out of bounds") => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    n => fail("write past the end succeeded with \{n} bytes")
  }
  try w.write(src, offset=-1, len=1) catch {
    Failure(msg) if msg.contains("out of bounds") => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    n => fail("write with a negative offset succeeded with \{n} bytes")
  }
  try w.write(src, offset=5) catch {
    Failure(msg) if msg.contains("out of bounds") => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    n => fail("write starting past the end succeeded with \{n} bytes")
  }
  try w.write(src, len=-1) catch {
    Failure(msg) if msg.contains("out of bounds") => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    n => fail("write with a negative length succeeded with \{n} bytes")
  }
  // in-range writes are unaffected, including empty ones at the end
  assert_eq(w.write(src, offset=4), 0)
  assert_eq(w.write(src, offset=1, len=2), 2)
  let dst = FixedArray::make(4, b'\x00')
  assert_eq(r.read(dst), 2)
  assert_eq(dst[0], b'b')
  assert_eq(dst[1], b'c')
}

///|
async test "RawFd::read rejects destination ranges outside the buffer" {
  let (r, w) = @fd_util.pipe(
    read_end_is_async=false,
    write_end_is_async=false,
    context="RawFd::read bounds",
  )
  let r = @raw_fd.RawFd(r)
  defer r.close()
  let w = @raw_fd.RawFd(w)
  defer w.close()
  assert_eq(w.write(b"0123456789"), 10)
  let dst = FixedArray::make(4, b'\x00')
  // `max_len` past the end of `dst` used to overrun the heap
  try r.read(dst, offset=2, max_len=64) catch {
    Failure(msg) if msg.contains("out of bounds") => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    n => fail("read past the end succeeded with \{n} bytes")
  }
  try r.read(dst, offset=-1, max_len=1) catch {
    Failure(msg) if msg.contains("out of bounds") => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    n => fail("read with a negative offset succeeded with \{n} bytes")
  }
  try r.read(dst, offset=5) catch {
    Failure(msg) if msg.contains("out of bounds") => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    n => fail("read starting past the end succeeded with \{n} bytes")
  }
  try r.read(dst, max_len=-1) catch {
    Failure(msg) if msg.contains("out of bounds") => ()
    err => fail("unexpected error: \{err}")
  } noraise {
    n => fail("read with a negative length succeeded with \{n} bytes")
  }
  // nothing was consumed by the rejected calls
  assert_eq(r.read(dst, offset=1, max_len=3), 3)
  assert_eq(dst[0], b'\x00')
  assert_eq(dst[1], b'0')
  assert_eq(dst[3], b'2')
}
