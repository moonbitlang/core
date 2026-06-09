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
/// Return a debug object-template writer in debug builds.
///
/// Intended usage:
///
/// ```mbt nocheck
/// @debug.debug_object <? { "value": value }
/// ```
///
/// The object field value must implement `Debug`. In release builds this
/// value is `None`, so `<?` skips the template and does not evaluate
/// field values.
pub let debug_object : DebugObject? = Some({
  buffer: StringBuilder(),
  first: true,
})
