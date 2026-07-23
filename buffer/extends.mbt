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

// --- promoted: kept as regular methods (blessed public API) ---

///|
pub extend Buffer with Logger::{
  write_view,
  write_string,
  write_string_interpolation,
  write_char,
  write,
}

// `Logger::write_substring` is itself deprecated, so it cannot be named in an
// `extend` (E0020). Define the promoted method manually instead -- it clears
// E0079, stays callable, and is deprecated in step with the trait method.

///|
#deprecated("use `write_view` instead", skip_current_package=true)
#doc(hidden)
pub fn Buffer::write_substring(
  self : Buffer,
  value : String,
  start : Int,
  len : Int,
) -> Unit {
  self.write_view(value[start:start + len])
}

///|
pub extend Buffer with Show::{to_string}

// --- deprecated: hidden from the generated interface ---

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend Buffer with Show::{output}
