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
let tmpdir_seed : @random.Rand = {
  let seed = @buffer.Buffer()
  let now = @event_loop.now()
  for _ in 0..<4 {
    seed.write_int64_le(now)
  }
  @random.Rand::chacha8(seed=seed.contents())
}

///|
extern "C" fn get_tmp_path_ffi() -> @c_buffer.Buffer = "moonbit_rt_get_tmp_path"

///|
let tmp_base_path : String = {
  let path = get_tmp_path_ffi()
  if path.is_null() {
    let err = @errno_util.errno_to_string(@errno_util.get_errno())
    abort("failed to obtain directory for temporary files: \{err}")
  }
  path.decode_as_os_string()
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
  for _ in 0..<@int.MAX_VALUE {
    let hasher = Hasher()
    hasher.combine_uint64(tmpdir_seed.uint64())
    hasher.combine_int64(@event_loop.now())
    let h = hasher.finalize().reinterpret_as_uint()
    let path = StringBuilder()
    path.write_string(tmp_base_path)
    path.write_stringview(prefix)
    path.write_char('.')
    path.write_string(@env_util.current_process.to_string())
    path.write_char('.')
    path.write_string(h.to_string(radix=16))
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
