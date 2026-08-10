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
fn size_at(
  index : UInt,
  count : UInt,
  max_size : UInt,
  recent_discards : UInt,
) -> Int {
  let base_size = if count <= 1 {
    0UL
  } else {
    index.to_uint64() * max_size.to_uint64() / (count - 1).to_uint64()
  }
  let size = base_size + recent_discards.to_uint64()
  let limit = if max_size.to_uint64() > @int.MAX_VALUE.to_uint64() {
    @int.MAX_VALUE.to_uint64()
  } else {
    max_size.to_uint64()
  }
  if size > limit {
    limit.to_int()
  } else {
    size.to_int()
  }
}

///|
priv enum CaseOutcome {
  Passed
  Discarded
  Falsified
  Raised(Error)
}

///|
/// Structured result of a property check.
///
/// `tests` includes the failing test case. `shrinks` counts accepted shrink
/// steps, while `shrink_attempts` counts every shrink candidate examined,
/// including candidates rejected by `filter`. `observations` contains only
/// successful top-level cases.
enum QuickCheckReport[A] {
  Passed(tests~ : UInt, observations~ : ObservationSummary)
  /// The configured discard budget was exhausted before `count` tests completed.
  GaveUp(tests~ : UInt, discarded~ : UInt, observations~ : ObservationSummary)
  Falsified(
    counterexample~ : A,
    context~ : String?,
    tests~ : UInt,
    size~ : Int,
    shrinks~ : UInt,
    shrink_attempts~ : UInt,
    observations~ : ObservationSummary
  )
  Raised(
    counterexample~ : A,
    error~ : Error,
    context~ : String?,
    tests~ : UInt,
    size~ : Int,
    shrinks~ : UInt,
    shrink_attempts~ : UInt,
    observations~ : ObservationSummary
  )
}

///|
pub impl[A : @debug.Debug] @debug.Debug for QuickCheckReport[A] with fn to_repr(
  self,
) {
  match self {
    Passed(tests~, observations~) =>
      @debug.Repr::ctor(
        "Passed",
        [
          (Some("tests"), Repr(tests)),
          ..if !observations.is_empty() {
            [(Some("observations"), @debug.Repr(observations))]
          },
        ],
      )
    GaveUp(tests~, discarded~, observations~) =>
      @debug.Repr::ctor(
        "GaveUp",
        [
          (Some("tests"), Repr(tests)),
          (Some("discarded"), Repr(discarded)),
          ..if !observations.is_empty() {
            [(Some("observations"), @debug.Repr(observations))]
          },
        ],
      )
    Falsified(
      counterexample~,
      context~,
      tests~,
      size~,
      shrinks~,
      shrink_attempts~,
      observations~
    ) =>
      @debug.Repr::ctor(
        "Falsified",
        [
          (Some("counterexample"), Repr(counterexample)),
          ..if context is Some(text) {
            [(Some("context"), @debug.Repr(text))]
          },
          (Some("tests"), Repr(tests)),
          (Some("size"), Repr(size)),
          (Some("shrinks"), Repr(shrinks)),
          (Some("shrink_attempts"), Repr(shrink_attempts)),
          ..if !observations.is_empty() {
            [(Some("observations"), @debug.Repr(observations))]
          },
        ],
      )
    Raised(
      counterexample~,
      error~,
      context~,
      tests~,
      size~,
      shrinks~,
      shrink_attempts~,
      observations~
    ) =>
      @debug.Repr::ctor(
        "Raised",
        [
          (Some("counterexample"), Repr(counterexample)),
          ..if context is Some(text) {
            [(Some("context"), @debug.Repr(text))]
          },
          (Some("error"), Repr(error)),
          (Some("tests"), Repr(tests)),
          (Some("size"), Repr(size)),
          (Some("shrinks"), Repr(shrinks)),
          (Some("shrink_attempts"), Repr(shrink_attempts)),
          ..if !observations.is_empty() {
            [(Some("observations"), @debug.Repr(observations))]
          },
        ],
      )
  }
}

///|
#deprecated("Use `@debug.Debug::to_repr` instead")
#doc(hidden)
pub extend QuickCheckReport with @debug.Debug::{to_repr}

///|
fn[A] evaluate_case(
  property : (A) -> Bool raise?,
  filter : (A) -> Bool,
  input : A,
) -> CaseOutcome {
  guard filter(input) else { Discarded }
  let invoke : (A) -> Bool raise = a => property(a)
  try invoke(input) catch {
    err => Raised(err)
  } noraise {
    true => Passed
    false => Falsified
  }
}

///|
impl Eq for CaseOutcome with fn equal(expected, actual) {
  match (expected, actual) {
    (Falsified, Falsified) | (Raised(_), Raised(_)) => true
    _ => false
  }
}

///|
fn[A : @shrink.Shrink] shrink_failure(
  property : (A) -> Bool raise?,
  filter : (A) -> Bool,
  input : A,
  initial : CaseOutcome,
  max_shrinks : UInt,
) -> (A, CaseOutcome, UInt, UInt) {
  let mut current = input
  let mut current_outcome = initial
  let mut successful = 0U
  let mut attempted = 0U
  let mut found = true
  while attempted < max_shrinks && found {
    found = false
    let candidates = @shrink.Shrink::shrink(current)
    while attempted < max_shrinks && candidates.next() is Some(candidate) {
      attempted = attempted + 1
      let outcome = evaluate_case(property, filter, candidate)
      if initial == outcome {
        current = candidate
        current_outcome = outcome
        successful = successful + 1
        found = true
        break
      }
    }
  }
  (current, current_outcome, successful, attempted)
}

///|
fn context_line(context : String?) -> String {
  match context {
    Some(text) => "\ncontext: \{text}"
    None => ""
  }
}

///|
fn[A : @debug.Debug] failure_report(report : QuickCheckReport[A]) -> String {
  match report {
    Passed(..) => abort("quickcheck internal error: a passed property reported")
    GaveUp(tests~, discarded~, observations~) =>
      (
        $|QuickCheck gave up after \{tests} test(s)
        $|discarded: \{discarded}\{observations.report(tests, prefix="\n")}
      )
    Falsified(
      counterexample~,
      context~,
      tests~,
      size~,
      shrinks~,
      shrink_attempts~,
      observations~
    ) =>
      (
        $|QuickCheck falsified after \{tests} test(s)
        $|counterexample: \{@debug.to_string(counterexample)}\{context_line(context)}
        $|size: \{size}
        $|shrinks: \{shrinks} successful, \{shrink_attempts} attempted\{observations.report(tests - 1U, prefix="\n")}
      )
    Raised(
      counterexample~,
      error~,
      context~,
      tests~,
      size~,
      shrinks~,
      shrink_attempts~,
      observations~
    ) =>
      (
        $|QuickCheck property raised after \{tests} test(s)
        $|counterexample: \{@debug.to_string(counterexample)}\{context_line(context)}
        $|error: \{@debug.to_string(error)}
        $|size: \{size}
        $|shrinks: \{shrinks} successful, \{shrink_attempts} attempted\{observations.report(tests - 1U, prefix="\n")}
      )
  }
}

///|
/// Checks `property` and returns a structured report.
///
/// Returning `false` records a falsification; every error raised by the
/// property is recorded separately. Unlike `check`, this function does not
/// turn either result into a test failure, does not raise property errors, and
/// does not require the input type to implement `Debug`. Cases rejected by the
/// pure `filter` do not count as tests. The run gives up after `discard_ratio`
/// discarded cases per requested test. The pure `observe` function is
/// evaluated and aggregated only after a top-level case succeeds.
///
/// `context` attaches a human-readable description of the shrunk
/// counterexample to a failure — for example the rendered form of a
/// generated document — without conflating it with errors raised by the
/// property itself.
pub fn[A : Arbitrary + @shrink.Shrink] report(
  property : (A) -> Bool raise?,
  filter? : (A) -> Bool = _ => true,
  observe? : (A) -> Observations = _ => [],
  context? : (A) -> String,
  count? : UInt = 100,
  max_size? : UInt = 100,
  max_shrinks? : UInt = 100,
  discard_ratio? : UInt = 10,
  seed? : UInt64 = 37,
) -> QuickCheckReport[A] {
  let state = @splitmix.new(seed~)
  let observations = ObservationSummary::empty()
  for tests = 0U, discarded = 0U, recent_discards = 0U; tests < count; {
    let size = size_at(tests, count, max_size, recent_discards)
    let input : A = Arbitrary::arbitrary(size, state.split())
    let outcome = evaluate_case(property, filter, input)
    match outcome {
      Passed => {
        observations.add(observe(input))
        continue tests + 1, discarded, 0U
      }
      Discarded => {
        let next_discarded = discarded + 1
        if discard_ratio == 0 || next_discarded / discard_ratio >= count {
          return GaveUp(tests~, discarded=next_discarded, observations~)
        }
        continue tests, next_discarded, recent_discards + 1
      }
      _ => {
        let completed_tests = tests + 1
        let (counterexample, outcome, shrinks, shrink_attempts) = shrink_failure(
          property, filter, input, outcome, max_shrinks,
        )
        let context = context.map(render => render(counterexample))
        return match outcome {
          Falsified =>
            Falsified(
              counterexample~,
              context~,
              tests=completed_tests,
              size~,
              shrinks~,
              shrink_attempts~,
              observations~,
            )
          Raised(error) =>
            Raised(
              counterexample~,
              error~,
              context~,
              tests=completed_tests,
              size~,
              shrinks~,
              shrink_attempts~,
              observations~,
            )
          Passed | Discarded =>
            abort(
              "quickcheck internal error: unexpected non-failure after shrinking",
            )
        }
      }
    }
  } nobreak {
    Passed(tests=count, observations~)
  }
}

///|
/// Checks `property` against generated values and shrinks the first failure.
///
/// Returning `false` falsifies the property. Raising an error records an
/// exceptional counterexample instead; these two failure classes are shrunk
/// independently. `filter` is evaluated first; returning `false` discards the
/// case without evaluating the property.
///
/// The generator size follows a linear schedule from zero to `max_size`.
/// Consecutive discarded cases temporarily increase the requested size, up to
/// `max_size`. Each generated case receives an independent random stream
/// derived from `seed`. If a case fails, the driver greedily keeps the first
/// smaller candidate with the same failure class until there are no such
/// candidates or `max_shrinks` candidates have been examined. A filtered
/// shrink candidate consumes an attempt, skips that candidate's subtree, and
/// does not count toward the run's discard budget.
///
/// Parameters:
///
/// * `property`: A deterministic function returning `true` on success.
/// * `filter`: A pure precondition returning `true` for cases to test.
/// * `observe`: A pure function classifying cases with `label`, `classify`, or
///   `collect`.
/// * `context`: A pure function rendering the shrunk counterexample as a
///   human-readable string included in the failure report.
/// * `count`: Number of non-discarded cases to test. Zero performs no tests.
/// * `max_size`: Largest requested generator size. Values above the `Int`
///   range accepted by `Arbitrary` are saturated at `Int::MAX_VALUE`.
/// * `max_shrinks`: Maximum number of shrink candidates examined. Zero
///   disables shrinking.
/// * `discard_ratio`: Maximum discarded cases per requested test. Zero gives
///   up on the first discarded case.
/// * `seed`: Seed used to derive each test case's random stream.
///
/// On falsification or a raised error, this function raises a
/// `Failure` containing the smallest counterexample found, its corresponding
/// error when applicable, shrink information, and any collected observations.
/// A successful run prints observation statistics when any were collected;
/// otherwise it prints nothing.
///
/// ```mbt check
/// test "adding zero is an identity" {
///   @quickcheck.check((x : Int) => x + 0 == x)
/// }
/// ```
#callsite(autofill(loc))
pub fn[A : Arbitrary + @shrink.Shrink + @debug.Debug] check(
  property : (A) -> Bool raise?,
  filter? : (A) -> Bool = _ => true,
  observe? : (A) -> Observations = _ => [],
  context? : (A) -> String,
  count? : UInt = 100,
  max_size? : UInt = 100,
  max_shrinks? : UInt = 100,
  discard_ratio? : UInt = 10,
  seed? : UInt64 = 37,
  loc~ : SourceLoc,
) -> Unit raise {
  let result = report(
    property,
    filter~,
    observe~,
    context?,
    count~,
    max_size~,
    max_shrinks~,
    discard_ratio~,
    seed~,
  )
  match result {
    Passed(observations~, ..) if observations.is_empty() => ()
    Passed(tests~, observations~) => println(observations.report(tests))
    GaveUp(..) | Falsified(..) | Raised(..) =>
      fail(failure_report(result), loc~)
  }
}
