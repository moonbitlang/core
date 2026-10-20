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
#cfg(all(target="native", not(platform="windows")))
priv struct OsEnv(@c_buffer.Buffer)

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn get_curr_env() -> OsEnv = "moonbit_rt_get_curr_env"

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn OsEnv::length(self : OsEnv) -> Int32 = "moonbit_rt_env_block_length"

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn OsEnv::new(size : Int32) -> OsEnv = "moonbit_rt_allocate_env_block"

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn OsEnv::write_env_block(
  dst : OsEnv,
  block : OsEnv,
  start~ : Int32,
) -> Unit = "moonbit_rt_write_env_block"

///|
/// Add a new entry to the environment array at `index`.
/// Return the new index after adding the new entry.
/// The entry would be skipped if its key contain '\0'.
/// '\0' in the value would be silently truncated.
#cfg(all(target="native", not(platform="windows")))
#borrow(key, value)
extern "C" fn OsEnv::add_entry(
  dst : OsEnv,
  index : Int32,
  key~ : String,
  key_len~ : Int32,
  value~ : String,
  value_len~ : Int32,
) -> Int32 = "moonbit_rt_env_block_add_entry"

///|
#cfg(all(target="native", not(platform="windows")))
fn OsEnv::make(extra_env : Map[String, String], inherit_env~ : Bool) -> OsEnv {
  let extra_count = extra_env.length()
  let (curr_env, curr_env_len) = if inherit_env {
    let curr_env = get_curr_env()
    (Some(curr_env), curr_env.length())
  } else {
    (None, 0)
  }
  let env = OsEnv::new(curr_env_len + extra_count)
  for k, v in extra_env; i = 0 {
    let key_len = k.length()
    let value_len = v.length()
    continue env.add_entry(i, key=k, key_len~, value=v, value_len~)
  } nobreak {
    if curr_env is Some(curr_env) {
      env.write_env_block(curr_env, start=i)
    }
  }
  env
}

///|
#cfg(all(target="native", not(platform="windows")))
priv struct OsArgv(@c_buffer.Buffer)

///|
#cfg(all(target="native", not(platform="windows")))
extern "C" fn OsArgv::new(size : Int32) -> OsArgv = "moonbit_rt_make_argv_array"

///|
#cfg(all(target="native", not(platform="windows")))
#borrow(arg)
extern "C" fn OsArgv::add_encoded_entry(
  self : OsArgv,
  offset : Int32,
  arg : @os_string.OsString,
  arg_len~ : Int32 = arg.bytes_length(),
) -> Unit = "moonbit_rt_argv_array_add_encoded_entry"

///|
#cfg(all(target="native", not(platform="windows")))
#borrow(arg)
extern "C" fn OsArgv::add_entry(
  self : OsArgv,
  offset : Int32,
  arg : String,
  arg_len~ : Int32 = arg.length(),
) -> Unit = "moonbit_rt_argv_array_add_entry"

///|
#cfg(not(platform="windows"))
async fn raw_spawn_unix(
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
  let (stdin_child, stdin_parent) = stdin.init_stdin(context~)
  defer stdin.close(stdin_child)
  errdefer stdin_parent.close()
  let (stdout_parent, stdout_child) = stdout.init_stdout(context~)
  defer stdout.close(stdout_child)
  errdefer stdout_parent.close()
  let (stderr_parent, stderr_child) = stderr.init_stderr(
    stdout=stdout_child,
    context~,
  )
  defer stderr.close(stderr_child)
  errdefer stderr_parent.close()
  let cmd = @os_string.from_string(cmd)
  let cwd = match cwd {
    None => None
    Some(cwd) => Some(@os_string.from_string(cwd))
  }
  let argv = OsArgv::new(args.length() + 1)
  argv.add_encoded_entry(0, cmd)
  for i, arg in args {
    argv.add_entry(i + 1, arg)
  }
  // currently auto kill child process on hard termination is not supported on Unix,
  // so `is_orphan` makes no difference on actual spawning
  ignore(is_orphan)
  ignore(no_console_window)
  let proc = @event_loop.spawn_unix(
    cmd,
    argv.0,
    env=OsEnv::make(extra_env, inherit_env~).0,
    stdin=if stdin_child is Some(io) { io.fd() } else { @fd_util.invalid_fd },
    stdout=if stdout_child is Some(io) { io.fd() } else { @fd_util.invalid_fd },
    stderr=if stderr_child is Some(io) { io.fd() } else { @fd_util.invalid_fd },
    is_orphan~,
    cwd~,
    context~,
  )
  (proc, stdin_parent, stdout_parent, stderr_parent)
}

///|
#cfg(all(target="native", not(platform="windows")))
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

///|
let _ignored : Unit = ignore(@os_error.check_errno)
