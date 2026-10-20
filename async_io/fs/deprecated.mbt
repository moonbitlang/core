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
#cfg(target="native")
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
pub impl Show for FileKind

///|
#cfg(target="native")
pub impl Show for FileKind with fn output(self, logger) {
  match self {
    Unknown => logger <+ "Unknown"
    Regular => logger <+ "Regular"
    Directory => logger <+ "Directory"
    SymLink => logger <+ "SymLink"
    Socket => logger <+ "Socket"
    Pipe => logger <+ "Pipe"
    BlockDevice => logger <+ "BlockDevice"
    CharDevice => logger <+ "CharDevice"
    Console => logger <+ "Console"
  }
}

///|
#cfg(target="native")
#deprecated("`Show` implementation for this type is deprecated, use `Debug` related API, or use `@debug.to_string` instead.")
#doc(hidden)
pub extend FileKind with Show::{to_string}

///|
#deprecated
#doc(hidden)
pub extend FileKind with Eq::{not_equal, equal}

///|
#deprecated
#doc(hidden)
pub extend FileKind with @debug.Debug::{to_repr}

///|
#cfg(target="native")
#deprecated
#doc(hidden)
pub extend FileKind with Show::{output}

///|
#deprecated
#doc(hidden)
pub extend FsEvent with Eq::{not_equal, equal}

///|
#deprecated
#doc(hidden)
pub extend FsEvent with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend Timestamp with Eq::{equal, not_equal}

///|
#deprecated
#doc(hidden)
pub extend Timestamp with Compare::{compare, op_lt, op_le, op_gt, op_ge}

///|
#deprecated
#doc(hidden)
pub extend Timestamp with @debug.Debug::{to_repr}

///|
#deprecated
#doc(hidden)
pub extend Timestamp with Sub::{sub}
