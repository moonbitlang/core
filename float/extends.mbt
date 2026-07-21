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
pub extend Float with Eq::{equal, not_equal}

///|
pub extend Float with Add::{add}

///|
pub extend Float with Compare::{compare, op_ge, op_gt, op_le, op_lt}

///|
pub extend Float with Default::{default}

///|
pub extend Float with Div::{div}

///|
#deprecated("Use the `Hash` trait instead", skip_current_package=true)
pub extend Float with Hash::{hash, hash_combine}

///|
pub extend Float with Mod::{mod}

///|
pub extend Float with Mul::{mul}

///|
pub extend Float with Neg::{neg}

///|
pub extend Float with Show::{to_string}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
pub extend Float with Show::{output}

///|
pub extend Float with Sub::{sub}

///|
pub extend Float with ToJson::{to_json}
