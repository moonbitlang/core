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
pub extend Category with Add::{add}

// --- deprecated: hidden from the generated interface ---

///|
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend Category with Eq::{equal, not_equal}

///|
#deprecated("Use `Hash::hash` / `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Category with Hash::{hash, hash_combine}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend Preference with @debug.Debug::{to_repr}

///|
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
#doc(hidden)
pub extend Preference with Eq::{equal, not_equal}

///|
#deprecated("Use `Hash::hash` / `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Preference with Hash::{hash, hash_combine}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend QuantifierMode with @debug.Debug::{to_repr}
