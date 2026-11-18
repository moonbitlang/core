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
#external
priv type Handle

///|
fn open(_path : String) -> Handle? raise {
  fail("file snapshot I/O currently supports only wasm")
}

///|
fn Handle::read(
  _self : Handle,
  _buffer : FixedArray[Byte],
  _offset : Int32,
  _len : Int32,
  _position : Int64,
) -> Int32 raise {
  fail("file snapshot I/O currently supports only wasm")
}

///|
fn Handle::close(_self : Handle) -> Unit raise {
  fail("file snapshot I/O currently supports only wasm")
}

///|
let file_host_is_unix : Bool = true
