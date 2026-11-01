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
fn clamped_bench_doc() -> String {
  [
    "key = \"value\"\n",
    "name = \"moonbit\" # 😈 comment\n",
    "nums = [1, 2, 3, 40, 500]\n",
    "[table]\n",
    "emoji = \"😈😈😈\"\n",
    "flag = true\n",
    "date = 1979-05-27T07:32:00Z\n",
  ].join("")
}

///|
/// Every character boundary of `s`: the offsets a caller can legitimately ask
/// for, skipping the middle of a surrogate pair.
fn clamped_bench_stops(s : String) -> Array[Int32] {
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
/// `s[i:]`: one bound, so the end offset is the string length and the only
/// boundary that can need snapping is the start.
test "bench String::clamped_view start only" (it : @bench.T) {
  let s = clamped_bench_doc()
  let stops = clamped_bench_stops(s)
  it.bench(() => {
    let mut acc = 0
    for i in stops {
      let v = s.clamped_view(start=i)
      acc += v.start_offset() + v.length()
    }
    it.keep(acc)
  })
}

///|
/// `s[i:len]`: the same request with the length spelled out.
test "bench String::clamped_view start and end at the end" (it : @bench.T) {
  let s = clamped_bench_doc()
  let stops = clamped_bench_stops(s)
  let len = s.length()
  it.bench(() => {
    let mut acc = 0
    for i in stops {
      let v = s.clamped_view(start=i, end=len)
      acc += v.start_offset() + v.length()
    }
    it.keep(acc)
  })
}

///|
/// `s[i:i + 4]`: two bounds that both have to be clamped and snapped.
test "bench String::clamped_view start and end" (it : @bench.T) {
  let s = clamped_bench_doc()
  let stops = clamped_bench_stops(s)
  it.bench(() => {
    let mut acc = 0
    for i in stops {
      let v = s.clamped_view(start=i, end=i + 4)
      acc += v.start_offset() + v.length()
    }
    it.keep(acc)
  })
}

///|
/// The view-relative spelling of the one-bound case.
test "bench StringView::clamped_view start only" (it : @bench.T) {
  let s = clamped_bench_doc()
  let stops = clamped_bench_stops(s)
  let whole = s[:]
  it.bench(() => {
    let mut acc = 0
    for i in stops {
      let v = whole.clamped_view(start=i)
      acc += v.start_offset() + v.length()
    }
    it.keep(acc)
  })
}
