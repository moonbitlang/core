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
#deprecated("Use the `Arbitrary` trait instead", skip_current_package=true)
pub extend BigInt with @quickcheck.Arbitrary::{arbitrary}

///|
#deprecated("Use the `Debug` trait instead", skip_current_package=true)
pub extend BigInt with @debug.Debug::{to_repr}

///|
#deprecated("Use the `FromJson` trait instead", skip_current_package=true)
pub extend BigInt with @json.FromJson::{from_json}

///|
pub extend BigInt with Default::{default}

///|
#deprecated("Use the `Hash` trait instead", skip_current_package=true)
pub extend BigInt with Hash::{hash, hash_combine}

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
pub extend BigInt with Show::{output}

///|
pub extend BigInt with ToJson::{to_json}
