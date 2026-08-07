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
priv struct SizedProbe(Int) derive(Debug)

///|
impl @quickcheck.Arbitrary for SizedProbe with fn arbitrary(size, _) {
  SizedProbe(size)
}

///|
impl @shrink.Shrink for SizedProbe

///|
priv struct ShrinkInput(Int) derive(Debug)

///|
impl @quickcheck.Arbitrary for ShrinkInput with fn arbitrary(_, _) {
  ShrinkInput(10)
}

///|
impl @shrink.Shrink for ShrinkInput with fn shrink(input) {
  if input.0 <= 0 {
    Iter::empty()
  } else {
    [ShrinkInput(input.0 - 1), ShrinkInput(0)].iter()
  }
}

///|
priv struct RepeatingInput(Int) derive(Debug, Arbitrary)

///|
impl @shrink.Shrink for RepeatingInput with fn shrink(input) {
  Iter::repeat(input)
}

///|
priv struct DriftInput(Int) derive(Debug)

///|
impl @quickcheck.Arbitrary for DriftInput with fn arbitrary(_, _) {
  DriftInput(10)
}

///|
impl @shrink.Shrink for DriftInput with fn shrink(input) {
  if input.0 == 10 {
    [DriftInput(9), DriftInput(8)].iter()
  } else {
    Iter::empty()
  }
}

///|
priv struct FilteredShrinkInput(Int) derive(Debug)

///|
impl @quickcheck.Arbitrary for FilteredShrinkInput with fn arbitrary(_, _) {
  FilteredShrinkInput(10)
}

///|
impl @shrink.Shrink for FilteredShrinkInput with fn shrink(input) {
  match input.0 {
    10 => [FilteredShrinkInput(9), FilteredShrinkInput(7)].iter()
    9 => [FilteredShrinkInput(8)].iter()
    _ => Iter::empty()
  }
}

///|
priv suberror QcError {
  InitialRaised
  ShrunkRaised
} derive(Debug)

///|
test "report returns a structured passing report" {
  let report = @quickcheck.report((x : Int) => x == x, count=2, seed=7)
  debug_inspect(report, content="Passed(tests=2)")
}

///|
test "report aggregates passing observations" {
  let report = @quickcheck.report(
    (_ : SizedProbe) => true,
    observe=input => {
      [
        @quickcheck.label(if input.0 % 2 == 0 { "even" } else { "odd" }),
        @quickcheck.classify(input.0 > 0, "positive"),
      ]
    },
    count=4,
    max_size=3,
  )
  debug_inspect(
    report,
    content=(
      #|Passed(
      #|  tests=4,
      #|  observations={
      #|    labels: { <List: ["even"]>: 2, <List: ["odd"]>: 2 },
      #|    classes: { "positive": 3 },
      #|  },
      #|)
    ),
  )
}

///|
test "discarded cases do not contribute observations" {
  let report = @quickcheck.report(
    (_ : SizedProbe) => true,
    filter=input => input.0 > 0,
    observe=input => [@quickcheck.collect(input.0)],
    count=2,
    max_size=2,
  )
  debug_inspect(
    report,
    content=(
      #|Passed(
      #|  tests=2,
      #|  observations={ labels: { <List: ["1"]>: 1, <List: ["2"]>: 1 } },
      #|)
    ),
  )
}

///|
test "report returns a structured falsification" {
  let report = @quickcheck.report(
    (_ : Int) => false,
    count=1,
    max_size=0,
    max_shrinks=0,
    seed=7,
  )
  debug_inspect(
    report,
    content=(
      #|Falsified(
      #|  counterexample=0,
      #|  tests=1,
      #|  size=0,
      #|  shrinks=0,
      #|  shrink_attempts=0,
      #|)
    ),
  )
}

///|
test "report returns a structured raised error" {
  let report = @quickcheck.report(
    (_ : Int) => raise InitialRaised,
    count=1,
    max_size=0,
    max_shrinks=0,
    seed=7,
  )
  debug_inspect(
    report,
    content=(
      #|Raised(
      #|  counterexample=0,
      #|  error=InitialRaised,
      #|  tests=1,
      #|  size=0,
      #|  shrinks=0,
      #|  shrink_attempts=0,
      #|)
    ),
  )
}

///|
test "check accepts a passing boolean property" {
  @quickcheck.check((x : Int) => x == x, count=5, seed=0)
}

///|
test "check runs the requested count with increasing sizes" {
  let seen = []
  @quickcheck.check(
    (input : SizedProbe) => {
      seen.push(input.0)
      true
    },
    count=5,
    max_size=20,
  )
  debug_inspect(
    seen,
    content=(
      #|[0, 5, 10, 15, 20]
    ),
  )
}

///|
test "discard ratio controls the give-up budget" {
  let report = @quickcheck.report(
    (_ : Int) => true,
    filter=_ => false,
    count=4,
    discard_ratio=2,
  )
  debug_inspect(
    report,
    content=(
      #|GaveUp(tests=0, discarded=8)
    ),
  )
}

///|
test "check size progression does not overflow" {
  let seen = []
  @quickcheck.check(
    (input : SizedProbe) => {
      seen.push(input.0)
      true
    },
    count=3,
    max_size=2147483647,
    seed=0,
  )
  debug_inspect(seen, content="[0, 1073741823, 2147483647]")
}

///|
test "check accepts zero count without running any tests" {
  @quickcheck.check((_ : Unit) => false, count=0U)
}

///|
test "check clamps maximum size to the Arbitrary Int range" {
  let seen = []
  @quickcheck.check(
    (input : SizedProbe) => {
      seen.push(input.0)
      true
    },
    count=2,
    max_size=4294967295U,
  )
  debug_inspect(seen, content="[0, 2147483647]")
}

///|
test "report greedily shrinks a falsified property" {
  let report = @quickcheck.report(
    (input : ShrinkInput) => input.0 < 3,
    count=1,
    max_shrinks=100,
  )
  debug_inspect(
    report,
    content=(
      #|Falsified(
      #|  counterexample=ShrinkInput(3),
      #|  tests=1,
      #|  size=0,
      #|  shrinks=7,
      #|  shrink_attempts=9,
      #|)
    ),
  )
}

///|
test "report bounds a repeating shrink stream by attempts" {
  let report = @quickcheck.report(
    (_ : RepeatingInput) => false,
    count=1,
    max_shrinks=10,
  )
  debug_inspect(
    report,
    content=(
      #|Falsified(
      #|  counterexample=RepeatingInput(0),
      #|  tests=1,
      #|  size=0,
      #|  shrinks=10,
      #|  shrink_attempts=10,
      #|)
    ),
  )
}

///|
test "report counts rejected shrink candidates toward the limit" {
  let report = @quickcheck.report(
    (input : DriftInput) => {
      let DriftInput(value) = input
      if value == 9 {
        raise InitialRaised
      }
      value != 10 && value != 8
    },
    count=1,
    max_shrinks=1,
  )
  debug_inspect(
    report,
    content=(
      #|Falsified(
      #|  counterexample=DriftInput(10),
      #|  tests=1,
      #|  size=0,
      #|  shrinks=0,
      #|  shrink_attempts=1,
      #|)
    ),
  )
}

///|
test "report skips a discarded shrink subtree" {
  let report = @quickcheck.report(
    (_ : FilteredShrinkInput) => false,
    filter=input => input.0 != 9,
    count=1,
    max_shrinks=10,
  )
  debug_inspect(
    report,
    content=(
      #|Falsified(
      #|  counterexample=FilteredShrinkInput(7),
      #|  tests=1,
      #|  size=0,
      #|  shrinks=1,
      #|  shrink_attempts=2,
      #|)
    ),
  )
}

///|
test "report keeps falsification separate from raised errors" {
  let report = @quickcheck.report(
    (input : DriftInput) => {
      guard input.0 != 9 else { raise InitialRaised }
      input.0 != 10 && input.0 != 8
    },
    count=1,
    max_shrinks=10,
  )
  debug_inspect(
    report,
    content=(
      #|Falsified(
      #|  counterexample=DriftInput(8),
      #|  tests=1,
      #|  size=0,
      #|  shrinks=1,
      #|  shrink_attempts=2,
      #|)
    ),
  )
}

///|
test "report keeps raised errors separate from falsification" {
  let report = @quickcheck.report(
    (input : DriftInput) => {
      match input.0 {
        10 => raise InitialRaised
        9 => false
        8 => raise ShrunkRaised
        _ => true
      }
    },
    count=1,
    max_shrinks=10,
  )
  debug_inspect(
    report,
    content=(
      #|Raised(
      #|  counterexample=DriftInput(8),
      #|  error=ShrunkRaised,
      #|  tests=1,
      #|  size=0,
      #|  shrinks=1,
      #|  shrink_attempts=2,
      #|)
    ),
  )
}

///|
test "report stops at the first failing case" {
  let mut calls = 0
  let result = @quickcheck.report(
    (_ : Int) => {
      calls = calls + 1
      calls < 4
    },
    count=10,
    max_shrinks=0,
  )
  debug_inspect(
    result,
    content=(
      #|Falsified(
      #|  counterexample=13,
      #|  tests=4,
      #|  size=33,
      #|  shrinks=0,
      #|  shrink_attempts=0,
      #|)
    ),
  )
  inspect(calls, content="4")
}

///|
test "report returns Failure as a raised property" {
  let result = @quickcheck.report(
    (_ : Int) => fail("property boom"),
    count=1,
    max_shrinks=0,
  )
  inspect(@debug.to_string(result).contains("property boom"), content="true")
}

///|
test "report accepts InspectError while shrinking Raised" {
  let report = @quickcheck.report(
    (input : DriftInput) => {
      match input.0 {
        10 => raise InitialRaised
        9 => raise InspectError("shrink sentinel")
        _ => true
      }
    },
    count=1,
    max_shrinks=10,
  )
  debug_inspect(
    report,
    content=(
      #|Raised(
      #|  counterexample=DriftInput(9),
      #|  error=InspectError("shrink sentinel"),
      #|  tests=1,
      #|  size=0,
      #|  shrinks=1,
      #|  shrink_attempts=1,
      #|)
    ),
  )
}

///|
test "classes-only summary omits the empty labels field" {
  let report = @quickcheck.report(
    (_ : Int) => true,
    observe=_ => [@quickcheck.classify(true, "observed")],
    count=3,
    max_size=2,
  )
  debug_inspect(
    report,
    content=(
      #|Passed(tests=3, observations={ classes: { "observed": 3 } })
    ),
  )
}

///|
test "context renders the shrunk counterexample" {
  let report = @quickcheck.report(
    (x : Int) => x < 3,
    context=x => "rendered input <\{x}>",
    count=100,
    max_shrinks=100,
    seed=7,
  )
  debug_inspect(
    report,
    content=(
      #|Falsified(
      #|  counterexample=3,
      #|  context="rendered input <3>",
      #|  tests=5,
      #|  size=4,
      #|  shrinks=0,
      #|  shrink_attempts=2,
      #|)
    ),
  )
}

///|
test "context is attached to raised failures too" {
  let report = @quickcheck.report(
    (x : Int) => if x >= 3 { fail("boom") } else { true },
    context=x => "rendered input <\{x}>",
    count=100,
    max_shrinks=100,
    seed=7,
  )
  debug_inspect(
    report,
    content=(
      #|Raised(
      #|  counterexample=3,
      #|  context="rendered input <3>",
      #|  error=Failure("quickcheck/driver_test.mbt:500:30-500:42@moonbitlang/core FAILED: boom"),
      #|  tests=5,
      #|  size=4,
      #|  shrinks=0,
      #|  shrink_attempts=2,
      #|)
    ),
  )
}
