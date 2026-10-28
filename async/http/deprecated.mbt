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
#cfg(any(target="native", target="wasm"))
#deprecated
#doc(hidden)
pub extend ProxyError with @debug.Debug::{to_repr}

///|
#cfg(any(target="native", target="wasm"))
#deprecated
#doc(hidden)
pub extend ProxyError with @json.ToJson::{to_json}

///|
#cfg(any(target="native", target="wasm"))
#deprecated
#doc(hidden)
pub extend HttpProtocolError with @debug.Debug::{to_repr}

///|
#cfg(any(target="native", target="wasm"))
#deprecated
#doc(hidden)
pub extend HttpProtocolError with @json.ToJson::{to_json}

///|
#deprecated
#doc(hidden)
pub extend RequestMethod with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend RequestMethod with Eq::{not_equal, equal}

///|
#deprecated
#doc(hidden)
pub extend RequestMethod with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
#deprecated
#doc(hidden)
pub extend RequestMethod with Hash::{hash, hash_combine}

///|
#deprecated
#doc(hidden)
pub extend RequestMethod with @json.ToJson::{to_json}

///|
#deprecated
#doc(hidden)
pub extend RequestMethod with Show::{output}

///|
#deprecated
#doc(hidden)
pub extend RequestHeader with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend RequestHeader with @json.ToJson::{to_json}

///|
#deprecated
#doc(hidden)
pub extend ResponseHeader with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend ResponseHeader with @json.ToJson::{to_json}

///|
#deprecated
#doc(hidden)
pub extend Protocol with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend Protocol with Eq::{not_equal, equal}

///|
#deprecated
#doc(hidden)
pub extend Protocol with Compare::{op_lt, op_le, op_ge, compare, op_gt}

///|
#deprecated
#doc(hidden)
pub extend Protocol with Hash::{hash, hash_combine}

///|
#deprecated
#doc(hidden)
pub extend Protocol with @json.ToJson::{to_json}

///|
#deprecated
#doc(hidden)
pub extend UriParseError with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend UriParseError with @json.ToJson::{to_json}

///|
#cfg(any(target="native", target="wasm"))
#deprecated
#doc(hidden)
pub extend IncorrectBodyLength with @debug.Debug::{to_repr}

///|
#cfg(any(target="native", target="wasm"))
#deprecated
#doc(hidden)
pub extend IncorrectBodyLength with @json.ToJson::{to_json}

///|
#deprecated
#doc(hidden)
pub extend Cookie with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend Cookie with @json.ToJson::{to_json}

///|
#deprecated
#doc(hidden)
pub extend InvalidMethod with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend InvalidMethod with @json.ToJson::{to_json}
