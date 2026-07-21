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
// `write_substring` is intentionally omitted here: it is a deprecated `Logger`
// method, and `extend`ing it from this (cross-)package would reference a
// deprecated method (an error). Instead it is shadowed by a manual
// `#deprecated fn Buffer::write_substring` in buffer.mbt, which clears the
// promotion without needing a package-level exemption.
pub extend Buffer with Logger::{
  write,
  write_char,
  write_string,
  write_string_interpolation,
  write_view,
}

///|
pub extend Buffer with Show::{to_string}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
pub extend Buffer with Show::{output}
