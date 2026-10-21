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
#cfg(not(any(target="native", target="wasm")))
let _ignore_unused_import : Unit = {
  ignore(@utf8.encode(""))
  ignore(@async_io.sleep)
  ignore(@socket.unimplemented)
  ignore((f : async () -> Unit) => @test.assert_raise_async(f))
}

///|
#cfg(target="wasm")
let _ignore_pipe_import : Unit = ignore(@pipe.pipe)

///|
#cfg(not(any(target="native", target="wasm")))
let _ignore_pipe_import : Unit = ignore(@pipe.unimplemented)
