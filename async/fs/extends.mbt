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
pub extend FileKind with Eq::{equal}

///|
pub extend FsEvent with Eq::{equal}

///|
pub extend Timestamp with Eq::{equal}

///|
pub extend Timestamp with Compare::{compare}

///|
pub extend Timestamp with Hash::{hash}

///|
pub extend Timestamp with Sub::{sub}

///|
pub extend FileView with @io.BinaryReader::{
  read_into,
  read,
  read_at_least,
  peek,
  peek_at_least,
  read_exactly,
  drop_exactly,
  peek_exactly,
  read_all,
  drop_all,
  read_until,
  peek_until,
}

///|
pub extend FileView with @io.BinaryWriter::{write, write_reader}
