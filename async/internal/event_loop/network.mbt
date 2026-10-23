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
/// Resolved address information for a host name
#cfg(target="native")
#external
pub type AddrInfo

///|
/// Resolved address information for a host name
#cfg(target="wasm")
pub struct AddrInfo(UInt64)

///|
/// Resolve a host name and return the list of IP address for the host name.
/// `getaddrinfo` specific errors are returned via `Err(..)`,
/// while other generic system errors are returned via `raise @os_error.OsError(..)`.
pub async fn getaddrinfo(
  host : StringView,
  context~ : String,
) -> Result[AddrInfo, String] {
  @coroutine.check_cancellation()
  let host_bytes = @os_string.from_string(host)
  let job = Job::getaddrinfo(host_bytes)
  let mut result = Err("")
  let mut terminated = false
  defer {
    terminated = true
  }
  // `getaddrinfo` cannot be cancelled,
  // but it always does not have any critical side effect.
  // So our strategy here is to keep `getaddrinfo` running on cancellation,
  // let a background task wait for its completion and perform cleanup, 
  // while not waiting for the result in the main task
  try
    @coroutine.spawn(() => {
      defer job.free()
      let ret = perform_job_in_worker(job, context~) catch {
        @os_error.OsError(_) as err =>
          raise err.wrap_context(context => "\{context}: \{host.escape()}")
        err => raise err
      }
      // if the outer `getaddrinfo` call already terminated,
      // we should not extract the result from the job,
      // instead we should let `job.free` free the result.
      guard !terminated else { return }
      if ret != 0 {
        result = Err(gai_error_to_string(ret))
      } else {
        result = Ok(job.get_getaddrinfo_result())
      }
    }).wait()
  catch {
    _ if result is Ok(_) =>
      // corner case: if the job happens to complete at the same tick as cancellation,
      // as long as `get_getaddrinfo_result` is called,
      // we should treat `getaddrinfo` as successful anyway,
      // otherwise the result will leak
      return result
    err => raise err
  } noraise {
    _ => result
  }
}

///|
/// Bind a socket to the specified local address.
/// Although `bind` does not need to perform network IO,
/// in practice it can take quite some time, blocking the main thread.
/// So here we dispatch `bind` to the thread pool.
pub async fn IoHandle::bind(
  handle : IoHandle,
  addr : Bytes,
  context~ : String,
) -> Unit {
  @coroutine.check_cancellation()
  let job = Job::bind(handle.fd, addr)
  defer job.free()
  ignore(perform_job_in_worker(job, context~))
}
