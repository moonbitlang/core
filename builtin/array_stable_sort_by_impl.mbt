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
// Keep comparator-based helpers separate from timsort so stable_sort retains
// direct trait comparisons without callback dispatch in its inner loops.
fn[T] timsort_by(arr : MutArrayView[T], cmp : (T, T) -> Int32) -> Unit {
  let max_insertion = 20
  let len = arr.length()
  if len <= max_insertion {
    MutArrayView::insertion_sort_by(arr, cmp)
    return
  }
  let runs : Array[TimSortRun] = []
  for start = 0, end = 0; end < len; {
    let (streak_end, was_reversed) = find_streak_by(arr.mut_view(start~), cmp)
    let end = end + streak_end
    if was_reversed {
      arr.mut_view(start~, end~).rev_in_place()
    }
    let end = provide_sorted_batch_by(arr, start, end, cmp)
    runs.push({ start, len: end - start, })
    while true {
      guard collapse(runs, len) is Some(r) else { break }
      let left = runs[r]
      let right = runs[r + 1]
      merge_by(arr.slice(left.start, right.start + right.len), left.len, cmp)
      runs[r + 1] = { start: left.start, len: left.len + right.len, }
      runs.remove(r) |> ignore
    }
    continue end, end
  }
}

///|
fn[T] MutArrayView::insertion_sort_by(
  arr : MutArrayView[T],
  cmp : (T, T) -> Int32,
) -> Unit {
  for i in 1..<arr.length() {
    for j = i
        j > 0 && cmp(arr.unsafe_get(j), arr.unsafe_get(j - 1)) < 0
        j = j - 1 {
      arr.swap(j, j - 1)
    }
  }
}

///|
// Merge from the back, choosing the right run on ties to preserve input order.
fn[T] merge_by(
  arr : MutArrayView[T],
  mid : Int32,
  cmp : (T, T) -> Int32,
) -> Unit {
  let buf_len = arr.length() - mid
  let buf = UninitializedArray::make_and_blit(
    arr.buf(),
    allocate_len=buf_len,
    src_offset=arr.start() + mid,
    len=buf_len,
  )
  let buf_remaining = for p1 = mid - 1, p2 = buf_len - 1, p = mid + buf_len - 1; p1 >=
                         0 &&
                         p2 >= 0; {
    if cmp(arr.unsafe_get(p1), buf[p2]) > 0 {
      arr.unsafe_set(p, arr.unsafe_get(p1))
      continue p1 - 1, p2, p - 1
    } else {
      arr.unsafe_set(p, buf[p2])
      continue p1, p2 - 1, p - 1
    }
  } nobreak {
    p2
  }
  if buf_remaining >= 0 {
    UninitializedArray::unsafe_blit(
      arr.buf(),
      arr.start(),
      buf,
      0,
      buf_remaining + 1,
    )
  }
}

///|
// Descending runs must be strict so reversing them never reverses equal elements.
fn[T] find_streak_by(
  arr : MutArrayView[T],
  cmp : (T, T) -> Int32,
) -> (Int32, Bool) {
  let len = arr.length()
  if len < 2 {
    return (len, false)
  }
  let assume_reverse = cmp(arr.unsafe_get(1), arr.unsafe_get(0)) < 0
  if assume_reverse {
    let end = for idx in 2..<len {
      if cmp(arr.unsafe_get(idx), arr.unsafe_get(idx - 1)) < 0 {
        continue
      }
      break idx
    } nobreak {
      len
    }
    (end, true)
  } else {
    let end = for idx in 2..<len {
      if cmp(arr.unsafe_get(idx), arr.unsafe_get(idx - 1)) >= 0 {
        continue
      }
      break idx
    } nobreak {
      len
    }
    (end, false)
  }
}

///|
fn[T] provide_sorted_batch_by(
  arr : MutArrayView[T],
  start : Int32,
  end : Int32,
  cmp : (T, T) -> Int32,
) -> Int32 {
  let len = arr.length()
  let min_insertion_run = 10
  if end - start < min_insertion_run && end < len {
    let sort_end = minimum(len, start + min_insertion_run)
    MutArrayView::insertion_sort_by(arr.slice(start, sort_end), cmp)
    sort_end
  } else {
    end
  }
}
