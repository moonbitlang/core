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

pub fn PlainDate::from(
  year : Int,
  month : Int,
  day : Int,
  ~calendar : Calendar = calendar_of(ISO8601)
) -> Result[PlainDate, String] {
  calendar.date_from(year, month, day)
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
