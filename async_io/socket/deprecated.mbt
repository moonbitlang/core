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
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
pub impl Show for InvalidAddr

///|
pub impl Show for InvalidAddr with fn output(_self, logger) {
  logger <+ "InvalidAddr"
}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
#doc(hidden)
pub extend InvalidAddr with Show::{to_string}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
pub impl Show for ResolveHostnameError

///|
pub impl Show for ResolveHostnameError with fn output(self, logger) {
  match self {
    ResolveHostnameError(msg) =>
      logger <+ "ResolveHostnameError(\{@debug.Repr(msg)})"
  }
}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
#doc(hidden)
pub extend ResolveHostnameError with Show::{to_string}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
pub impl Show for IpProtocolPreference

///|
pub impl Show for IpProtocolPreference with fn output(self, logger) {
  match self {
    OnlyV4 => logger <+ "OnlyV4"
    OnlyV6 => logger <+ "OnlyV6"
    FavorV4 => logger <+ "FavorV4"
    FavorV6 => logger <+ "FavorV6"
    NoPreference => logger <+ "NoPreference"
  }
}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
#doc(hidden)
pub extend IpProtocolPreference with Show::{to_string}

///|
#deprecated
#doc(hidden)
pub extend Addr with Eq::{not_equal, equal}

///|
#deprecated
#doc(hidden)
pub extend Addr with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
#deprecated
#doc(hidden)
pub extend Addr with Hash::{hash, hash_combine}

///|
#deprecated
#doc(hidden)
pub extend Addr with Show::{output}

///|
#deprecated
#doc(hidden)
pub extend Addr with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend InvalidAddr with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend InvalidAddr with @json.ToJson::{to_json}

///|
#deprecated
#doc(hidden)
pub extend InvalidAddr with Show::{output}

///|
#deprecated
#doc(hidden)
pub extend ResolveHostnameError with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend ResolveHostnameError with @json.ToJson::{to_json}

///|
#deprecated
#doc(hidden)
pub extend ResolveHostnameError with Show::{output}

///|
#deprecated
#doc(hidden)
pub extend IpProtocolPreference with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend IpProtocolPreference with Show::{output}
