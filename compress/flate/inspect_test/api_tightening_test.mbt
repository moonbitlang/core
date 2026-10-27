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
test "codec equality methods can be passed as functions across packages" {
  let error_equal = @flate.InflateErrorKind::equal
  @test.assert_eq(error_equal(Truncated, Truncated), true)
  let status_equal = @flate.Status::equal
  @test.assert_eq(status_equal(Done, Done), true)
  let action_equal = @flate.DeflateAction::equal
  @test.assert_eq(action_equal(Finish, Finish), true)
  let gzip_equal = @gzip.GzipErrorKind::equal
  @test.assert_eq(gzip_equal(Truncated, Truncated), true)
  let zlib_equal = @zlib.ZlibErrorKind::equal
  @test.assert_eq(zlib_equal(Truncated, Truncated), true)
  @test.assert_eq(zlib_equal(Truncated, InvalidHeader), false)
}

///|
test "bounded inflate_all enforces its decoded-size boundary" {
  let source = b"bounded one-shot inflate"
  let compressed = @flate.deflate_all(source)
  @test.assert_eq(
    @flate.inflate_all(compressed, max_output=source.length()),
    source,
  )
  // The limited convenience API deliberately retains inflate_all's prefix
  // semantics; exact framing is the separate inflate_exact contract.
  @test.assert_eq(
    @flate.inflate_all(compressed + b"TRAILING", max_output=source.length()),
    source,
  )
  let InflateError(kind, _) = @test.expect_error(() => {
    @flate.inflate_all(compressed, max_output=source.length() - 1)
  })
  @test.assert_eq(kind, OutputLimitExceeded)
  let InflateError(kind, _) = @test.expect_error(() => {
    @flate.inflate_all(compressed, max_output=-1)
  })
  @test.assert_eq(kind, InvalidArgument)
  let empty = @flate.deflate_all(b"")
  @test.assert_eq(@flate.inflate_all(empty, max_output=0), b"")
  // More than one scratch buffer forces the convenience driver through
  // NeedMoreOutput without weakening the decoded-size limit.
  let large = Bytes::from_array(Array::make(20000, b'X'))
  let large_compressed = @flate.deflate_all(large)
  @test.assert_eq(
    @flate.inflate_all(large_compressed, max_output=large.length()),
    large,
  )
}

///|
fn inflate_exact_sources() -> Array[Bytes] {
  let patterned = Array::make(30000, b'\x00')
  for i in 0..<30000 {
    patterned[i] = (i * 31 + i / 7).to_byte()
  }
  [
    b"",
    b"hello",
    Bytes::from_array(Array::make(8191, b'a')),
    Bytes::from_array(Array::make(8192, b'b')),
    Bytes::from_array(Array::make(8193, b'c')),
    Bytes::from_array(Array::make(30000, b'z')),
    Bytes::from_array(patterned),
  ]
}

///|
test "inflate_exact preallocated and grow paths agree" {
  for source in inflate_exact_sources() {
    for level in [0, 1, 6] {
      let compressed = @flate.deflate_all(source, level~)
      @test.assert_eq(
        @flate.inflate_exact(compressed, preallocated=true),
        source,
      )
      @test.assert_eq(@flate.inflate_exact(compressed), source)
    }
  }
}

///|
test "preallocated inflate_exact rejects truncation after output suspension" {
  let compressed = @flate.deflate_all(Bytes::make(8194, b'x'), level=0)
  let InflateError(kind, _) = @test.expect_error(() => {
    @flate.inflate_exact(
      compressed[:compressed.length() - 1],
      preallocated=true,
    )
  })
  @test.assert_eq(kind, Truncated)
}

///|
test "inflate_exact enforces max_output on both paths" {
  let source = Bytes::from_array(Array::make(20000, b'X'))
  let compressed = @flate.deflate_all(source)
  @test.assert_eq(@flate.inflate_exact(compressed, max_output=20000), source)
  @test.assert_eq(
    @flate.inflate_exact(compressed, max_output=20000, preallocated=true),
    source,
  )
  for preallocated in [false, true] {
    let InflateError(kind, _) = @test.expect_error(() => {
      @flate.inflate_exact(compressed, max_output=19999, preallocated~)
    })
    @test.assert_eq(kind, OutputLimitExceeded)
  }
  let InflateError(kind, _) = @test.expect_error(() => {
    @flate.inflate_exact(compressed, max_output=-1)
  })
  @test.assert_eq(kind, InvalidArgument)
}

///|
test "inflate_exact entry cancellation raises Cancelled on both paths" {
  for preallocated in [false, true] {
    let InflateError(kind, _) = @test.expect_error(() => {
      @flate.inflate_exact(b"\x03\x00", preallocated~, cancelled=() => true)
    })
    @test.assert_eq(kind, Cancelled)
  }
}

///|
test "preallocated inflate_exact honors cancellation in both passes" {
  let source = Bytes::from_array(Array::make(30000, b'A'))
  let compressed = @flate.deflate_all(source)
  // Pass 1 (counting) covers 30000 bytes in four 8192-byte steps and polls
  // four times; pass 2 replays the same four steps and polls four more.
  // Poll 3 lands in pass 1, poll 6 in pass 2.
  for cancel_at in [3, 6] {
    let mut calls = 0
    let InflateError(kind, _) = @test.expect_error(() => {
      @flate.inflate_exact(
        compressed,
        cancelled=() => {
          calls = calls + 1
          calls >= cancel_at
        },
        preallocated=true,
      )
    })
    @test.assert_eq(kind, Cancelled)
  }
}

///|
test "inflate_all honours entry and mid-stream cancellation with or without a limit" {
  let source = Bytes::make(20000, b'X')
  for level in [0, 6] {
    let compressed = @flate.deflate_all(source, level~)
    for limit in [None, Some(source.length())] {
      for cancel_at in [1, 3] {
        let mut polls = 0
        let InflateError(kind, _) = @test.expect_error(() => {
          @flate.inflate_all(compressed, max_output?=limit, cancelled=() => {
            polls += 1
            polls == cancel_at
          })
        })
        @test.assert_eq(kind, Cancelled)
        @test.assert_eq(polls, cancel_at)
      }
    }
  }
}
