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
let obs_sample : ObservationSummary = {
  labels: Map([(List(["common"]), 100U), (List(["rare"]), 5U)]),
  classes: Map([("edge", 10U)]),
}

///|
test "passed report aligns observation statistics" {
  inspect(
    obs_sample.report(105U),
    content=(
      #|
      #|observations:
      #|  labels:
      #|    100   95%  common
      #|      5    5%  rare
      #|  classes:
      #|     10   10%  edge
    ),
  )
}

///|
test "failure report includes aggregate statistics" {
  let report : QuickCheckReport[Int] = Falsified(
    counterexample=3,
    tests=106U,
    size=10,
    shrinks=1U,
    shrink_attempts=2U,
    observations=obs_sample,
  )
  inspect(
    failure_report(report),
    content=(
      #|QuickCheck falsified after 106 test(s)
      #|counterexample: 3
      #|size: 10
      #|shrinks: 1 successful, 2 attempted
      #|observations:
      #|  labels:
      #|    100   95%  common
      #|      5    5%  rare
      #|  classes:
      #|     10   10%  edge
    ),
  )
}

///|
test "failed cases do not run the observer" {
  let observed = []
  let _ = report(
    (_ : Int) => false,
    observe=_ => {
      observed.push(())
      []
    },
    count=1,
    max_size=0,
    max_shrinks=0,
  )
  assert_true(observed.is_empty())
}
