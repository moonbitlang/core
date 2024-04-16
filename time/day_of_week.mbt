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

enum DayOfWeek {
  Monday
  Tuesday
  Wednesday
  Thursday
  Friday
  Saturday
  Sunday
} derive(Debug, Eq, Show)

let min_day_of_week = 1

let max_day_of_week = 7

pub fn DayOfWeek::new_exact(day_of_week : Int) -> DayOfWeek {
  match DayOfWeek::new(day_of_week) {
    Ok(dow) => dow
    _ => abort(dow_out_of_range_err)
  }
}

pub fn DayOfWeek::new(day_of_week : Int) -> Result[DayOfWeek, String] {
  match day_of_week {
    1 => Ok(Monday)
    2 => Ok(Tuesday)
    3 => Ok(Wednesday)
    4 => Ok(Thursday)
    5 => Ok(Friday)
    6 => Ok(Saturday)
    7 => Ok(Sunday)
    _ => Err(dow_out_of_range_err)
  }
}

pub fn DayOfWeek::valid(day_of_week : Int) -> Bool {
  day_of_week >= min_day_of_week && day_of_week <= max_day_of_week
}

test "new" {
  @assertion.assert_eq(DayOfWeek::new(1), Ok(DayOfWeek::Monday))?
  @assertion.assert_eq(DayOfWeek::new(2), Ok(DayOfWeek::Tuesday))?
  @assertion.assert_eq(DayOfWeek::new(3), Ok(DayOfWeek::Wednesday))?
  @assertion.assert_eq(DayOfWeek::new(4), Ok(DayOfWeek::Thursday))?
  @assertion.assert_eq(DayOfWeek::new(5), Ok(DayOfWeek::Friday))?
  @assertion.assert_eq(DayOfWeek::new(6), Ok(DayOfWeek::Saturday))?
  @assertion.assert_eq(DayOfWeek::new(7), Ok(DayOfWeek::Sunday))?
  @assertion.assert_eq(DayOfWeek::new(8), Err(dow_out_of_range_err))?
  @assertion.assert_eq(DayOfWeek::new(0), Err(dow_out_of_range_err))?
}

test "valid" {
  inspect(DayOfWeek::valid(1), ~content="true")?
  inspect(DayOfWeek::valid(7), ~content="true")?
  inspect(DayOfWeek::valid(0), ~content="false")?
  inspect(DayOfWeek::valid(8), ~content="false")?
}
