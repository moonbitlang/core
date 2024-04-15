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

enum Month {
  January
  February
  March
  April
  May
  June
  July
  August
  September
  October
  November
  December
} derive (Debug, Eq, Compare)

let min_month : Int = 1

let max_month : Int = 12

pub fn Month::new(month : Int) -> Result[Month, String] {
  if month < min_month || month > max_month {
    return Err(month_out_of_range_err)
  }
  match month {
    1 => Ok(January)
    2 => Ok(February)
    3 => Ok(March)
    4 => Ok(April)
    5 => Ok(May)
    6 => Ok(June)
    7 => Ok(July)
    8 => Ok(August)
    9 => Ok(September)
    10 => Ok(October)
    11 => Ok(November)
    12 => Ok(December)
    _ => Err(month_out_of_range_err)
  }
}

pub fn value(self: Month) -> Int {
  match self {
    January => 1
    February => 2
    March => 3
    April => 4
    May => 5
    June => 6
    July => 7
    August => 8
    September => 9
    October => 10
    November => 11
    December => 12
  }
}

pub fn length(self : Month, ~leap_year : Bool = false) -> Int {
  match self {
    February => if leap_year { 29 } else { 28 }
    April | June | September | November => 30
    _ => 31
  }
}

test "new" {
  @assertion.assert_eq(Month::new(0), Err(month_out_of_range_err))?
  @assertion.assert_eq(Month::new(13), Err(month_out_of_range_err))?
  @assertion.assert_eq(Month::new(1), Ok(January))?
  @assertion.assert_eq(Month::new(12), Ok(December))?
}

test "value" {
  @assertion.assert_eq(Month::January.value(), 1)?
  @assertion.assert_eq(Month::February.value(), 2)?
  @assertion.assert_eq(Month::March.value(), 3)?
  @assertion.assert_eq(Month::April.value(), 4)?
  @assertion.assert_eq(Month::May.value(), 5)?
  @assertion.assert_eq(Month::June.value(), 6)?
  @assertion.assert_eq(Month::July.value(), 7)?
  @assertion.assert_eq(Month::August.value(), 8)?
  @assertion.assert_eq(Month::September.value(), 9)?
  @assertion.assert_eq(Month::October.value(), 10)?
  @assertion.assert_eq(Month::November.value(), 11)?
  @assertion.assert_eq(Month::December.value(), 12)?
}

test "length" {
  @assertion.assert_eq(Month::February.length(), 28)?
  @assertion.assert_eq(Month::February.length(~leap_year=true), 29)?
  @assertion.assert_eq(Month::April.length(), 30)?
  @assertion.assert_eq(Month::May.length(), 31)?
}