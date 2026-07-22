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

// --- promoted: kept as regular methods ---

///|
pub extend Deque with Add::{add}

///|
pub extend Deque with Compare::{compare}

// --- deprecated: hidden from the generated interface ---

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Deque with Compare::{op_ge, op_gt, op_le, op_lt}

///|
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend Deque with Eq::{equal, not_equal}

///|
#deprecated("Use `@json.from_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Deque with @json.FromJson::{from_json}

///|
#deprecated("Use `Hash::hash` / `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Deque with Hash::{hash, hash_combine}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend Deque with Show::{output, to_string}

///|
#deprecated("Use `@json.to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Deque with ToJson::{to_json}
