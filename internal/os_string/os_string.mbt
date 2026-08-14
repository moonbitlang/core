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
/// A string type using native encoding of current operating system.
///
/// On Windows, we use native `W` series unicode API,
/// which return string in UTF-16 directly,
/// so no need for extra encoding phase here.
///
/// Note: technically path etc. may be invalid UTF-16 on Windows,
///   but this should be extremely rare in practice.
///   If we need to fix this case, a validation or encoding phase can be added.
#cfg(any(not(target="native"), platform="windows"))
struct OsString(String)

///|
/// A string type using native encoding of current operating system.
///
/// On non-Windows platforms, path etc. are essentially binary data,
/// and we assume they contain UTF-8 encoded text here.
#cfg(all(target="native", not(platform="windows")))
struct OsString(Bytes)

///|
#cfg(any(not(target="native"), platform="windows"))
pub impl Show for OsString with fn to_string(self) {
  self.0
}

///|
#cfg(all(target="native", not(platform="windows")))
pub impl Show for OsString with fn to_string(self) {
  @utf8.decode_lossy(self.0)
}

///|
#deprecated
pub extend OsString with @builtin.Show::{output}

///|
pub extend OsString with @builtin.Show::{to_string}

///|
/// Create a `OsString` from a MoonBit `StringView`
#cfg(any(not(target="native"), platform="windows"))
pub fn OsString::from_string(str : StringView) -> OsString {
  OsString(str.to_owned())
}

///|
/// Create a `OsString` from a MoonBit `StringView`
#cfg(all(target="native", not(platform="windows")))
pub fn OsString::from_string(str : StringView) -> OsString {
  OsString(@utf8.encode(str))
}

///|
#cfg(any(not(target="native"), platform="windows"))
let _unused_import : Unit = ignore(@utf8.encode(""))
