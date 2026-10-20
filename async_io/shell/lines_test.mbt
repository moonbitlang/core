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
/// `each_line`'s framing rules are exercised by echoing a chosen payload
/// through the `cat` test program, so every byte of the child's output is
/// under the test's control on every platform.
async fn lines_of(payload : String, max_line_bytes? : Int32) -> Array[String] {
  let seen = []
  let code = @shell.Cmd(cat_prog.wait(), [], stdin=Text(payload)).each_line(
    line => seen.push(line),
    max_line_bytes?,
  )
  assert_eq(code, 0)
  seen
}

///|
async test "each_line delivers stdout incrementally, tail included" {
  // The unterminated trailing fragment is still a line.
  assert_eq(lines_of("alpha\nbeta\ngamma"), ["alpha", "beta", "gamma"])
}

///|
async test "CRLF terminates a line; a lone trailing CR is data" {
  // "a\r\n" and "b\r\n" are CRLF lines; the final "c\r" was never terminated,
  // so its CR is content rather than punctuation.
  assert_eq(lines_of("a\r\nb\r\nc\r"), ["a", "b", "c\r"])
}

///|
async test "the line cap counts content, not terminators" {
  // One byte of content under a one-byte cap: the CRLF is free.
  assert_eq(lines_of("a\r\n", max_line_bytes=1), ["a"])
  // A line exactly at the cap is allowed.
  assert_eq(lines_of("aaaaaaaa\n", max_line_bytes=8), ["aaaaaaaa"])
  // One byte over — terminated or not, delivered lines keep the promise.
  try lines_of("ab\r\n", max_line_bytes=1) |> ignore catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|OutputLimitExceeded(stream="stdout line", limit=1)
        ),
      )
  } noraise {
    _ => fail("expected the line limit to raise")
  }
  // A child that never emits a newline cannot grow the held line unboundedly.
  try lines_of("a".repeat(1000), max_line_bytes=64) |> ignore catch {
    err =>
      debug_inspect(
        err,
        content=(
          #|OutputLimitExceeded(stream="stdout line", limit=64)
        ),
      )
  } noraise {
    _ => fail("expected the line limit to raise")
  }
}

///|
async test "streaming is unbounded where capture is bounded" {
  // 2000 lines of 30 bytes: far over the 1 KiB capture limit used below, yet
  // each_line holds only one line at a time, so it delivers everything.
  let payload = "\{"a".repeat(29)}\n".repeat(2000)
  let lines = Ref(0)
  let bytes = Ref(0)
  let code = @shell.Cmd(cat_prog.wait(), [], stdin=Text(payload)).each_line(line => {
    lines.val += 1
    bytes.val += line.length()
  })
  inspect(code, content="0")
  inspect(lines.val, content="2000")
  inspect(bytes.val, content="58000")
  try
    @shell.Cmd(cat_prog.wait(), [], stdin=Text(payload)).output(
      max_output_bytes=1024,
    )
  catch {
    err => {
      let diagnostic = "\{Repr(err)}"
      assert_true(diagnostic.contains("OutputLimitExceeded"))
      assert_true(diagnostic.contains("limit=1024"))
    }
  } noraise {
    _ => fail("expected the output limit to raise")
  }
}
