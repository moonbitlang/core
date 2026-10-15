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
// Return an entirely initialized, independent buffer. Only full-buffer views
// can transfer storage: a prefix may include unused/uninitialized capacity and
// a suffix has a different base pointer. All other cases retain the copy path.
#cfg(any(target="native", target="wasm"))
#owned(self)
fn[T] ArrayView::copy_or_reuse_buffer(
  self : ArrayView[T],
) -> UninitializedArray[T] {
  let len = self.length()
  let start = self.start()
  let buf = self.buf()
  // Consume the owned view before checking its buffer. A borrowed caller or
  // any surviving array/view must still own another reference and force a copy.
  if start == 0 && len == buf.length() && unsafe_is_unique_ref(buf) {
    return buf
  }
  UninitializedArray::unsafe_make_and_blit(buf, len, start, 0, len)
}

///|
// Only valid when every slot is initialized, as guaranteed by the helper above.
#cfg(any(target="native", target="wasm"))
fn[T] UninitializedArray::unsafe_to_fixed_array(
  self : UninitializedArray[T],
) -> FixedArray[T] = "%identity"
