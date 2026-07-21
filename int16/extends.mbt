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
pub extend Int16 with Eq::{equal, not_equal}

///|
pub extend Int16 with Add::{add}

///|
pub extend Int16 with BitAnd::{land}

///|
pub extend Int16 with BitOr::{lor}

///|
pub extend Int16 with BitXOr::{lxor}

///|
pub extend Int16 with Compare::{compare, op_ge, op_gt, op_le, op_lt}

///|
pub extend Int16 with Default::{default}

///|
pub extend Int16 with Div::{div}

///|
#deprecated("Use the `Hash` trait instead", skip_current_package=true)
pub extend Int16 with Hash::{hash, hash_combine}

///|
pub extend Int16 with Mod::{mod}

///|
pub extend Int16 with Mul::{mul}

///|
pub extend Int16 with Neg::{neg}

///|
pub extend Int16 with Shl::{shl}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
pub extend Int16 with Show::{output}

///|
pub extend Int16 with Shr::{shr}

///|
pub extend Int16 with Sub::{sub}

///|
pub extend Int16 with ToJson::{to_json}
