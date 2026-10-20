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
/// This package currently does not support JavaScript or wasm-gc backend
#cfg(not(any(target="native", target="wasm")))
#coverage.skip
pub let unimplemented : Unit = {
  ignore(@base64.encode(b""))
  ignore(@cmp.minimum(0, 0))
  ignore(@io.pipe)
  ignore(@bytes_util.ascii_to_string)
  ignore(@c_buffer.unimplemented)
  ignore(@event_loop.sleep)
  ignore(@io_buffer.new)
  ignore(@semaphore.Semaphore::acquire)
  ignore(@os_error.unimplemented)
  ignore(@utf8.encode(""))
  ignore(@fs.unimplemented)
  ignore(@errno_util.unimplemented)
  ignore((_ : @os_string.OsString) => ())
  ignore((_ : @lazy.Lazy[Int32]) => ())
  ignore((_ : @ref.Ref[Int32]) => ())
  ignore((_ : @debug.Repr) => ())
}

///|
#cfg(target="wasm")
#coverage.skip
let _ignore_unused_import : Unit = ignore(@utf8.encode(""))
