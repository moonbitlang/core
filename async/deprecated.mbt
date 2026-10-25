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
pub impl Show for TimeoutError

///|
pub impl Show for TimeoutError with fn output(_self, logger) {
  logger <+ "TimeoutError"
}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
#doc(hidden)
pub extend TimeoutError with Show::{to_string}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
pub impl Show for TimerCancelled

///|
pub impl Show for TimerCancelled with fn output(_self, logger) {
  logger <+ "TimerCancelled"
}

///|
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
#doc(hidden)
pub extend TimerCancelled with Show::{to_string}

///|
#deprecated
#doc(hidden)
pub extend TimeoutError with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend TimeoutError with @json.ToJson::{to_json}

///|
#deprecated
#doc(hidden)
pub extend TimeoutError with Show::{output}

///|
#deprecated
#doc(hidden)
pub extend TimerCancelled with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend TimerCancelled with @json.ToJson::{to_json}

///|
#deprecated
#doc(hidden)
pub extend TimerCancelled with Show::{output}

///|
#deprecated
#doc(hidden)
pub extend WaitedTaskAlreadyCancelled with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend WaitedTaskAlreadyCancelled with @json.ToJson::{to_json}
