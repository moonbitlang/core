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

struct PlainDate {
  year : Int
  month : Int
  day : Int
  calendar : Calendar
}

/// Creates a PlainDate from a year, month, day and calendar.
/// The default calendar is ISO 8601 calendar.
pub fn PlainDate::of(
  year : Int,
  month : Int,
  day : Int,
  ~calendar : Calendar = iso_calendar
) -> Result[PlainDate, String] {
  calendar.date_from(year, month, day)
}

/// Creates a PlainDate from an ISO 8601 date string.
pub fn PlainDate::from_string(str : String) -> Result[PlainDate, String] {
  // TODO: better parsing implementation, parse the calendar specified in the string.
  let s = substring(str, 0, 10)
  let ymd = split(s, '-')
  if ymd.length() < 3 {
    return Err(invalid_date_err)
  }
  let y = ymd[0]
  let m = ymd[1]
  let d = ymd[2]
  if y.length() < 4 || m.length() < 2 || d.length() < 2 {
    return Err(invalid_date_err)
  }
  let year = @strconv.parse(y)?
  let month = @strconv.parse(m)?
  let day = @strconv.parse(d)?
  iso_calendar.date_from(year, month, day)
}

pub fn op_equal(self : PlainDate, other : PlainDate) -> Bool {
  self.compare(other) == 0 && self.calendar.get_type() == other.calendar.get_type()
}

pub fn compare(self : PlainDate, other : PlainDate) -> Int {
  if self.year > other.year {
    1
  } else if self.year < other.year {
    -1
  } else if self.month > other.month {
    1
  } else if self.month < other.month {
    -1
  } else if self.day > other.day {
    1
  } else if self.day < other.day {
    -1
  } else {
    0
  }
}

/// Returns the number of years relative to a calendar-specific epoch.
pub fn year(self : PlainDate) -> Int {
  self.calendar.year(self)
}

/// Returns the ordinal number of month in the current year.
pub fn month(self : PlainDate) -> Int {
  self.calendar.month(self)
}

/// Returns the day of the month.
pub fn day(self : PlainDate) -> Int {
  self.calendar.day(self)
}

/// Returns the weekday.
pub fn day_of_week(self : PlainDate) -> DayOfWeek {
  self.calendar.day_of_week(self)
}

/// Returns the ordinal day of the year.
pub fn day_of_year(self : PlainDate) -> Int {
  self.calendar.day_of_year(self)
}

/// Returns the number of days in the week.
pub fn days_in_week(self : PlainDate) -> Int {
  self.calendar.days_in_week(self)
}

/// Returns the number of days in the month.
pub fn days_in_month(self : PlainDate) -> Int {
  self.calendar.days_in_month(self)
}

/// Returns the number of days in the year.
pub fn days_in_year(self : PlainDate) -> Int {
  self.calendar.days_in_year(self)
}

/// Returns the number of months in the year.
pub fn months_in_year(self : PlainDate) -> Int {
  self.calendar.months_in_year(self)
}

/// Checks if the date is in a leap year.
pub fn in_leap_year(self : PlainDate) -> Bool {
  self.calendar.in_leap_year(self)
}

pub fn with_year(self : PlainDate, year : Int) -> Result[PlainDate, String] {
  self.calendar.with_year(self, year)
}

pub fn with_month(self : PlainDate, month : Int) -> Result[PlainDate, String] {
  self.calendar.with_month(self, month)
}

pub fn with_day(self : PlainDate, day : Int) -> Result[PlainDate, String] {
  self.calendar.with_day(self, day)
}

pub fn with_calendar(
  self : PlainDate,
  calendar : Calendar
) -> Result[PlainDate, String] {
  let { year, month, day, .. } = self
  calendar.date_from(year, month, day)
}

pub fn add_years(self : PlainDate, years : Int) -> Result[PlainDate, String] {
  self.calendar.add_years(self, years)
}

pub fn add_months(self : PlainDate, months : Int) -> Result[PlainDate, String] {
  self.calendar.add_months(self, months)
}

pub fn add_days(self : PlainDate, days : Int) -> Result[PlainDate, String] {
  self.calendar.add_days(self, days)
}

pub fn add_period(
  self : PlainDate,
  period : Period
) -> Result[PlainDate, String] {
  self.calendar.add_period(self, period)
}

pub fn get_calendar(self : PlainDate) -> Calendar {
  self.calendar
}

/// Returns a string in the ISO 8601 date format representing the date.
pub fn to_string(self : PlainDate) -> String {
  let buf = Buffer::make(10)
  buf.write_string(add_prefix_zero(self.year.to_string(), 4))
  buf.write_char('-')
  buf.write_string(add_prefix_zero(self.month.to_string(), 2))
  buf.write_char('-')
  buf.write_string(add_prefix_zero(self.day.to_string(), 2))
  if self.calendar.get_type() != CalendarType::ISO8601 {
    buf.write_string("[u-ca=")
    buf.write_string(self.calendar.to_string())
    buf.write_string("]")
  }
  buf.to_string()
}

test "compare" {
  let d1 = PlainDate::of(2000, 1, 1)?
  let d2 = PlainDate::of(2000, 1, 1)?
  let d3 = PlainDate::of(2000, 2, 1)?
  inspect(d1 == d2, content="true")?
  inspect(d1 < d2, content="false")?
  inspect(d1 > d2, content="false")?
  inspect(d1 < d3, content="true")?
  inspect(d1 > d3, content="false")?
  inspect(d3 > d1, content="true")?
  inspect(d3 > d2, content="true")?
}

test "of" {
  inspect(PlainDate::of(2008, 8, 8), content="Ok(2008-08-08)")?
  inspect(PlainDate::of(0, 1, 1), content="Ok(0000-01-01)")?
  inspect(PlainDate::of(1, 1, 1), content="Ok(0001-01-01)")?
  inspect(PlainDate::of(2000, 2, 29), content="Ok(2000-02-29)")?
  inspect(PlainDate::of(2001, 2, 29), content="Err(Invalid date)")?
  inspect(PlainDate::of(2001, 1, 32), content="Err(Invalid date)")?
  inspect(PlainDate::of(10000, 1, 1), content="Err(Invalid date)")?
}

test "from_string" {
  inspect(PlainDate::from_string("2008-08-08"), content="Ok(2008-08-08)")?
  inspect(PlainDate::from_string("0000-01-01"), content="Ok(0000-01-01)")?
  inspect(PlainDate::from_string("0001-01-01"), content="Ok(0001-01-01)")?
  inspect(PlainDate::from_string("10000-01-01"), content="Err(Invalid date)")?
  inspect(PlainDate::from_string("-1970-01-01"), content="Err(Invalid date)")?
  inspect(PlainDate::from_string("-01-01"), content="Err(Invalid date)")?
  inspect(PlainDate::from_string("12-31"), content="Err(Invalid date)")?
  inspect(PlainDate::from_string("-01"), content="Err(Invalid date)")?
}
