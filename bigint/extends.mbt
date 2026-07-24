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

// --- promoted: kept as regular methods (blessed public API) ---

///|
pub extend BigInt with Add::{add}

///|
pub extend BigInt with BitAnd::{land}

///|
pub extend BigInt with BitOr::{lor}

///|
pub extend BigInt with BitXOr::{lxor}

///|
pub extend BigInt with Compare::{compare}

///|
pub extend BigInt with Div::{div}

///|
pub extend BigInt with Eq::{equal, not_equal}

///|
pub extend BigInt with Hash::{hash}

///|
pub extend BigInt with Mod::{mod}

///|
pub extend BigInt with Mul::{mul}

///|
pub extend BigInt with Neg::{neg}

///|
pub extend BigInt with Sub::{sub}

// `BigInt::to_json` is promoted (not deprecated): it has cross-package method-syntax
// callers (builtin/json tests); deprecating it would break `--deny-warn`.

///|
pub extend BigInt with ToJson::{to_json}

// --- deprecated: hidden from the generated interface ---

///|
#deprecated("Use `Debug::to_repr` instead", skip_current_package=true)
#doc(hidden)
pub extend BigInt with @debug.Debug::{to_repr}

///|
#deprecated("Use `@json.from_json` instead", skip_current_package=true)
#doc(hidden)
pub extend BigInt with @json.FromJson::{from_json}

///|
#deprecated("Use `@quickcheck.Arbitrary::arbitrary` instead", skip_current_package=true)
#doc(hidden)
pub extend BigInt with @quickcheck.Arbitrary::{arbitrary}

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend BigInt with Compare::{op_lt, op_le, op_ge, op_gt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend BigInt with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend BigInt with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend BigInt with Show::{output}
