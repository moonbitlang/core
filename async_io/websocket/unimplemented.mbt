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
/// This package currently does not support JavaScript or Wasm GC backends.
#cfg(any(target="js", target="wasm-gc"))
#coverage.skip
pub let unimplemented : Unit = {
  ignore(@cmp.minimum(0, 0))
  let _ : (@random.Rand) -> Unit = ignore
  ignore(@base64.encode(b""))
  ignore(@io.pipe)
  ignore(@semaphore.Semaphore::release)
  ignore(@tls.unimplemented)
  ignore(@http.unimplemented)
  ignore(@coroutine.Coroutine::wake)
  ignore(@utf8.encode(""))
  ignore((_ : @debug.Repr) => ())
}
