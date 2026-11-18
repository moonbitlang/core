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
/// Get the runtime command line, including its executable prefix.
/// On JavaScript/Node this is `process.argv`, including both the Node executable
/// and the script path. JavaScript environments without `process.argv` return
/// an empty array. Other targets use the host-provided argument list.
/// On linear Wasm, uses WASIp1 and panics on host errors. JS WASI hosts
/// (including moonrun) require completed instantiation: do not call from
/// `fn init` or top-level initializers.
pub fn args() -> Array[String] {
  get_cli_args_internal()
}

///|
/// Terminate the process with the given exit code. Zero indicates success;
/// a nonzero code indicates failure. This function never returns.
///
/// On JavaScript, uses `process.exit` and panics if it is unavailable.
/// WebAssembly hosts must provide WASI `proc_exit` for `wasm` or
/// `__moonbit_sys_unstable.exit` for `wasm-gc`.
pub fn[T] exit(code : Int32) -> T {
  exit_internal(code)
  panic()
}

///|
/// Get the current time in milliseconds since the Unix epoch.
pub fn now() -> UInt64 {
  now_internal()
}

///|
/// Get the current working directory. On some platforms, this may return `None` if the current directory cannot be determined.
pub fn current_dir() -> String? {
  current_dir_internal()
}

///|
/// Get an environment variable by key. Returns `None` if the key does not exist.
/// On linear Wasm, reads the full WASIp1 environment; see `args` for host requirements.
pub fn get_env_var(key : String) -> String? {
  get_env_var_internal(key)
}

///|
/// Get all environment variables.
/// On linear Wasm, uses WASIp1; see `args` for host requirements.
pub fn get_env_vars() -> Map[String, String] {
  get_env_vars_internal()
}

///|
/// Set an environment variable for the current process.
///
/// On JavaScript, this writes to `process.env`. If `process.env` is unavailable
/// (for example, in a browser), it does nothing, and `get_env_var` keeps
/// returning `None`.
/// On Wasm, requires Moonrun's custom imports.
pub fn set_env_var(key : String, value : String) -> Unit {
  set_env_var_internal(key, value)
}

///|
/// Unset an environment variable for the current process.
///
/// On JavaScript, this deletes the key from `process.env`. If `process.env` is
/// unavailable (for example, in a browser), it does nothing.
/// On Wasm, requires Moonrun's custom imports.
pub fn unset_env_var(key : String) -> Unit {
  unset_env_var_internal(key)
}

///|
/// Get `n` random bytes from a platform entropy source.
/// Returns `Some(bytes)` when the platform can provide secure random bytes,
/// and `None` when entropy is unsupported or the host reports a failure.
/// For `n <= 0`, probes availability and returns `Some(b"")` on success.
pub fn rand(n : Int32) -> Bytes? {
  if n <= 0 {
    let probe : FixedArray[Byte] = FixedArray::make(1, b'\x00')
    return if rand_internal(probe) { Some(b"") } else { None }
  }
  let buf : FixedArray[Byte] = FixedArray::make(n, b'\x00')
  if rand_internal(buf) {
    Some(Bytes::from_array(buf))
  } else {
    None
  }
}
