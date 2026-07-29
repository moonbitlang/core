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
  let ShrinkInput(value) = input
  if value <= 0 {
    Iter::empty()
  } else {
    [ShrinkInput(value - 1), ShrinkInput(0)].iter()
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
  let DriftInput(value) = input
  if value == 10 {
    [DriftInput(9), DriftInput(8)].iter()
  } else {
    Iter::empty()
  }
}

///|
priv suberror QcError {
  InitialRaised
  ShrunkRaised
} derive(Debug)

///|
test "quickcheck_report returns a structured passing report" {
  let report = @quickcheck.quickcheck_report(
    (x : Int) => x == x,
    count=2,
    seed=7,
  )
  debug_inspect(report, content="Passed(tests=2)")
}

///|
test "quickcheck_report returns a structured falsification" {
  let report = @quickcheck.quickcheck_report(
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
test "quickcheck_report returns a structured raised error" {
  let report = @quickcheck.quickcheck_report(
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
test "quickcheck accepts a passing boolean property" {
  @quickcheck.quickcheck((x : Int) => x == x, count=5, seed=0)
}

///|
test "quickcheck runs the requested count with increasing sizes" {
  let seen = []
  @quickcheck.quickcheck(
    (input : SizedProbe) => {
      let SizedProbe(size) = input
      seen.push(size)
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
test "quickcheck size progression does not overflow" {
  let seen = []
  @quickcheck.quickcheck(
    (input : SizedProbe) => {
      let SizedProbe(size) = input
      seen.push(size)
      true
    },
    count=3,
    max_size=2147483647,
    seed=0,
  )
  debug_inspect(seen, content="[0, 1073741823, 2147483647]")
}

///|
test "quickcheck accepts zero count without running any tests" {
  @quickcheck.quickcheck((_ : Unit) => false, count=0U)
}

///|
test "quickcheck clamps maximum size to the Arbitrary Int range" {
  let seen = []
  @quickcheck.quickcheck(
    (input : SizedProbe) => {
      let SizedProbe(size) = input
      seen.push(size)
      true
    },
    count=2,
    max_size=4294967295U,
  )
  debug_inspect(seen, content="[0, 2147483647]")
}

///|
test "quickcheck_report greedily shrinks a falsified property" {
  let report = @quickcheck.quickcheck_report(
    (input : ShrinkInput) => {
      let ShrinkInput(value) = input
      value < 3
    },
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
test "quickcheck_report bounds a repeating shrink stream by attempts" {
  let report = @quickcheck.quickcheck_report(
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
test "quickcheck_report counts rejected shrink candidates toward the limit" {
  let report = @quickcheck.quickcheck_report(
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
test "quickcheck_report keeps falsification separate from raised errors" {
  let report = @quickcheck.quickcheck_report(
    (input : DriftInput) => {
      let DriftInput(value) = input
      if value == 9 {
        raise InitialRaised
      }
      value != 10 && value != 8
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
test "quickcheck_report keeps raised errors separate from falsification" {
  let report = @quickcheck.quickcheck_report(
    (input : DriftInput) => {
      let DriftInput(value) = input
      match value {
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
test "quickcheck_report stops at the first failing case" {
  let mut calls = 0
  let report = @quickcheck.quickcheck_report(
    (_ : Int) => {
      calls = calls + 1
      calls < 4
    },
    count=10,
    max_shrinks=0,
  )
  guard report is Falsified(tests=4, ..) else {
    fail("expected the fourth case to falsify")
  }
  inspect(calls, content="4")
}

///|
test "quickcheck_report returns Failure as a raised property" {
  let report = @quickcheck.quickcheck_report(
    (_ : Int) => fail("property boom"),
    count=1,
    max_shrinks=0,
  )
  guard report is Raised(error=Failure(msg), tests=1, ..) else {
    fail("expected the property to raise Failure")
  }
  inspect(msg.contains("property boom"), content="true")
}

///|
test "quickcheck_report accepts InspectError while shrinking Raised" {
  let report = @quickcheck.quickcheck_report(
    (input : DriftInput) => {
      let DriftInput(value) = input
      match value {
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
