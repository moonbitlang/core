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
priv struct OsArgv(UInt64)

///|
priv struct OsEnv(UInt64)

///|
#unsafe_skip_stub_check
fn OsEnv::new(inherit_env : Bool) -> OsEnv = "moonbitlang/async" "process/make_env"

///|
#unsafe_skip_stub_check
#borrow(key, value)
fn OsEnv::add_entry(
  dst : OsEnv,
  key~ : String,
  key_len~ : Int32,
  value~ : String,
  value_len~ : Int32,
) -> Unit = "moonbitlang/async" "process/env_add_entry"

///|
fn OsEnv::make(extra_env : Map[String, String], inherit_env~ : Bool) -> OsEnv {
  let env = OsEnv::new(inherit_env)
  for k, v in extra_env {
    let key_len = k.length()
    let value_len = v.length()
    env.add_entry(key=k, key_len~, value=v, value_len~)
  }
  env
}

///|
#unsafe_skip_stub_check
fn OsArgv::new(size : Int32) -> OsArgv = "moonbitlang/async" "process/make_argv_array/unix"

///|
#unsafe_skip_stub_check
#borrow(arg)
fn OsArgv::add_encoded_entry(
  self : OsArgv,
  offset : Int32,
  arg : @os_string.OsString,
  arg_len~ : Int32 = arg.to_string().length(),
) -> Unit = "moonbitlang/async" "process/argv_array_add_encoded_entry/unix"

///|
#unsafe_skip_stub_check
#borrow(arg)
fn OsArgv::add_entry(
  self : OsArgv,
  offset : Int32,
  arg : String,
  arg_len~ : Int32 = arg.length(),
) -> Unit = "moonbitlang/async" "process/argv_array_add_entry/unix"

///|
async fn raw_spawn(
  cmd : StringView,
  args : ArrayView[String],
  extra_env~ : Map[String, String],
  inherit_env~ : Bool,
  stdin~ : &ProcessInput,
  stdout~ : &ProcessOutput,
  stderr~ : &ProcessOutput,
  cwd~ : StringView?,
  no_console_window~ : Bool,
  is_orphan~ : Bool,
  context~ : String,
) -> (@event_loop.Process, WriteToProcess, ReadFromProcess, ReadFromProcess) {
  match @event_loop.platform {
    Windows =>
      raw_spawn_windows(
        cmd,
        args,
        extra_env~,
        inherit_env~,
        stdin~,
        stdout~,
        stderr~,
        cwd~,
        no_console_window~,
        is_orphan~,
        context~,
      )
    Linux | MacOS =>
      raw_spawn_unix(
        cmd,
        args,
        extra_env~,
        inherit_env~,
        stdin~,
        stdout~,
        stderr~,
        cwd~,
        no_console_window~,
        is_orphan~,
        context~,
      )
  }
}
