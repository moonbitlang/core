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
#cfg(target="wasm")
fn snapshot_matches(
  actual : String,
  filename : String,
  location : String,
) -> Bool raise {
  guard @json.parse(location) is { "filename": String(source), .. } else {
    fail("invalid snapshot source location")
  }
  @snapshot_io.matches(source, filename, @utf8.encode(actual))
}

///|
#cfg(not(target="wasm"))
#warnings("-unused_error_type")
fn snapshot_matches(
  _actual : String,
  _filename : String,
  _location : String,
) -> Bool raise {
  // Keep the existing Moon protocol on targets without synchronous host I/O.
  false
}
