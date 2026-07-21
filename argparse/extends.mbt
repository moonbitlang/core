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
pub extend FlagAction with Eq::{equal, not_equal}

///|
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
pub extend OptionAction with Eq::{equal, not_equal}

///|
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
pub extend ValueRange with Eq::{equal, not_equal}

///|
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
pub extend ValueSource with Eq::{equal, not_equal}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend ArgGroup with @debug.Debug::{to_repr}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend Command with @debug.Debug::{to_repr}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend FlagAction with @debug.Debug::{to_repr}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend FlagArg with @debug.Debug::{to_repr}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend Matches with @debug.Debug::{to_repr}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend OptionAction with @debug.Debug::{to_repr}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend OptionArg with @debug.Debug::{to_repr}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend PositionArg with @debug.Debug::{to_repr}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend ValueRange with @debug.Debug::{to_repr}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend ValueSource with @debug.Debug::{to_repr}

///|
pub extend FlagAction with Show::{to_string}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
pub extend FlagAction with Show::{output}

///|
pub extend OptionAction with Show::{to_string}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
pub extend OptionAction with Show::{output}

///|
pub extend ValueRange with Show::{to_string}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
pub extend ValueRange with Show::{output}

///|
pub extend ValueSource with Show::{to_string}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
pub extend ValueSource with Show::{output}
