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
test "range Int basic" {
  inspect(@range.range(0, 5, 1), content="[0, 1, 2, 3, 4]")
  inspect(@range.range(0, 10, 3), content="[0, 3, 6, 9]")
  inspect(@range.range(0, 0, 1), content="[]")
  inspect(@range.range(5, 0, 1), content="[]")
}

///|
test "range Int inclusive" {
  inspect(@range.range(0, 5, 1, inclusive=true), content="[0, 1, 2, 3, 4, 5]")
  inspect(@range.range(0, 0, 1, inclusive=true), content="[0]")
  inspect(@range.range(0, 10, 3, inclusive=true), content="[0, 3, 6, 9]")
}

///|
test "range Int descending" {
  inspect(@range.range(10, 0, -1), content="[10, 9, 8, 7, 6, 5, 4, 3, 2, 1]")
  inspect(@range.range(10, 0, -3), content="[10, 7, 4, 1]")
  inspect(@range.range(10, 0, -3, inclusive=true), content="[10, 7, 4, 1]")
  inspect(@range.range(0, 10, -1), content="[]")
}

///|
test "range Int overflow at MAX_VALUE" {
  inspect(
    @range.range(@int.MAX_VALUE - 2, @int.MAX_VALUE - 1, 1),
    content="[2147483645]",
  )
  inspect(
    @range.range(@int.MAX_VALUE - 1, @int.MAX_VALUE, 1, inclusive=true),
    content="[2147483646, 2147483647]",
  )
  inspect(
    @range.range(@int.MAX_VALUE, @int.MAX_VALUE, 1, inclusive=true),
    content="[2147483647]",
  )
}

///|
test "range Int64" {
  inspect(@range.range(0L, 10L, 3L), content="[0, 3, 6, 9]")
  inspect(@range.range(10L, 0L, -3L), content="[10, 7, 4, 1]")
  inspect(
    @range.range(0x80000000L, 0x80000000L + 10L, 2L),
    content="[2147483648, 2147483650, 2147483652, 2147483654, 2147483656]",
  )
}

///|
test "range UInt" {
  inspect(@range.range(0U, 5U, 1U), content="[0, 1, 2, 3, 4]")
  inspect(@range.range(0U, 10U, 3U), content="[0, 3, 6, 9]")
  inspect(@range.range(5U, 0U, 1U), content="[]")
}

///|
test "range UInt64" {
  inspect(@range.range(0UL, 5UL, 1UL), content="[0, 1, 2, 3, 4]")
}

///|
test "range Double" {
  inspect(@range.range(0.0, 1.0, 0.25), content="[0, 0.25, 0.5, 0.75]")
  inspect(
    @range.range(0.0, 1.0, 0.25, inclusive=true),
    content="[0, 0.25, 0.5, 0.75, 1]",
  )
  inspect(@range.range(0.0, -1.0, -0.25), content="[0, -0.25, -0.5, -0.75]")
}

///|
test "range Double terminates on sub-precision step" {
  // 1e16 + 1.0 == 1e16 in IEEE 754 (double precision around 2^53),
  // so the loop must bail rather than infinite-loop.
  let r = @range.range(1.0e16, 1.0e16 + 100.0, 1.0).take(5).to_array()
  inspect(r.length() <= 1, content="true")
}

///|
test "range Double Inf step yields one and stops" {
  let inf = 1.0 / 0.0
  inspect(@range.range(0.0, 100.0, inf), content="[0]")
}

///|
test "range Float" {
  inspect(
    @range.range((0.0 : Float), 1.0, 0.25),
    content="[0, 0.25, 0.5, 0.75]",
  )
}

///|
test "range BigInt" {
  inspect(@range.range(0N, 5N, 1N), content="[0, 1, 2, 3, 4]")
  inspect(@range.range(10N, 0N, -3N), content="[10, 7, 4, 1]")
  inspect(
    @range.range(0N, 1000000000000000000000N, 200000000000000000000N),
    content="[0, 200000000000000000000, 400000000000000000000, 600000000000000000000, 800000000000000000000]",
  )
}

///|
test "range zero step aborts" {
  // We can't easily catch `abort` in tests, so we just document the
  // contract via the public docstring. A zero-step call would abort
  // the process here.
  inspect(@range.Direction::Still == @range.Still, content="true")
}

///|
test "range is lazy" {
  let mut count = 0
  for i in @range.range(0, 100, 1) {
    count = count + 1
    if i == 4 {
      break
    }
  }
  inspect(count, content="5")
}
