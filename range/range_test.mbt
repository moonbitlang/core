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
test "range Int default step" {
  inspect(@range.range(0, 5), content="[0, 1, 2, 3, 4]")
  inspect(@range.range(0, 0), content="[]")
  inspect(@range.range(5, 0), content="[]")
}

///|
test "range Int with step" {
  inspect(@range.range(0, 10, step=3), content="[0, 3, 6, 9]")
  inspect(@range.range(100, 101, step=4), content="[100]")
  inspect(@range.range(1, 2, step=0), content="[]")
}

///|
test "range Int inclusive" {
  inspect(@range.range(0, 5, inclusive=true), content="[0, 1, 2, 3, 4, 5]")
  inspect(@range.range(0, 0, inclusive=true), content="[0]")
}

///|
test "range Int negative step" {
  inspect(@range.range(10, 0, step=-1).take(5), content="[10, 9, 8, 7, 6]")
  inspect(@range.range(10, 0, step=-3), content="[10, 7, 4, 1]")
}

///|
test "range Int overflow near max" {
  inspect(
    @range.range(@int.MAX_VALUE - 2, @int.MAX_VALUE - 1),
    content="[2147483645]",
  )
  inspect(
    @range.range(@int.MAX_VALUE - 2, @int.MAX_VALUE - 1, inclusive=true),
    content="[2147483645, 2147483646]",
  )
  inspect(
    @range.range(@int.MAX_VALUE - 1, @int.MAX_VALUE, inclusive=true),
    content="[2147483646, 2147483647]",
  )
}

///|
test "range Int64" {
  inspect(@range.range(0L, 10L, step=3L), content="[0, 3, 6, 9]")
  inspect(
    @range.range(0x80000000L, 0x80000000L + 10L, step=2L),
    content="[2147483648, 2147483650, 2147483652, 2147483654, 2147483656]",
  )
  inspect(
    @range.range(0x80000000L, 0x80000000L - 10L, step=-2L).take(5),
    content="[2147483648, 2147483646, 2147483644, 2147483642, 2147483640]",
  )
}

///|
test "range UInt" {
  inspect(@range.range(0U, 5U), content="[0, 1, 2, 3, 4]")
  inspect(@range.range(0U, 10U, step=3U), content="[0, 3, 6, 9]")
}

///|
test "range UInt64" {
  inspect(@range.range(0UL, 5UL), content="[0, 1, 2, 3, 4]")
  inspect(@range.range(0UL, 10UL, step=3UL), content="[0, 3, 6, 9]")
}

///|
test "range Double" {
  inspect(@range.range(0.0, 1.0, step=0.25), content="[0, 0.25, 0.5, 0.75]")
  inspect(
    @range.range(0.0, 1.0, step=0.25, inclusive=true),
    content="[0, 0.25, 0.5, 0.75, 1]",
  )
  inspect(@range.range(1.0, 2.0, step=0.0), content="[]")
  inspect(
    @range.range(0.0, -1.0, step=-0.25),
    content="[0, -0.25, -0.5, -0.75]",
  )
}

///|
test "range Float" {
  inspect(
    @range.range((0.0 : Float), 1.0, step=0.25),
    content="[0, 0.25, 0.5, 0.75]",
  )
}

///|
test "range is lazy" {
  let mut count = 0
  for i in @range.range(0, 100) {
    count = count + 1
    if i == 4 {
      break
    }
  }
  inspect(count, content="5")
}
