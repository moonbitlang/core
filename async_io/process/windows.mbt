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
#cfg(platform="windows")
priv struct OsEnv(@c_buffer.Buffer)

///|
#cfg(platform="windows")
extern "C" fn get_curr_env() -> OsEnv = "moonbit_rt_get_curr_env"

///|
#cfg(platform="windows")
extern "C" fn OsEnv::length(self : OsEnv) -> Int32 = "moonbit_rt_env_block_length"

///|
#cfg(platform="windows")
extern "C" fn OsEnv::new(size : Int32) -> OsEnv = "moonbit_rt_allocate_env_block"

///|
#cfg(platform="windows")
extern "C" fn OsEnv::write_env_block(
  dst : OsEnv,
  block : OsEnv,
  offset~ : Int32,
) -> Unit = "moonbit_rt_write_env_block"

///|
/// Return updated offset after writing the new entry.
/// The `dst` block should contain at least
/// `key_len + value_len + 2` characters of space after `offset`.
#cfg(platform="windows")
#borrow(key, value)
extern "C" fn OsEnv::add_entry(
  dst : OsEnv,
  offset : Int32,
  key~ : String,
  key_len~ : Int32,
  value~ : String,
  value_len~ : Int32,
) -> Int32 = "moonbit_rt_env_block_add_entry"

///|
#cfg(platform="windows")
fn OsEnv::make(extra_env : Map[String, String], inherit_env~ : Bool) -> OsEnv {
  let extra_env_len = for k, v in extra_env; acc = 0 {
    continue acc + k.length() + v.length() + 2
  } nobreak {
    acc
  }
  let (curr_env, curr_env_len) = if inherit_env {
    let curr_env = get_curr_env()
    (Some(curr_env), curr_env.length())
  } else {
    (None, 0)
  }
  let env = OsEnv::new(curr_env_len + extra_env_len)
  for k, v in extra_env; offset = 0 {
    let key_len = k.length()
    let value_len = v.length()
    continue env.add_entry(offset, key=k, key_len~, value=v, value_len~)
  } nobreak {
    if curr_env is Some(curr_env) {
      env.write_env_block(curr_env, offset~)
    }
  }
  env
}

///|
#cfg(any(target="wasm", platform="windows"))
fn StringBuilder::write_arg_with_windows_escape(
  builder : StringBuilder,
  arg : StringView,
) -> Unit {
  if arg is "" {
    builder.write("\"\"")
    return
  }
  // Do not add double quotes if it is unnecessary to do so.
  // This help with simple cases when the program is not using C argv syntax,
  // such as `rundll32.exe`.
  let need_quote = for char in arg.code_units() {
    if char is (' ' | '\t' | '"' | 0) {
      break true
    }
  } nobreak {
    false
  }
  if !need_quote {
    builder.write_stringview(arg)
    return
  }
  let mut segment_start = 0
  let mut index = 0
  let mut trailing_backslash = 0
  fn flush(skip : Int32) {
    if index > segment_start {
      builder.write_stringview(arg[segment_start:index - trailing_backslash])
      if trailing_backslash > 0 {
        builder.write_string(String::make(trailing_backslash * 2, '\\'))
      }
    }
    segment_start = index + skip
  }

  builder.write_char('"')
  while index < arg.length() {
    match arg.code_unit_at(index) {
      0 =>
        // truncate on NUL in input to prevent argv injection
        break
      '"' => {
        flush(1)
        builder <+ "\\\""
      }
      '\\' => trailing_backslash += 1
      _ => trailing_backslash = 0
    }
    index += 1
  }
  flush(0)
  builder.write_char('"')
}

///|
#cfg(any(target="wasm", platform="windows"))
async fn raw_spawn_windows(
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
  let cmd = match cmd {
    [.., '.', 'e' | 'E', 'x' | 'X', 'e' | 'E']
    | [.., '.', 'c' | 'C', 'o' | 'O', 'm' | 'M'] => cmd
    _ => cmd + ".exe"
  }
  let command_line = StringBuilder()
  command_line.write_arg_with_windows_escape(cmd)
  for arg in args {
    command_line..write_char(' ').write_arg_with_windows_escape(arg)
  }
  let command_line = @os_string.from_string(command_line.to_string())
  let cwd = match cwd {
    None => None
    Some(cwd) => Some(@os_string.from_string(cwd))
  }
  let proc = @event_loop.spawn_windows(
    command_line,
    env=OsEnv::make(extra_env, inherit_env~).0,
    stdin=if stdin_child is Some(io) { io.fd() } else { @fd_util.invalid_fd },
    stdout=if stdout_child is Some(io) { io.fd() } else { @fd_util.invalid_fd },
    stderr=if stderr_child is Some(io) { io.fd() } else { @fd_util.invalid_fd },
    cwd~,
    no_console_window~,
    is_orphan~,
    context~,
  )
  (proc, stdin_parent, stdout_parent, stderr_parent)
}

///|
#cfg(platform="windows")
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
}
