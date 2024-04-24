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

type IsoCalendar String derive(Debug, Eq, Show)

let iso_calendar : Calendar = IsoCalendar::IsoCalendar("iso8601")

let iso_min_year = 0

let iso_max_year = 9999

let iso_min_month = 1

let iso_max_month = 12

let iso_min_day = 1

let iso_max_day = 31

let iso_days_per_400_years : Int64 = 400L * 365L + 97L

let iso_days_per_100_years : Int64 = 100L * 365L + 24L

let iso_days_per_4_years : Int64 = 4L * 365L + 1L

pub fn IsoCalendar::get_type(_self : IsoCalendar) -> CalendarType {
  CalendarType::ISO8601
}

pub fn IsoCalendar::era(_self : IsoCalendar, date : PlainDate) -> String {
  if date.year >= 1 {
    "CE"
  } else {
    "BCE"
  }
}

pub fn IsoCalendar::era_year(_self : IsoCalendar, date : PlainDate) -> Int {
  if date.year <= 0 {
    date.year.abs() + 1
  } else {
    date.year
  }
}

pub fn IsoCalendar::year(_self : IsoCalendar, date : PlainDate) -> Int {
  date.year
}

pub fn IsoCalendar::month(_self : IsoCalendar, date : PlainDate) -> Int {
  date.month
}

pub fn IsoCalendar::day(_self : IsoCalendar, date : PlainDate) -> Int {
  date.day
}

pub fn IsoCalendar::day_of_week(
  _self : IsoCalendar,
  date : PlainDate
) -> DayOfWeek {
  // Zeller's congruence
  // https://en.wikipedia.org/wiki/Zeller%27s_congruence
  let mut y = date.year
  let mut m = date.month
  let q = date.day
  if m < 3 {
    m += 12
    y -= 1
  }
  let k = y % 100
  let j = y / 100
  let h = (q + 13 * (m + 1) / 5 + k + k / 4 + j / 4 + 5 * j) % 7
  let week_day = (h + 5) % 7 + 1
  DayOfWeek::new(week_day).unwrap()
}

pub fn IsoCalendar::day_of_year(_self : IsoCalendar, date : PlainDate) -> Int {
  let days = date_to_fixed_days(date.year, date.month, date.day)
  let (_, ordinal) = fixed_days_to_year_ord(days)
  ordinal
}

pub fn IsoCalendar::days_in_week(_self : IsoCalendar, _date : PlainDate) -> Int {
  7
}

pub fn IsoCalendar::days_in_month(_self : IsoCalendar, date : PlainDate) -> Int {
  let { year, month, .. } = date
  iso_days_in_month(year, month)
}

pub fn IsoCalendar::days_in_year(_self : IsoCalendar, date : PlainDate) -> Int {
  if iso_leap_year(date.year) {
    366
  } else {
    365
  }
}

pub fn IsoCalendar::months_in_year(
  _self : IsoCalendar,
  _date : PlainDate
) -> Int {
  12
}

pub fn IsoCalendar::in_leap_year(_self : IsoCalendar, date : PlainDate) -> Bool {
  let { year, .. } = date
  iso_leap_year(year)
}

pub fn date_from(
  self : IsoCalendar,
  year : Int,
  month : Int,
  day : Int
) -> Result[PlainDate, String] {
  if not(iso_validate(year, month, day)) {
    return Err(invalid_date_err)
  }
  Ok(PlainDate::{ year, month, day, calendar: self })
}

fn date_from_valid(year : Int, month : Int, day : Int) -> PlainDate {
  let mut d = day
  let max_day = iso_days_in_month(year, month)
  if d > max_day {
    d = max_day
  }
  PlainDate::{ year, month, day: d, calendar: iso_calendar }
}

pub fn IsoCalendar::add_years(
  _self : IsoCalendar,
  date : PlainDate,
  years : Int
) -> Result[PlainDate, String] {
  if years == 0 {
    return Ok(date)
  }
  let new_year = checked_add_int(date.year, years)?
  if iso_validate_year(new_year) {
    let new_date = date_from_valid(new_year, date.month, date.day)
    Ok(new_date)
  } else {
    Err(invalid_date_err)
  }
}

pub fn IsoCalendar::add_months(
  _self : IsoCalendar,
  date : PlainDate,
  months : Int
) -> Result[PlainDate, String] {
  if months == 0 {
    return Ok(date)
  }
  let total_months = date.year * 12 + (date.month - 1)
  let new_total_months = checked_add_int(total_months, months)?
  let new_year = new_total_months / 12
  let new_month = new_total_months % 12 + 1
  if iso_validate_year(new_year) && iso_validate_month(new_month) {
    let new_date = date_from_valid(new_year, new_month, date.day)
    Ok(new_date)
  } else {
    Err(invalid_date_err)
  }
}

pub fn add_weeks(
  self : IsoCalendar,
  date : PlainDate,
  weeks : Int
) -> Result[PlainDate, String] {
  if weeks == 0 {
    return Ok(date)
  }
  let days_to_add = checked_mul_int(weeks, 7)?
  self.add_days(date, days_to_add)
}

pub fn add_days(
  self : IsoCalendar,
  date : PlainDate,
  days : Int
) -> Result[PlainDate, String] {
  if days == 0 {
    return Ok(date)
  }
  let fixed_days = date_to_fixed_days(date.year, date.month, date.day)
  let new_days = checked_add_int64(fixed_days, days.to_int64())?
  let (y, m, d, _) = fixed_days_to_date(new_days)
  self.date_from(y, m, d)
}

pub fn add_period(
  self : IsoCalendar,
  date : PlainDate,
  period : Period
) -> Result[PlainDate, String] {
  let mut d = date
  if period.years != 0 {
    d = self.add_years(d, period.years)?
  }
  if period.months != 0 {
    d = self.add_months(d, period.months)?
  }
  if period.days != 0 {
    d = self.add_days(d, period.days)?
  }
  Ok(d)
}

pub fn IsoCalendar::with_year(
  _self : IsoCalendar,
  date : PlainDate,
  year : Int
) -> Result[PlainDate, String] {
  if date.year == year {
    return Ok(date)
  }
  if iso_validate_year(year) {
    let new_date = date_from_valid(year, date.month, date.day)
    Ok(new_date)
  } else {
    Err(invalid_date_err)
  }
}

pub fn IsoCalendar::with_month(
  _self : IsoCalendar,
  date : PlainDate,
  month : Int
) -> Result[PlainDate, String] {
  if date.month == month {
    return Ok(date)
  }
  if iso_validate_month(month) {
    let new_date = date_from_valid(date.year, month, date.day)
    Ok(new_date)
  } else {
    Err(invalid_date_err)
  }
}

pub fn IsoCalendar::with_day(
  _self : IsoCalendar,
  date : PlainDate,
  day : Int
) -> Result[PlainDate, String] {
  if date.day == day {
    return Ok(date)
  }
  if iso_validate_day(date.year, date.month, day) {
    let new_date = date_from_valid(date.year, date.month, day)
    Ok(new_date)
  } else {
    Err(invalid_date_err)
  }
}

pub fn until(
  self : IsoCalendar,
  start : PlainDate,
  end : PlainDate
) -> Result[Period, String] {
  let start_months = start.year * 12 + start.month - 1
  let end_months = end.year * 12 + end.month - 1
  let mut total_months = end_months - start_months
  let mut days = end.day - start.day
  if total_months > 0 && days < 0 {
    total_months -= 1
    let d = self.add_months(start, total_months)?
    let end_days = date_to_fixed_days(end.year, end.month, end.day)
    days = (end_days - date_to_fixed_days(d.year, d.month, d.day)).to_int()
  } else if total_months < 0 && days > 0 {
    total_months += 1
    days -= self.days_in_month(end)
  }
  let years = total_months / 12
  let months = total_months % 12
  Ok(Period::of(~years, ~months, ~days))
}

fn iso_leap_year(year : Int) -> Bool {
  year % 4 == 0 && year % 100 != 0 || year % 400 == 0
}

fn iso_days_in_month(year : Int, month : Int) -> Int {
  let leap = iso_leap_year(year)
  match month {
    2 => if leap { 29 } else { 28 }
    1 | 3 | 5 | 7 | 8 | 10 | 12 => 31
    _ => 30
  }
}

fn date_to_fixed_days(year : Int, month : Int, day : Int) -> Int64 {
  let mut days = 0L
  // year days
  let y = (year - 1).to_int64()
  let non_leap = 365L * y
  days += non_leap
  let leap = y / 4L - y / 100L + y / 400L
  days += leap
  // month days
  days += (367L * month.to_int64() - 362L) / 12L
  if month > 2 {
    days += if iso_leap_year(year) { -1L } else { -2L }
  }
  days += day.to_int64()
  days
}

fn fixed_days_to_year_ord(days : Int64) -> (Int, Int) {
  let d0 = days - 1L
  // calculate year
  let n400 = d0 / iso_days_per_400_years
  let d1 = d0 % iso_days_per_400_years
  let n100 = d1 / iso_days_per_100_years
  let d2 = d1 % iso_days_per_100_years
  let n4 = d2 / iso_days_per_4_years
  let d3 = d2 % iso_days_per_4_years
  let n1 = d3 / 365L
  let mut year = 400 * n400.to_int() + 100 * n100.to_int() + 4 * n4.to_int() + n1.to_int()
  if not(n100 == 4L || n1 == 4L) {
    year += 1
  }
  let ordinal = if n1 != 4L && n100 != 4L {
    (d3 % 365L + 1L).to_int()
  } else {
    366
  }
  (year, ordinal)
}

fn fixed_days_to_date(days : Int64) -> (Int, Int, Int, Int) {
  let (year, ordinal) = fixed_days_to_year_ord(days)
  let prior_days = (days - date_to_fixed_days(year, 1, 1)).to_int()
  let correction = if days < date_to_fixed_days(year, 3, 1) {
    0
  } else if iso_leap_year(year) {
    1
  } else {
    2
  }
  let month = (12 * (prior_days + correction) + 373) / 367
  let day = (days - date_to_fixed_days(year, month, 1)).to_int() + 1
  (year, month, day, ordinal)
}

fn iso_validate(year : Int, month : Int, day : Int) -> Bool {
  iso_validate_year(year) && iso_validate_month(month) && iso_validate_day(
    year, month, day,
  )
}

fn iso_validate_year(year : Int) -> Bool {
  year >= iso_min_year && year <= iso_max_year
}

fn iso_validate_month(month : Int) -> Bool {
  month >= iso_min_month && month <= iso_max_month
}

fn iso_validate_day(year : Int, month : Int, day : Int) -> Bool {
  day >= iso_min_day && day <= iso_max_day && day <= iso_days_in_month(
    year, month,
  )
}
