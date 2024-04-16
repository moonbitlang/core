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
} derive(Debug, Eq, Show, Compare)

let min_month : Int = 1

let max_month : Int = 12

pub fn Month::new(month : Int) -> Result[Month, String] {
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

pub fn value(self : Month) -> Int {
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

pub fn add(self : Month, months : Int) -> Month {
  match Month::new((self.value() + months - 1) % 12 + 1) {
    Ok(m) => m
    _ => abort("add months error")
  }
}

pub fn first_day_of_year(self : Month, ~leap_year : Bool = false) -> Int {
  let leap_day = if leap_year { 1 } else { 0 }
  match self {
    January => 1
    February => 32
    March => 60 + leap_day
    April => 91 + leap_day
    May => 121 + leap_day
    June => 152 + leap_day
    July => 182 + leap_day
    August => 213 + leap_day
    September => 244 + leap_day
    October => 274 + leap_day
    November => 305 + leap_day
    December => 335 + leap_day
  }
}

test "new" {
  @assertion.assert_eq(Month::new(0), Err(month_out_of_range_err))?
  @assertion.assert_eq(Month::new(13), Err(month_out_of_range_err))?
  @assertion.assert_eq(Month::new(1), Ok(January))?
  @assertion.assert_eq(Month::new(2), Ok(February))?
  @assertion.assert_eq(Month::new(3), Ok(March))?
  @assertion.assert_eq(Month::new(4), Ok(April))?
  @assertion.assert_eq(Month::new(5), Ok(May))?
  @assertion.assert_eq(Month::new(6), Ok(June))?
  @assertion.assert_eq(Month::new(7), Ok(July))?
  @assertion.assert_eq(Month::new(8), Ok(August))?
  @assertion.assert_eq(Month::new(9), Ok(September))?
  @assertion.assert_eq(Month::new(10), Ok(October))?
  @assertion.assert_eq(Month::new(11), Ok(November))?
  @assertion.assert_eq(Month::new(12), Ok(December))?
}

test "value" {
  inspect(Month::January.value(), ~content="1")?
  inspect(Month::February.value(), ~content="2")?
  inspect(Month::March.value(), ~content="3")?
  inspect(Month::April.value(), ~content="4")?
  inspect(Month::May.value(), ~content="5")?
  inspect(Month::June.value(), ~content="6")?
  inspect(Month::July.value(), ~content="7")?
  inspect(Month::August.value(), ~content="8")?
  inspect(Month::September.value(), ~content="9")?
  inspect(Month::October.value(), ~content="10")?
  inspect(Month::November.value(), ~content="11")?
  inspect(Month::December.value(), ~content="12")?
}

test "length" {
  inspect(Month::February.length(), ~content="28")?
  inspect(Month::February.length(leap_year=true), ~content="29")?
  inspect(Month::April.length(), ~content="30")?
  inspect(Month::May.length(), ~content="31")?
}

test "add" {
  let m = Month::January
  inspect(m.add(1), ~content="February")?
  inspect(m.add(2), ~content="March")?
  inspect(m.add(3), ~content="April")?
  inspect(m.add(4), ~content="May")?
  inspect(m.add(5), ~content="June")?
  inspect(m.add(6), ~content="July")?
  inspect(m.add(7), ~content="August")?
  inspect(m.add(8), ~content="September")?
  inspect(m.add(9), ~content="October")?
  inspect(m.add(10), ~content="November")?
  inspect(m.add(11), ~content="December")?
  inspect(m.add(12), ~content="January")?
}

test "first_day_of_year" {
  inspect(Month::January.first_day_of_year(), ~content="1")?
  inspect(Month::February.first_day_of_year(), ~content="32")?
  inspect(Month::March.first_day_of_year(), ~content="60")?
  inspect(Month::April.first_day_of_year(), ~content="91")?
  inspect(Month::May.first_day_of_year(), ~content="121")?
  inspect(Month::June.first_day_of_year(), ~content="152")?
  inspect(Month::July.first_day_of_year(), ~content="182")?
  inspect(Month::August.first_day_of_year(), ~content="213")?
  inspect(Month::September.first_day_of_year(), ~content="244")?
  inspect(Month::October.first_day_of_year(), ~content="274")?
  inspect(Month::November.first_day_of_year(), ~content="305")?
  inspect(Month::December.first_day_of_year(), ~content="335")?
}
