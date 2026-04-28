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
test "iter Int default step" {
  inspect(@range.iter(from=0, to=5), content="[0, 1, 2, 3, 4]")
  inspect(@range.iter(from=0, to=0), content="[]")
  inspect(@range.iter(from=5, to=0), content="[]")
}

///|
test "iter Int with step" {
  inspect(@range.iter(from=0, to=10, step=3), content="[0, 3, 6, 9]")
  inspect(@range.iter(from=100, to=101, step=4), content="[100]")
}

///|
test "iter Int inclusive" {
  inspect(
    @range.iter(from=0, to=5, inclusive=true),
    content="[0, 1, 2, 3, 4, 5]",
  )
  inspect(@range.iter(from=0, to=0, inclusive=true), content="[0]")
  inspect(
    @range.iter(from=0, to=10, step=3, inclusive=true),
    content="[0, 3, 6, 9]",
  )
}

///|
test "iter Int descending" {
  inspect(
    @range.iter(from=10, to=0, step=-1),
    content="[10, 9, 8, 7, 6, 5, 4, 3, 2, 1]",
  )
  inspect(@range.iter(from=10, to=0, step=-3), content="[10, 7, 4, 1]")
  inspect(
    @range.iter(from=10, to=0, step=-3, inclusive=true),
    content="[10, 7, 4, 1]",
  )
  inspect(@range.iter(from=0, to=10, step=-1), content="[]")
}

///|
test "iter Int overflow at MAX_VALUE" {
  inspect(
    @range.iter(from=@int.MAX_VALUE - 2, to=@int.MAX_VALUE - 1),
    content="[2147483645]",
  )
  inspect(
    @range.iter(from=@int.MAX_VALUE - 1, to=@int.MAX_VALUE, inclusive=true),
    content="[2147483646, 2147483647]",
  )
  inspect(
    @range.iter(from=@int.MAX_VALUE, to=@int.MAX_VALUE, inclusive=true),
    content="[2147483647]",
  )
}

///|
test "iter Int64" {
  inspect(@range.iter(from=0L, to=10L, step=3L), content="[0, 3, 6, 9]")
  inspect(@range.iter(from=10L, to=0L, step=-3L), content="[10, 7, 4, 1]")
  inspect(
    @range.iter(from=0x80000000L, to=0x80000000L + 10L, step=2L),
    content="[2147483648, 2147483650, 2147483652, 2147483654, 2147483656]",
  )
}

///|
test "iter UInt" {
  inspect(@range.iter(from=0U, to=5U), content="[0, 1, 2, 3, 4]")
  inspect(@range.iter(from=0U, to=10U, step=3U), content="[0, 3, 6, 9]")
  inspect(@range.iter(from=5U, to=0U), content="[]")
}

///|
test "iter UInt64" {
  inspect(@range.iter(from=0UL, to=5UL), content="[0, 1, 2, 3, 4]")
}

///|
test "iter Double" {
  inspect(
    @range.iter(from=0.0, to=1.0, step=0.25),
    content="[0, 0.25, 0.5, 0.75]",
  )
  inspect(
    @range.iter(from=0.0, to=1.0, step=0.25, inclusive=true),
    content="[0, 0.25, 0.5, 0.75, 1]",
  )
  inspect(
    @range.iter(from=0.0, to=-1.0, step=-0.25),
    content="[0, -0.25, -0.5, -0.75]",
  )
}

///|
test "iter Double default step is 1.0" {
  inspect(@range.iter(from=0.0, to=4.5), content="[0, 1, 2, 3, 4]")
}

///|
test "iter Double terminates on sub-precision step" {
  // 1e16 + 1.0 == 1e16 in IEEE 754 (double precision around 2^53),
  // so the loop must bail rather than infinite-loop.
  let r = @range.iter(from=1.0e16, to=1.0e16 + 100.0, step=1.0)
    .take(5)
    .to_array()
  inspect(r.length() <= 1, content="true")
}

///|
test "iter Double Inf step yields one and stops" {
  let inf = 1.0 / 0.0
  inspect(@range.iter(from=0.0, to=100.0, step=inf), content="[0]")
}

///|
test "iter Float" {
  inspect(
    @range.iter(from=(0.0 : Float), to=1.0, step=0.25),
    content="[0, 0.25, 0.5, 0.75]",
  )
}

///|
test "iter Int16" {
  inspect(
    @range.iter(from=(0 : Int16), to=(5 : Int16)),
    content="[0, 1, 2, 3, 4]",
  )
  inspect(
    @range.iter(from=(0 : Int16), to=(10 : Int16), step=(3 : Int16)),
    content="[0, 3, 6, 9]",
  )
  inspect(
    @range.iter(from=(10 : Int16), to=(0 : Int16), step=(-1 : Int16)),
    content="[10, 9, 8, 7, 6, 5, 4, 3, 2, 1]",
  )
}

///|
test "iter UInt16" {
  inspect(
    @range.iter(from=(0 : UInt16), to=(5 : UInt16)),
    content="[0, 1, 2, 3, 4]",
  )
  inspect(
    @range.iter(from=(0 : UInt16), to=(10 : UInt16), step=(3 : UInt16)),
    content="[0, 3, 6, 9]",
  )
}

///|
test "iter Byte" {
  inspect(
    @range.iter(from=(0 : Byte), to=(5 : Byte)),
    content="[b'\\x00', b'\\x01', b'\\x02', b'\\x03', b'\\x04']",
  )
  inspect(
    @range.iter(from=(250 : Byte), to=(255 : Byte), inclusive=true),
    content="[b'\\xFA', b'\\xFB', b'\\xFC', b'\\xFD', b'\\xFE', b'\\xFF']",
  )
}

///|
test "iter BigInt" {
  inspect(@range.iter(from=0N, to=5N), content="[0, 1, 2, 3, 4]")
  inspect(@range.iter(from=10N, to=0N, step=-3N), content="[10, 7, 4, 1]")
  inspect(
    @range.iter(
      from=0N,
      to=1000000000000000000000N,
      step=200000000000000000000N,
    ),
    content="[0, 200000000000000000000, 400000000000000000000, 600000000000000000000, 800000000000000000000]",
  )
}

///|
test "iter zero step yields empty (or [from] when inclusive at the boundary)" {
  inspect(@range.iter(from=0, to=10, step=0), content="[]")
  inspect(@range.iter(from=5, to=5, step=0, inclusive=true), content="[5]")
  inspect(@range.iter(from=0.0, to=1.0, step=0.0), content="[]")
}

///|
test "iter Double NaN step matches Double::until: yields [from] only when inclusive at equal bounds" {
  let nan = 0.0 / 0.0
  inspect(
    @range.iter(from=1.0, to=1.0, step=nan, inclusive=true),
    content="[1]",
  )
  inspect(@range.iter(from=1.0, to=2.0, step=nan, inclusive=true), content="[]")
  inspect(@range.iter(from=1.0, to=1.0, step=nan), content="[]")
}

///|
test "iter Double NaN end never matches inclusive" {
  let nan = 0.0 / 0.0
  // NaN as `to` with a finite forward step must not infinite-loop;
  // it terminates because `i == NaN` is always false.
  inspect(@range.iter(from=0.0, to=nan, step=1.0, inclusive=true), content="[]")
}

///|
test "iter Int MIN_VALUE descending and step" {
  // step = MIN_VALUE: 0 + MIN_VALUE = MIN_VALUE (one valid advance);
  // MIN_VALUE + MIN_VALUE wraps to 0, no progress, stops.
  let min = -2147483648
  inspect(@range.iter(from=0, to=min, step=min), content="[0]")
  inspect(
    @range.iter(from=0, to=min, step=min, inclusive=true),
    content="[0, -2147483648]",
  )
  // Plain descending into MIN_VALUE
  inspect(
    @range.iter(from=min + 2, to=min, step=-1, inclusive=true),
    content="[-2147483646, -2147483647, -2147483648]",
  )
}

///|
test "iter UInt wrap-around at MAX_VALUE" {
  let max = 4294967295U
  inspect(@range.iter(from=max - 1U, to=max, step=2U), content="[4294967294]")
  inspect(
    @range.iter(from=max - 1U, to=max, inclusive=true),
    content="[4294967294, 4294967295]",
  )
}

///|
test "iter via for-comprehension into array" {
  debug_inspect(
    [
      for i in @range.iter(from=1, to=10, step=3) => i
    ],
    content="[1, 4, 7]",
  )
  debug_inspect(
    [
      for i in @range.iter(from=0, to=5) => i * i
    ],
    content="[0, 1, 4, 9, 16]",
  )
  debug_inspect(
    [
      for c in @range.iter(from=(0 : Byte), to=(4 : Byte)) => c
    ],
    content="[0x00, 0x01, 0x02, 0x03]",
  )
}

///|
test "iter is lazy" {
  let mut count = 0
  for i in @range.iter(from=0, to=100) {
    count = count + 1
    if i == 4 {
      break
    }
  }
  inspect(count, content="5")
}
