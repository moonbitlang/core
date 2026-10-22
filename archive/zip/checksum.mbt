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
/// Checksum an entry while polling ZIP's cancellation callback at entry,
/// between 4 KiB chunks, and after the final chunk.
fn crc32_cancellable(
  bytes : BytesView,
  cancelled~ : () -> Bool,
) -> UInt32 raise ZipError {
  check_cancelled(cancelled)
  let crc = @checksum.Crc32()
  let mut start = 0
  while start < bytes.length() {
    if start > 0 {
      check_cancelled(cancelled)
    }
    let end = start + (bytes.length() - start).min(4096)
    crc.update(bytes[start:end])
    start = end
  }
  check_cancelled(cancelled)
  crc.finish()
}
