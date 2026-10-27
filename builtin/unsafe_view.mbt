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
/// Creates a view without checking or clamping bounds.
/// Offsets are relative to this container; both labeled bounds are required.
///
/// # Safety
///
/// The caller must ensure `0 <= start <= end <= self.length()`.
/// Invalid bounds can cause undefined behavior; a panic is not guaranteed.
/// Use `Array::exact_view` to validate bounds, or `Array::clamped_view`
/// (also available as `self[start:end]`) to clamp them.
pub fn[T] Array::unsafe_view(
  self : Array[T],
  start~ : Int32,
  end~ : Int32,
) -> ArrayView[T] {
  ArrayView::make(self.buffer(), start, end - start)
}

///|
/// Creates a view without checking or clamping bounds.
/// Offsets are relative to this view; both labeled bounds are required.
///
/// # Safety
///
/// The caller must ensure `0 <= start <= end <= self.length()`.
/// Invalid bounds can cause undefined behavior; a panic is not guaranteed.
/// Use `ArrayView::exact_view` to validate bounds, or `ArrayView::clamped_view`
/// (also available as `self[start:end]`) to clamp them.
pub fn[T] ArrayView::unsafe_view(
  self : ArrayView[T],
  start~ : Int32,
  end~ : Int32,
) -> ArrayView[T] {
  ArrayView::make(self.buf(), self.start() + start, end - start)
}

///|
/// Creates a view without checking or clamping bounds.
/// Offsets are relative to this container; both labeled bounds are required.
///
/// # Safety
///
/// The caller must ensure `0 <= start <= end <= self.length()`.
/// Invalid bounds can cause undefined behavior; a panic is not guaranteed.
/// Use `FixedArray::exact_view` to validate bounds, or `FixedArray::clamped_view`
/// (also available as `self[start:end]`) to clamp them.
pub fn[T] FixedArray::unsafe_view(
  self : FixedArray[T],
  start~ : Int32,
  end~ : Int32,
) -> ArrayView[T] {
  ArrayView::make(
    unsafe_cast_fixedarray_to_uninitializedarray(self),
    start,
    end - start,
  )
}

///|
/// Creates a view without checking or clamping bounds.
/// Offsets are relative to this container; both labeled bounds are required.
///
/// # Safety
///
/// The caller must ensure `0 <= start <= end <= self.length()`.
/// Invalid bounds can cause undefined behavior; a panic is not guaranteed.
/// Use `ReadOnlyArray::exact_view` to validate bounds, or `ReadOnlyArray::clamped_view`
/// (also available as `self[start:end]`) to clamp them.
pub fn[T] ReadOnlyArray::unsafe_view(
  self : ReadOnlyArray[T],
  start~ : Int32,
  end~ : Int32,
) -> ArrayView[T] {
  self.unsafe_reinterpret_to_fixed_array().unsafe_view(start~, end~)
}

///|
/// Creates a view without checking or clamping bounds.
/// Offsets are relative to this view; both labeled bounds are required.
///
/// # Safety
///
/// The caller must ensure `0 <= start <= end <= self.length()`.
/// Invalid bounds can cause undefined behavior; a panic is not guaranteed.
/// Use `MutArrayView::exact_view` to validate bounds, or `MutArrayView::clamped_view`
/// (also available as `self[start:end]`) to clamp them.
pub fn[T] MutArrayView::unsafe_view(
  self : MutArrayView[T],
  start~ : Int32,
  end~ : Int32,
) -> ArrayView[T] {
  ArrayView::make(self.buf(), self.start() + start, end - start)
}

///|
/// Creates a view without checking or clamping bounds.
/// Offsets are relative to this container; both labeled bounds are required.
///
/// # Safety
///
/// The caller must ensure `0 <= start <= end <= self.length()`.
/// Invalid bounds can cause undefined behavior; a panic is not guaranteed.
/// Every element that will be read through the returned view must already
/// be initialized.
///
/// Use `UninitializedArray::exact_view` to validate bounds, or `UninitializedArray::clamped_view`
/// (also available as `self[start:end]`) to clamp them.
pub fn[T] UninitializedArray::unsafe_view(
  self : UninitializedArray[T],
  start~ : Int32,
  end~ : Int32,
) -> ArrayView[T] {
  ArrayView::make(self, start, end - start)
}

///|
/// Creates a view without checking or clamping bounds.
/// Offsets are relative to this container; both labeled bounds are required.
///
/// # Safety
///
/// The caller must ensure `0 <= start <= end <= self.length()`.
/// Invalid bounds can cause undefined behavior; a panic is not guaranteed.
/// Use `Bytes::exact_view` to validate bounds, or `Bytes::clamped_view`
/// (also available as `self[start:end]`) to clamp them.
pub fn Bytes::unsafe_view(
  self : Bytes,
  start~ : Int32,
  end~ : Int32,
) -> BytesView {
  BytesView::make(self, start, end - start)
}

///|
/// Creates a view without checking or clamping bounds.
/// Offsets are relative to this view; both labeled bounds are required.
///
/// # Safety
///
/// The caller must ensure `0 <= start <= end <= self.length()`.
/// Invalid bounds can cause undefined behavior; a panic is not guaranteed.
/// Use `BytesView::exact_view` to validate bounds, or `BytesView::clamped_view`
/// (also available as `self[start:end]`) to clamp them.
pub fn BytesView::unsafe_view(
  self : BytesView,
  start~ : Int32,
  end~ : Int32,
) -> BytesView {
  BytesView::make(self.bytes(), self.start() + start, end - start)
}

///|
/// Creates a view without checking or clamping bounds.
/// Offsets are relative to this container; both labeled bounds are required.
///
/// # Safety
///
/// The caller must ensure `0 <= start <= end <= self.length()`.
/// Invalid bounds can cause undefined behavior; a panic is not guaranteed.
/// Offsets count UTF-16 code units. Surrogate boundaries are neither checked
/// nor adjusted: raw code-unit algorithms may preserve split pairs. The caller
/// must ensure well-formed UTF-16 before using character-based APIs.
///
/// Use `String::exact_view` to validate bounds, or `String::clamped_view`
/// (also available as `self[start:end]`) to clamp them.
pub fn String::unsafe_view(
  self : String,
  start~ : Int32,
  end~ : Int32,
) -> StringView {
  StringView::make_view(self, start, end)
}

///|
/// Creates a view without checking or clamping bounds.
/// Offsets are relative to this view; both labeled bounds are required.
///
/// # Safety
///
/// The caller must ensure `0 <= start <= end <= self.length()`.
/// Invalid bounds can cause undefined behavior; a panic is not guaranteed.
/// Offsets count UTF-16 code units. Surrogate boundaries are neither checked
/// nor adjusted: raw code-unit algorithms may preserve split pairs. The caller
/// must ensure well-formed UTF-16 before using character-based APIs.
///
/// Use `StringView::exact_view` to validate bounds, or `StringView::clamped_view`
/// (also available as `self[start:end]`) to clamp them.
pub fn StringView::unsafe_view(
  self : StringView,
  start~ : Int32,
  end~ : Int32,
) -> StringView {
  StringView::make_view(self.str(), self.start() + start, self.start() + end)
}
