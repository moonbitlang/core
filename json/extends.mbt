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
pub extend JsonDecodeError with Eq::{equal, not_equal}

///|
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
pub extend JsonPath with Eq::{equal, not_equal}

///|
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
pub extend ParseError with Eq::{equal, not_equal}

///|
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
pub extend Position with Eq::{equal, not_equal}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend JsonDecodeError with @debug.Debug::{to_repr}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend JsonPath with @debug.Debug::{to_repr}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend ParseError with @debug.Debug::{to_repr}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend Position with @debug.Debug::{to_repr}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend Replacer with @debug.Debug::{to_repr}

///|
#deprecated("Use the `FromJson` trait instead", skip_current_package=true)
pub extend Json with FromJson::{from_json}

///|
pub extend Json with Show::{to_string}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
pub extend Json with Show::{output}

///|
pub extend Json with ToJson::{to_json}

///|
pub extend JsonDecodeError with Show::{to_string}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
pub extend JsonDecodeError with Show::{output}

///|
pub extend JsonDecodeError with ToJson::{to_json}

///|
pub extend JsonPath with Show::{to_string}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
pub extend JsonPath with Show::{output}

///|
pub extend JsonPath with ToJson::{to_json}

///|
pub extend ParseError with Show::{to_string}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
pub extend ParseError with Show::{output}

///|
pub extend ParseError with ToJson::{to_json}

///|
pub extend Position with ToJson::{to_json}
