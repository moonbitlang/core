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
pub extend Int16 with Add::{add}

///|
pub extend Int16 with BitAnd::{land}

///|
pub extend Int16 with BitOr::{lor}

///|
pub extend Int16 with BitXOr::{lxor}

///|
pub extend Int16 with Compare::{compare}

///|
pub extend Int16 with Div::{div}

///|
pub extend Int16 with Eq::{equal, not_equal}

///|
pub extend Int16 with Hash::{hash}

///|
pub extend Int16 with Mod::{mod}

///|
pub extend Int16 with Mul::{mul}

///|
pub extend Int16 with Neg::{neg}

///|
pub extend Int16 with Shl::{shl}

///|
pub extend Int16 with Shr::{shr}

///|
pub extend Int16 with Sub::{sub}

// --- deprecated: hidden from the generated interface ---

///|
#deprecated("Use the comparison operators (`<`, `<=`, `>=`, `>`) instead", skip_current_package=true)
#doc(hidden)
pub extend Int16 with Compare::{op_ge, op_gt, op_le, op_lt}

///|
#deprecated("Use `Default::default` instead", skip_current_package=true)
#doc(hidden)
pub extend Int16 with Default::{default}

///|
#deprecated("Use `Hash::hash_combine` instead", skip_current_package=true)
#doc(hidden)
pub extend Int16 with Hash::{hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend Int16 with Show::{output}

///|
#deprecated("Use `@json.to_json` instead", skip_current_package=true)
#doc(hidden)
pub extend Int16 with ToJson::{to_json}
