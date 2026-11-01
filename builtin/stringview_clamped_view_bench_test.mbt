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
/// Text with astral characters, so the boundary snapping has real surrogate
/// pairs to look at, and long enough that the per-call cost is what is being
/// measured.
fn stringview_clamped_bench_doc() -> String {
  [
    "key = \"value\"\n", "name = \"moonbit\" # 😈 comment\n", "nums = [1, 2, 3, 40, 500]\n",
    "[table]\n", "emoji = \"😈😈😈\"\n", "flag = true\n", "date = 1979-05-27T07:32:00Z\n",
  ].join("")
}

///|
/// Character-boundary starts, representative of parser cursors. Separate
/// benchmarks below also exercise out-of-range and surrogate-splitting starts.
fn stringview_clamped_bench_stops(s : String) -> Array[Int32] {
  let stops : Array[Int32] = []
  let mut i = 0
  while i <= s.length() {
    stops.push(i)
    let pair = i + 1 < s.length() &&
      s.unsafe_get(i).is_leading_surrogate() &&
      s.unsafe_get(i + 1).is_trailing_surrogate()
    i += if pair { 2 } else { 1 }
  }
  stops
}

///|
/// The view-relative spelling of the one-bound case.
test "bench StringView::clamped_view start only" (it : @bench.T) {
  let s = stringview_clamped_bench_doc()
  let stops = stringview_clamped_bench_stops(s)
  let whole = ("prefix" + s + "suffix").exact_view(start=6, end=6 + s.length())
  it.bench(() => {
    let mut acc = 0
    for i in stops {
      let v = whole.clamped_view(start=i)
      acc += v.start_offset() ^ v.length()
    }
    it.keep(acc)
  })
}

///|
/// Include every code-unit offset, negative and oversized offsets, and both
/// integer extremes so the fast path also measures clamping and snapping.
fn stringview_clamped_bench_mixed_stops(s : String) -> Array[Int32] {
  let stops = [@int.MIN_VALUE, @int.MAX_VALUE]
  for i in -1..<=(s.length() + 1) {
    stops.push(i)
  }
  stops
}

///|
test "bench StringView::clamped_view mixed starts" (it : @bench.T) {
  let s = stringview_clamped_bench_doc()
  let stops = stringview_clamped_bench_mixed_stops(s)
  let whole = ("prefix" + s + "suffix").exact_view(start=6, end=6 + s.length())
  it.bench(() => {
    let mut acc = 0
    for i in stops {
      let v = whole.clamped_view(start=i)
      acc += v.start_offset() ^ v.length()
    }
    it.keep(acc)
  })
}
