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
#unsafe_skip_stub_check
fn ms_since_epoch() -> UInt64 = "moonbitlang/async" "time/get_ms_since_epoch"

///|
let tmpdir_seed : @random.Rand = {
  let seed = @buffer.Buffer()
  let now = ms_since_epoch()
  for _ in 0..<4 {
    seed.write_uint64_le(now)
  }
  @random.Rand::chacha8(seed=seed.contents())
}

///|
#unsafe_skip_stub_check
fn get_tmp_path_len_ffi() -> Int32 = "moonbitlang/async" "fs/get_tmp_path_len"

///|
#unsafe_skip_stub_check
#borrow(path)
fn get_tmp_path_ffi(path : String, len : Int32) -> Int32 = "moonbitlang/async" "fs/get_tmp_path"

///|
/// Wasm can't access exported memory during initialization,
/// so we have to use a function to get the tmp base path.
fn get_tmp_base_path() -> String {
  let len = get_tmp_path_len_ffi()
  if len < 0 {
    let err = @errno_util.errno_to_string(@errno_util.get_errno())
    abort("failed to obtain directory for temporary files: \{err}")
  }
  let path = String::make(len, '\u{0}')
  if get_tmp_path_ffi(path, len) < 0 {
    let err = @errno_util.errno_to_string(@errno_util.get_errno())
    abort("failed to obtain directory for temporary files: \{err}")
  }

  path
}

///|
/// Create a temporary directory in the system-specific temporary file storage
/// (such as `/tmp/`) with prefix `prefix`.
/// `tmpdir` force-create the directory atomically, so it never reuse directory.
///
/// The format of the directory name is:
///
///   <prefix>.<current_pid>.<random_number>
///
/// The random number part cotains 32bits of information,
/// so at most 2^32 temporary directories can be created for every process.
/// However, due to collision, `tmpdir` will slow down
/// when a lot of temporary directories are created by the same process.
///
/// The temporary directory name is not cryptographically secure.
pub async fn tmpdir(prefix~ : StringView) -> String {
  let tmp_base_path = get_tmp_base_path()
  for _ in 0..<@int.MAX_VALUE {
    let hasher = Hasher()
    hasher.combine_uint64(tmpdir_seed.uint64())
    hasher.combine_uint64(ms_since_epoch())
    let h = hasher.finalize().reinterpret_as_uint()
    let path = StringBuilder()
    path <+
      "\{tmp_base_path}\{prefix}.\{@env_util.current_process}.\{h.to_string(radix=16)}"
    let path = path.to_string()
    try @event_loop.mkdir(path, mode=0o700, context="@fs.tmpdir()") catch {
      @os_error.OsError(AlreadyExists, ..) => ()
      err => raise err
    } noraise {
      _ => return path
    }
  }
  raise Failure::Failure("failed to create tmp directory: too many attempts")
}
