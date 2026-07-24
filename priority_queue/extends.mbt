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

// --- deprecated: hidden from the generated interface ---

///|
#deprecated("Use `@quickcheck.Arbitrary::arbitrary` instead", skip_current_package=true)
#doc(hidden)
pub extend PriorityQueue with @quickcheck.Arbitrary::{arbitrary}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend PriorityQueue with Default::{default}

///|
#deprecated("Use `@debug.Debug` instead of `Show` for collections", skip_current_package=true)
#doc(hidden)
pub extend PriorityQueue with Show::{output, to_string}

///|
#deprecated("Use `@json.to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend PriorityQueue with ToJson::{to_json}
