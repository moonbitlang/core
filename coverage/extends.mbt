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
// `CoverageCounter` is a collection, so per AGENTS.md its `Show::to_string`
// is not promoted. The policy would point callers at `@debug.Debug`, but this
// package is injected into `builtin` under `--enable-coverage`, so it cannot
// depend on `@debug`; `Show` stays the only way to print it.
#deprecated("`CoverageCounter` is a collection with no canonical string form; use string interpolation or `Show::to_string` via the trait instead", skip_current_package=true)
#doc(hidden)
pub extend CoverageCounter with Show::{output, to_string}
