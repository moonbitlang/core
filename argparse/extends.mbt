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
pub extend FlagAction with Eq::{equal, not_equal}

///|
pub extend FlagAction with Show::{to_string}

///|
pub extend OptionAction with Eq::{equal, not_equal}

///|
pub extend OptionAction with Show::{to_string}

///|
pub extend ValueRange with Eq::{equal, not_equal}

///|
pub extend ValueRange with Show::{to_string}

///|
pub extend ValueSource with Eq::{equal, not_equal}

///|
pub extend ValueSource with Show::{to_string}

// --- deprecated: hidden from the generated interface ---

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend ArgGroup with @debug.Debug::{to_repr}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend Command with @debug.Debug::{to_repr}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend FlagAction with @debug.Debug::{to_repr}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend FlagAction with Show::{output}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend FlagArg with @debug.Debug::{to_repr}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend Matches with @debug.Debug::{to_repr}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend OptionAction with @debug.Debug::{to_repr}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend OptionAction with Show::{output}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend OptionArg with @debug.Debug::{to_repr}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend PositionArg with @debug.Debug::{to_repr}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend ValueRange with @debug.Debug::{to_repr}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend ValueRange with Show::{output}

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend ValueSource with @debug.Debug::{to_repr}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend ValueSource with Show::{output}
