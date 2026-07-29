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
fn size_at(index : UInt, count : UInt, max_size : UInt) -> Int {
  if count <= 1 {
    0
  } else {
    let size = index.to_uint64() *
      max_size.to_uint64() /
      (count - 1).to_uint64()
    if size > @int.MAX_VALUE.to_uint64() {
      @int.MAX_VALUE
    } else {
      size.to_int()
    }
  }
}

///|
priv enum CaseOutcome {
  Passed
  Falsified
  Raised(Error)
}

///|
/// Structured result of a property check.
///
/// `tests` includes the failing test case. `shrinks` counts accepted shrink
/// steps, while `shrink_attempts` counts every shrink candidate whose property
/// was evaluated.
pub enum QuickCheckReport[A] {
  Passed(tests~ : UInt)
  Falsified(
    counterexample~ : A,
    tests~ : UInt,
    size~ : Int,
    shrinks~ : UInt,
    shrink_attempts~ : UInt
  )
  Raised(
    counterexample~ : A,
    error~ : Error,
    tests~ : UInt,
    size~ : Int,
    shrinks~ : UInt,
    shrink_attempts~ : UInt
  )
} derive(@debug.Debug)

///|
#deprecated("Use `@debug.Debug::to_repr` instead")
#doc(hidden)
pub extend QuickCheckReport with @debug.Debug::{to_repr}

///|
fn[A] evaluate_property(
  property : (A) -> Bool raise?,
  input : A,
) -> CaseOutcome {
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
      let outcome = evaluate_property(property, candidate)
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
fn[A : @debug.Debug] failure_report(report : QuickCheckReport[A]) -> String {
  match report {
    Passed(..) => abort("quickcheck internal error: a passed property reported")
    Falsified(counterexample~, tests~, size~, shrinks~, shrink_attempts~) =>
      (
        $|QuickCheck falsified after \{tests} test(s)
        $|counterexample: \{@debug.to_string(counterexample)}
        $|size: \{size}
        $|shrinks: \{shrinks} successful, \{shrink_attempts} attempted
      )
    Raised(counterexample~, error~, tests~, size~, shrinks~, shrink_attempts~) =>
      (
        $|QuickCheck property raised after \{tests} test(s)
        $|counterexample: \{@debug.to_string(counterexample)}
        $|error: \{@debug.to_string(error)}
        $|size: \{size}
        $|shrinks: \{shrinks} successful, \{shrink_attempts} attempted
      )
  }
}

///|
/// Checks `property` and returns a structured report.
///
/// Returning `false` produces `QuickCheckReport::Falsified`; every error raised
/// by the property produces `QuickCheckReport::Raised`. Unlike `quickcheck`,
/// this function does not turn either report into a test failure, does not
/// raise property errors, and does not require the input type to implement
/// `Debug`.
pub fn[A : Arbitrary + @shrink.Shrink] quickcheck_report(
  property : (A) -> Bool raise?,
  count? : UInt = 100,
  max_size? : UInt = 100,
  max_shrinks? : UInt = 100,
  seed? : UInt64 = 37,
) -> QuickCheckReport[A] {
  let state = @splitmix.new(seed~)
  for index = 0U; index < count; index = index + 1 {
    let size = size_at(index, count, max_size)
    let input : A = Arbitrary::arbitrary(size, state.split())
    let outcome = evaluate_property(property, input)
    match outcome {
      Passed => ()
      _ => {
        let tests = index + 1
        let (counterexample, outcome, shrinks, shrink_attempts) = shrink_failure(
          property, input, outcome, max_shrinks,
        )
        return match outcome {
          Falsified =>
            Falsified(
              counterexample~,
              tests~,
              size~,
              shrinks~,
              shrink_attempts~,
            )
          Raised(error) =>
            Raised(
              counterexample~,
              error~,
              tests~,
              size~,
              shrinks~,
              shrink_attempts~,
            )
          Passed =>
            abort(
              "quickcheck internal error: unexpected passed outcome after shrinking",
            )
        }
      }
    }
  }
  Passed(tests=count)
}

///|
/// Checks `property` against generated values and shrinks the first failure.
///
/// Returning `false` falsifies the property. Raising an error records an
/// exceptional counterexample instead; these two failure classes are shrunk
/// independently.
///
/// The generator size grows linearly from zero to `max_size`. Each test case
/// receives an independent random stream derived from `seed`. If a case fails,
/// the driver greedily keeps the first smaller candidate with the same failure
/// class until there are no such candidates or `max_shrinks` property
/// evaluations have been attempted.
///
/// Parameters:
///
/// * `property`: A deterministic function returning `true` on success.
/// * `count`: Number of generated cases. Zero performs no tests.
/// * `max_size`: Largest requested generator size. Values above the `Int`
///   range accepted by `Arbitrary` are saturated at `Int::MAX_VALUE`.
/// * `max_shrinks`: Maximum number of shrink candidates evaluated. Zero
///   disables shrinking.
/// * `seed`: Seed used to derive each test case's random stream.
///
/// On falsification or a raised error, this function raises a
/// `Failure` containing the smallest counterexample found, its corresponding
/// error when applicable, and shrink information.
///
/// ```mbt check
/// test "adding zero is an identity" {
///   @quickcheck.quickcheck((x : Int) => x + 0 == x)
/// }
/// ```
#callsite(autofill(loc))
pub fn[A : Arbitrary + @shrink.Shrink + @debug.Debug] quickcheck(
  property : (A) -> Bool raise?,
  count? : UInt = 100,
  max_size? : UInt = 100,
  max_shrinks? : UInt = 100,
  seed? : UInt64 = 37,
  loc~ : SourceLoc,
) -> Unit raise {
  let report = quickcheck_report(
    property,
    count~,
    max_size~,
    max_shrinks~,
    seed~,
  )
  match report {
    Passed(..) => ()
    Falsified(..) | Raised(..) => fail(failure_report(report), loc~)
  }
}
