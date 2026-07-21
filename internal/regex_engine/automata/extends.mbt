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
pub extend Mark with Eq::{equal, not_equal}

///|
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
pub extend MarkSlotMap with Eq::{equal, not_equal}

///|
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
pub extend Slot with Eq::{equal, not_equal}

///|
#deprecated("Use `==` / `!=` instead", skip_current_package=true)
pub extend State with Eq::{equal, not_equal}

///|
pub extend Mark with Compare::{compare, op_ge, op_gt, op_le, op_lt}

///|
#deprecated("Use the `Hash` trait instead", skip_current_package=true)
pub extend Mark with Hash::{hash, hash_combine}

///|
#deprecated("Use the `Hash` trait instead", skip_current_package=true)
pub extend MarkSlotMap with Hash::{hash, hash_combine}

///|
#deprecated("Use the `Hash` trait instead", skip_current_package=true)
pub extend Slot with Hash::{hash, hash_combine}

///|
#deprecated("Use the `Hash` trait instead", skip_current_package=true)
pub extend State with Hash::{hash, hash_combine}
