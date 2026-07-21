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
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
pub extend Category with Eq::{equal, not_equal}

///|
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
pub extend Preference with Eq::{equal, not_equal}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend Preference with @debug.Debug::{to_repr}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend QuantifierMode with @debug.Debug::{to_repr}

///|
pub extend Category with Add::{add}

///|
#deprecated("Use the `Hash` trait instead", skip_current_package=true)
pub extend Category with Hash::{hash, hash_combine}

///|
#deprecated("Use the `Hash` trait instead", skip_current_package=true)
pub extend Preference with Hash::{hash, hash_combine}
