// Copyright 2024 International Digital Economy Academy
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

type DayOfYear Int derive(Debug, Eq, Show, Compare)

let min_day_of_year = 1

let max_day_of_year = 366

pub fn DayOfYear::new(day_of_year : Int) -> Result[DayOfYear, String] {
  if DayOfYear::valid(day_of_year) {
    Ok(DayOfYear(day_of_year))
  } else {
    Err(doy_out_of_range_err)
  }
}

pub fn DayOfYear::valid(day_of_year : Int) -> Bool {
  day_of_year <= max_day_of_year && day_of_year >= min_day_of_year
}

test "new" {
  @assertion.assert_eq(DayOfYear::new(1), Ok(DayOfYear(1)))?
  @assertion.assert_eq(DayOfYear::new(366), Ok(DayOfYear(366)))?
  @assertion.assert_eq(DayOfYear::new(367), Err(doy_out_of_range_err))?
  @assertion.assert_eq(DayOfYear::new(0), Err(doy_out_of_range_err))?
}

test "valid" {
  @assertion.assert_true(DayOfYear::valid(1))?
  @assertion.assert_true(DayOfYear::valid(366))?
  @assertion.assert_false(DayOfYear::valid(0))?
  @assertion.assert_false(DayOfYear::valid(367))?
}
