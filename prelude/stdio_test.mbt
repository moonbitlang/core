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
#cfg(any(target="wasm", target="native"))
test "use stdio native/wasm" {
  let _ = stdin.fd()
  let _ = stdout.fd()
  let _ = stderr.fd()
}

///|
#cfg(any(target="wasm-gc", target="js"))
test "use stdio wasm-gc/js" {
  debug_inspect(
    @test.expect_error(() => stdin.fd()),
    content=(
      #|Failure("`@stdio.stdin` is not supported on wasm-gc/js backend")
    ),
  )
  debug_inspect(
    @test.expect_error(() => stdout.fd()),
    content=(
      #|Failure("`@stdio.stdout` and `@stdio.stderr` are not supported on wasm-gc/js backend")
    ),
  )
  debug_inspect(
    @test.expect_error(() => stderr.fd()),
    content=(
      #|Failure("`@stdio.stdout` and `@stdio.stderr` are not supported on wasm-gc/js backend")
    ),
  )
}
