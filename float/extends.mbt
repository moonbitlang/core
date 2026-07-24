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
pub extend Float with Add::{add}

///|
pub extend Float with Compare::{compare}

///|
pub extend Float with Div::{div}

///|
pub extend Float with Eq::{not_equal, equal}

///|
pub extend Float with Hash::{hash}

///|
pub extend Float with Mod::{mod}

///|
pub extend Float with Mul::{mul}

///|
pub extend Float with Neg::{neg}

///|
pub extend Float with Show::{to_string}

///|
pub extend Float with Sub::{sub}

// `Float::to_json` is promoted (not deprecated) because it has cross-package
// method-syntax callers (json/builtin tests); deprecating it would break the
// `--deny-warn` workspace build. It can be deprecated in a coordinated follow-up.

///|
pub extend Float with ToJson::{to_json}

// --- deprecated: hidden from the generated interface ---

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Float with Compare::{op_ge, op_gt, op_le, op_lt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Float with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Float with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend Float with Show::{output}
