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
/// A classification attached to one generated test case.
///
/// Construct observations with `label`, `classify`, and `collect`.
enum Observation {
  Label(String)
  Class(label~ : String, hit~ : Bool)
} derive(@debug.Debug)

///|
/// Observations attached to one generated test case.
type Observations = Array[Observation]

///|
/// Aggregated observations from successful test cases.
///
/// `labels` counts each case's sorted set of labels as one joint bucket.
/// `classes` counts each named class independently.
priv struct ObservationSummary {
  labels : Map[@list.List[String], UInt]
  classes : Map[String, UInt]
} derive(@debug.Debug)

///|
pub impl Show for Observation with fn output(self, logger) {
  match self {
    Label(value) => logger.write_string(value)
    Class(label~, ..) => logger.write_string(label)
  }
}

///|
#deprecated("Use `@debug.Debug::to_repr` instead")
#doc(hidden)
pub extend Observation with @debug.Debug::{to_repr}

///|
/// Attaches `value` as a label to a generated test case.
pub fn label(value : String) -> Observation {
  Label(value)
}

///|
/// Classifies a generated test case under `label` when `condition` is true.
pub fn classify(condition : Bool, label : String) -> Observation {
  Class(label~, hit=condition)
}

///|
/// Attaches the debug representation of `value` as a label.
pub fn[T : @debug.Debug] collect(value : T) -> Observation {
  label(@debug.to_string(value))
}

///|
fn ObservationSummary::empty() -> ObservationSummary {
  { labels: {}, classes: {} }
}

///|
fn ObservationSummary::is_empty(self : ObservationSummary) -> Bool {
  self.labels.is_empty() && self.classes.is_empty()
}

///|
fn ObservationSummary::add(
  self : ObservationSummary,
  observations : Observations,
) -> Unit {
  let labels = []
  let classes : Map[String, Bool] = Map([])
  for observation in observations {
    match observation {
      Label(value) => if !labels.contains(value) { labels.push(value) }
      Class(label~, hit~) =>
        classes[label] = classes.get_or_default(label, false) || hit
    }
  }
  if !labels.is_empty() {
    labels.sort()
    let key = @list.List(labels)
    self.labels[key] = self.labels.get_or_default(key, 0U) + 1U
  }
  for label, hit in classes {
    let increment = if hit { 1U } else { 0U }
    self.classes[label] = self.classes.get_or_default(label, 0U) + increment
  }
}

///|
priv struct ObservationRow {
  count : UInt
  name : String
} derive(Eq)

///|
impl Compare for ObservationRow with fn compare(
  left : ObservationRow,
  right : ObservationRow,
) {
  if left.count > right.count {
    -1
  } else if left.count < right.count {
    1
  } else {
    Compare::compare(left.name, right.name)
  }
}

///|
fn uint_digits(value : UInt) -> Int {
  for remaining = value, digits = 1; remaining >= 10U; {
    continue remaining / 10U, digits + 1
  } nobreak {
    digits
  }
}

///|
fn percentage(count : UInt, total : UInt) -> UInt {
  guard total > 0U else { return 0U }
  let total = total.to_uint64()
  ((count.to_uint64() * 100UL + total / 2UL) / total).to_uint()
}

///|
fn write_observation_rows(
  builder : StringBuilder,
  heading : String,
  rows : Array[ObservationRow],
  total : UInt,
  count_width : Int,
) -> Unit {
  guard !rows.is_empty() else { return }
  rows.sort_by(Compare::compare)
  builder <+ "\n  "
  builder.write_string(heading)
  builder <+ ":"
  for row in rows {
    let percent = percentage(row.count, total)
    builder <+ "\n    "
    builder.write_string(" ".repeat(count_width - uint_digits(row.count)))
    builder.write_object(row.count)
    builder <+ "  "
    builder.write_string(" ".repeat(3 - uint_digits(percent)))
    builder.write_object(percent)
    builder <+ "%  "
    builder.write_string(row.name)
  }
}

///|
fn ObservationSummary::report(
  self : ObservationSummary,
  total : UInt,
) -> String {
  guard !self.is_empty() else { return "" }
  let label_rows = [
    for labels, count in self.labels => {
      { count, name: labels.iter().join(", ") }
    }
  ]
  let class_rows = [ for name, count in self.classes => { count, name } ]
  let builder = StringBuilder()
  builder <+ "\nobservations:"
  let count_width = uint_digits(total)
  write_observation_rows(builder, "labels", label_rows, total, count_width)
  write_observation_rows(builder, "classes", class_rows, total, count_width)
  builder.to_string()
}

///|
pub extend Observation with Show::{to_string}

// --- deprecated: hidden from the generated interface ---

///|
#deprecated("Use `Show::output` via the trait or `to_string` instead", skip_current_package=true)
#doc(hidden)
pub extend Observation with Show::{output}
