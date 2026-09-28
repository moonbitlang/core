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
  debug_inspect(
    @range.iter(from=0, to=5).to_array(),
    content=(
      #|[0, 1, 2, 3, 4]
    ),
  )
  debug_inspect(
    @range.iter(from=0, to=0).to_array(),
    content=(
      #|[]
    ),
  )
  debug_inspect(
    @range.iter(from=5, to=0).to_array(),
    content=(
      #|[]
    ),
  )
}

///|
test "iter Int with step" {
  debug_inspect(
    @range.iter(from=0, to=10, step=3).to_array(),
    content=(
      #|[0, 3, 6, 9]
    ),
  )
  debug_inspect(
    @range.iter(from=100, to=101, step=4).to_array(),
    content=(
      #|[100]
    ),
  )
}

///|
test "iter Int inclusive" {
  debug_inspect(
    @range.iter(from=0, to=5, inclusive=true).to_array(),
    content=(
      #|[0, 1, 2, 3, 4, 5]
    ),
  )
  debug_inspect(
    @range.iter(from=0, to=0, inclusive=true).to_array(),
    content=(
      #|[0]
    ),
  )
  debug_inspect(
    @range.iter(from=0, to=10, step=3, inclusive=true).to_array(),
    content=(
      #|[0, 3, 6, 9]
    ),
  )
}

///|
test "iter Int descending" {
  debug_inspect(
    @range.iter(from=10, to=0, step=-1).to_array(),
    content=(
      #|[10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
    ),
  )
  debug_inspect(
    @range.iter(from=10, to=0, step=-3).to_array(),
    content=(
      #|[10, 7, 4, 1]
    ),
  )
  debug_inspect(
    @range.iter(from=10, to=0, step=-3, inclusive=true).to_array(),
    content=(
      #|[10, 7, 4, 1]
    ),
  )
  debug_inspect(
    @range.iter(from=0, to=10, step=-1).to_array(),
    content=(
      #|[]
    ),
  )
}

///|
test "iter Int overflow at MAX_VALUE" {
  debug_inspect(
    @range.iter(from=@int.MAX_VALUE - 2, to=@int.MAX_VALUE - 1).to_array(),
    content=(
      #|[2147483645]
    ),
  )
  debug_inspect(
    @range.iter(from=@int.MAX_VALUE - 1, to=@int.MAX_VALUE, inclusive=true).to_array(),
    content=(
      #|[2147483646, 2147483647]
    ),
  )
  debug_inspect(
    @range.iter(from=@int.MAX_VALUE, to=@int.MAX_VALUE, inclusive=true).to_array(),
    content=(
      #|[2147483647]
    ),
  )
}

///|
test "iter Int64" {
  debug_inspect(
    @range.iter(from=0L, to=10L, step=3L).to_array(),
    content=(
      #|[0, 3, 6, 9]
    ),
  )
  debug_inspect(
    @range.iter(from=10L, to=0L, step=-3L).to_array(),
    content=(
      #|[10, 7, 4, 1]
    ),
  )
  debug_inspect(
    @range.iter(from=0x80000000L, to=0x80000000L + 10L, step=2L).to_array(),
    content=(
      #|[2147483648, 2147483650, 2147483652, 2147483654, 2147483656]
    ),
  )
}

///|
test "iter UInt" {
  debug_inspect(
    @range.iter(from=0U, to=5U).to_array(),
    content=(
      #|[0, 1, 2, 3, 4]
    ),
  )
  debug_inspect(
    @range.iter(from=0U, to=10U, step=3U).to_array(),
    content=(
      #|[0, 3, 6, 9]
    ),
  )
  debug_inspect(
    @range.iter(from=5U, to=0U).to_array(),
    content=(
      #|[]
    ),
  )
}

///|
test "iter UInt64" {
  debug_inspect(
    @range.iter(from=0UL, to=5UL).to_array(),
    content=(
      #|[0, 1, 2, 3, 4]
    ),
  )
}

///|
test "iter Double" {
  debug_inspect(
    @range.iter(from=0.0, to=1.0, step=0.25).to_array(),
    content=(
      #|[0, 0.25, 0.5, 0.75]
    ),
  )
  debug_inspect(
    @range.iter(from=0.0, to=1.0, step=0.25, inclusive=true).to_array(),
    content=(
      #|[0, 0.25, 0.5, 0.75, 1]
    ),
  )
  debug_inspect(
    @range.iter(from=0.0, to=-1.0, step=-0.25).to_array(),
    content=(
      #|[0, -0.25, -0.5, -0.75]
    ),
  )
}

///|
test "iter Double default step is 1.0" {
  debug_inspect(
    @range.iter(from=0.0, to=4.5).to_array(),
    content=(
      #|[0, 1, 2, 3, 4]
    ),
  )
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
  debug_inspect(
    @range.iter(from=0.0, to=100.0, step=inf).to_array(),
    content=(
      #|[0]
    ),
  )
}

///|
test "iter Float" {
  debug_inspect(
    @range.iter(from=(0.0 : Float), to=1.0, step=0.25).to_array(),
    content=(
      #|[0, 0.25, 0.5, 0.75]
    ),
  )
}

///|
test "iter Int16" {
  debug_inspect(
    @range.iter(from=(0 : Int16), to=(5 : Int16)).to_array(),
    content=(
      #|[0, 1, 2, 3, 4]
    ),
  )
  debug_inspect(
    @range.iter(from=(0 : Int16), to=(10 : Int16), step=(3 : Int16)).to_array(),
    content=(
      #|[0, 3, 6, 9]
    ),
  )
  debug_inspect(
    @range.iter(from=(10 : Int16), to=(0 : Int16), step=(-1 : Int16)).to_array(),
    content=(
      #|[10, 9, 8, 7, 6, 5, 4, 3, 2, 1]
    ),
  )
}

///|
test "iter UInt16" {
  debug_inspect(
    @range.iter(from=(0 : UInt16), to=(5 : UInt16)).to_array(),
    content=(
      #|[0, 1, 2, 3, 4]
    ),
  )
  debug_inspect(
    @range.iter(from=(0 : UInt16), to=(10 : UInt16), step=(3 : UInt16)).to_array(),
    content=(
      #|[0, 3, 6, 9]
    ),
  )
}

///|
test "iter Byte" {
  debug_inspect(
    @range.iter(from=(0 : Byte), to=(5 : Byte)).to_array(),
    content=(
      #|[0x00, 0x01, 0x02, 0x03, 0x04]
    ),
  )
  debug_inspect(
    @range.iter(from=(250 : Byte), to=(255 : Byte), inclusive=true).to_array(),
    content=(
      #|[0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff]
    ),
  )
}

///|
test "iter BigInt" {
  debug_inspect(
    @range.iter(from=0N, to=5N).to_array(),
    content=(
      #|[0, 1, 2, 3, 4]
    ),
  )
  debug_inspect(
    @range.iter(from=10N, to=0N, step=-3N).to_array(),
    content=(
      #|[10, 7, 4, 1]
    ),
  )
  debug_inspect(
    @range.iter(
      from=0N,
      to=1000000000000000000000N,
      step=200000000000000000000N,
    ).to_array(),
    content=(
      #|[
      #|  0,
      #|  200000000000000000000,
      #|  400000000000000000000,
      #|  600000000000000000000,
      #|  800000000000000000000,
      #|]
    ),
  )
}

///|
test "iter zero step yields empty (or [from] when inclusive at the boundary)" {
  debug_inspect(
    @range.iter(from=0, to=10, step=0).to_array(),
    content=(
      #|[]
    ),
  )
  debug_inspect(
    @range.iter(from=5, to=5, step=0, inclusive=true).to_array(),
    content=(
      #|[5]
    ),
  )
  debug_inspect(
    @range.iter(from=0.0, to=1.0, step=0.0).to_array(),
    content=(
      #|[]
    ),
  )
}

///|
test "iter Double NaN step matches Double::until: yields [from] only when inclusive at equal bounds" {
  let nan = 0.0 / 0.0
  debug_inspect(
    @range.iter(from=1.0, to=1.0, step=nan, inclusive=true).to_array(),
    content=(
      #|[1]
    ),
  )
  debug_inspect(
    @range.iter(from=1.0, to=2.0, step=nan, inclusive=true).to_array(),
    content=(
      #|[]
    ),
  )
  debug_inspect(
    @range.iter(from=1.0, to=1.0, step=nan).to_array(),
    content=(
      #|[]
    ),
  )
}

///|
test "iter Double NaN end never matches inclusive" {
  let nan = 0.0 / 0.0
  // NaN as `to` with a finite forward step must not infinite-loop;
  // it terminates because `i == NaN` is always false.
  debug_inspect(
    @range.iter(from=0.0, to=nan, step=1.0, inclusive=true).to_array(),
    content=(
      #|[]
    ),
  )
}

///|
test "iter Int MIN_VALUE descending and step" {
  // step = MIN_VALUE: 0 + MIN_VALUE = MIN_VALUE (one valid advance);
  // MIN_VALUE + MIN_VALUE wraps to 0, no progress, stops.
  let min = -2147483648
  debug_inspect(
    @range.iter(from=0, to=min, step=min).to_array(),
    content=(
      #|[0]
    ),
  )
  debug_inspect(
    @range.iter(from=0, to=min, step=min, inclusive=true).to_array(),
    content=(
      #|[0, -2147483648]
    ),
  )
  // Plain descending into MIN_VALUE
  debug_inspect(
    @range.iter(from=min + 2, to=min, step=-1, inclusive=true).to_array(),
    content=(
      #|[-2147483646, -2147483647, -2147483648]
    ),
  )
}

///|
test "iter UInt wrap-around at MAX_VALUE" {
  let max = 4294967295U
  debug_inspect(
    @range.iter(from=max - 1U, to=max, step=2U).to_array(),
    content=(
      #|[4294967294]
    ),
  )
  debug_inspect(
    @range.iter(from=max - 1U, to=max, inclusive=true).to_array(),
    content=(
      #|[4294967294, 4294967295]
    ),
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
    count += 1
    if i == 4 {
      break
    }
  }
  inspect(count, content="5")
}

///|
test "iter Double computes each element as from + k * step" {
  // Each element is `from + k * step`, not the previous element plus
  // `step`. Repeated addition drifts, which showed up as an 11th element
  // (0.9999999999999999) and as `inclusive` never reaching `to`.
  debug_inspect(
    @range.iter(from=0.0, to=1.0, step=0.1).to_array(),
    content=(
      #|[
      #|  0,
      #|  0.1,
      #|  0.2,
      #|  0.30000000000000004,
      #|  0.4,
      #|  0.5,
      #|  0.6000000000000001,
      #|  0.7000000000000001,
      #|  0.8,
      #|  0.9,
      #|]
    ),
  )
  debug_inspect(
    @range.iter(from=0.0, to=1.0, step=0.1, inclusive=true).to_array().last(),
    content=(
      #|Some(1)
    ),
  )
  debug_inspect(
    @range.iter(from=1.0, to=0.0, step=-0.1, inclusive=true).to_array().last(),
    content=(
      #|Some(0)
    ),
  )
  // from + 3 * 0.1 is 0.30000000000000004, so an inclusive 0.3 is not hit
  debug_inspect(
    @range.iter(from=0.0, to=0.3, step=0.1, inclusive=true).to_array(),
    content=(
      #|[0, 0.1, 0.2]
    ),
  )
  // the documented workaround: iterate over integers and scale
  debug_inspect(
    @range.iter(from=0, to=3, inclusive=true)
    .map(k => k.to_double() / 10.0)
    .to_array(),
    content=(
      #|[0, 0.1, 0.2, 0.3]
    ),
  )
}

///|
test "iter Float computes each element as from + k * step" {
  debug_inspect(
    @range.iter(from=Float(0), to=1.0, step=0.01).count(),
    content=(
      #|100
    ),
  )
  debug_inspect(
    @range.iter(from=Float(0), to=1.0, step=0.01, inclusive=true)
    .to_array()
    .last()
    .map(Float::to_double),
    content=(
      #|Some(1)
    ),
  )
}

///|
test "iter Double direct stepping edge cases" {
  let inf = 1.0 / 0.0
  // element 0 is `from` itself, so a negative zero survives
  let first = @range.iter(from=-0.0, to=1.0, step=0.5).to_array()[0]
  inspect(1.0 / first == -inf, content="true")
  // `from + k * step` overflowing to infinity is a real (last) element
  debug_inspect(
    @range.iter(from=1.0e308, to=inf, step=1.0e308, inclusive=true).to_array(),
    content=(
      #|[1e+308, Infinity]
    ),
  )
  debug_inspect(
    @range.iter(from=-inf, to=0.0).to_array(),
    content=(
      #|[-Infinity]
    ),
  )
  // A step close to the spacing of the elements: 2^53 + 3 * 1.5 rounds to
  // the same Double as 2^53 + 2 * 1.5, so the iterator stops there rather
  // than yield a duplicate. The elements stay strictly increasing.
  let big = 9007199254740992.0
  debug_inspect(
    @range.iter(from=big, to=big + 12.0, step=1.5).map(x => x - big).to_array(),
    content=(
      #|[0, 2, 4]
    ),
  )
}

///|
test "iter Double survives k * step overflowing while from + k * step is finite" {
  // At k = 2, 2 * 1e308 overflows to infinity, but -1e308 + 2 * 1e308 is
  // 1e308, a representable (inclusive) end point, so it must not become
  // from + inf.
  debug_inspect(
    @range.iter(from=-1.0e308, to=1.0e308, step=1.0e308, inclusive=true).to_array(),
    content=(
      #|[-1e+308, 0, 1e+308]
    ),
  )
  debug_inspect(
    @range.iter(from=1.0e308, to=-1.0e308, step=-1.0e308, inclusive=true).to_array(),
    content=(
      #|[1e+308, 0, -1e+308]
    ),
  )
  // The overflowing element must still be computed as from + k * step, not
  // as prev + step: element 5 here is 3.000000000000001e307, and adding step
  // to it would carry that error forward and overshoot `to` (6e307). Like
  // every element, element 6 rounds k * step and then the sum, so it lands
  // just below `to` rather than on it, exactly as the same range scaled down
  // by a power of two does (see the quickcheck on scale invariance).
  debug_inspect(
    @range.iter(from=-1.2e308, to=6.0e307, step=3.0e307, inclusive=true)
    .to_array()
    .last(),
    content=(
      #|Some(5.999999999999998e+307)
    ),
  )
  debug_inspect(
    @range.iter(from=1.2e308, to=-6.0e307, step=-3.0e307, inclusive=true)
    .to_array()
    .last(),
    content=(
      #|Some(-5.999999999999998e+307)
    ),
  )
}
