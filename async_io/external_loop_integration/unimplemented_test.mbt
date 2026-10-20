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
#cfg(not(target="native"))
let _unused : Unit = {
  let _ : (@async_io.Mutex) -> Unit = ignore
  ignore(@event_loop.sleep)
  ignore(@external_loop_test.unimplemented)
}

///|
#cfg(target="wasm")
let _unused_wasm : Unit = {
  let _ : (@socket.Addr) -> Unit = ignore
  let _ : (@pipe.PipeRead) -> Unit = ignore
  ignore(@utf8.encode(""))
}

///|
#cfg(any(target="js", target="wasm-gc"))
let _unused_non_wasm : Unit = {
  ignore(@utf8.encode(""))
  ignore(@socket.unimplemented)
  ignore(@pipe.unimplemented)
}
