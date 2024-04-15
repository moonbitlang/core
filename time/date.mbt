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

struct Date {
  year : Year
  month : Month
  day : DayOfMonth
} derive(Debug, Eq, Compare)

/// Creates a date from year, month, day of month.
pub fn Date::from_ymd(
  year : Int,
  month : Int,
  day : Int
) -> Result[Date, String] {
  create(Year::new(year)?, Month::new(month)?, DayOfMonth::new(day)?)
}

/// Creates a date based on the days from the start of unix epoch.
pub fn Date::from_unix_days(days : Int64) -> Result[Date, String] {
  // TODO: from unix days
  Err("")
}

/// Returns the days from the start of unix epoch.
pub fn to_unix_days(self : Date) -> Int64 {
  // TODO: to unix days
  0L
}

/// Parse a date from a ISO-8601 date string.
pub fn Date::parse(s : String) -> Result[Date, String] {
  let ymd = split(s, '-')
  if ymd.length() < 3 || ymd[0].length() < 4 || ymd[1].length() < 2 || ymd[2].length() <
  2 {
    return Err(invalid_date_err)
  }
  let year = @strconv.parse(remove_prefix_zero(ymd[0]))?
  let month = @strconv.parse(remove_prefix_zero(ymd[1]))?
  let day = @strconv.parse(remove_prefix_zero(ymd[2]))?
  create(Year::new(year)?, Month::new(month)?, DayOfMonth::new(day)?)
}

/// Converts this date to ISO-8601 date string.
pub fn to_string(self : Date) -> String {
  let y = self.year.value().to_string()
  let m = add_prefix_zero(self.month.value().to_string(), 2)
  let d = add_prefix_zero(self.day.value().to_string(), 2)
  let buf = Buffer::make(y.length() + 6)
  buf.write_string(y)
  buf.write_char('-')
  buf.write_string(m)
  buf.write_char('-')
  buf.write_string(d)
  buf.to_string()
}

pub fn year(self : Date) -> Year {
  self.year
}

pub fn month(self : Date) -> Month {
  self.month
}

pub fn day_of_month(self : Date) -> DayOfMonth {
  self.day
}

pub fn length_of_year(self : Date) -> Int {
  self.year.length()
}

pub fn length_of_month(self : Date) -> Int {
  self.month.length(~leap_year=self.year.is_leap_year())
}

pub fn add_years(self : Date, years_to_add : Int) -> Result[Date, String] {
  if years_to_add == 0 {
    Ok(self)
  } else {
    create_from_valid_date(self.year.add(years_to_add)?, self.month, self.day)
  }
}

pub fn add_months(self : Date, months_to_add : Int) -> Result[Date, String] {
  if months_to_add == 0 {
    Ok(self)
  } else {
    let month_count = self.year.value().to_int64() * 12L + (self.month.value().to_int64() -
      1L)
    let new_month_count = month_count + months_to_add.to_int64()
    let new_year = (new_month_count / 12L).to_int()
    let new_month = (new_month_count % 12L).to_int() + 1
    create_from_valid_date(
      Year::new(new_year)?,
      Month::new(new_month)?,
      self.day,
    )
  }
}

pub fn add_days(self : Date, days_to_add : Int) -> Result[Date, String] {
  self.to_unix_days() + days_to_add.to_int64() |> from_unix_days()
}

fn create(year : Year, month : Month, day : DayOfMonth) -> Result[Date, String] {
  if day.value() > 28 && day.value() > month.length(
    ~leap_year=year.is_leap_year(),
  ) {
    return Err(invalid_date_err)
  }
  Ok({ year, month, day })
}

fn create_from_valid_date(
  year : Year,
  month : Month,
  day : DayOfMonth
) -> Result[Date, String] {
  let d = @math.minimum(
    day.value(),
    month.length(~leap_year=year.is_leap_year()),
  )
  Ok({ year, month, day: DayOfMonth::new(d)? })
}

test "from_ymd" {
  @assertion.assert_eq(
    Date::from_ymd(2000, 1, 1),
    Ok({ year: Year(2000), month: January, day: DayOfMonth(1) }),
  )?
  @assertion.assert_eq(Date::from_ymd(2000, 13, 1), Err(month_out_of_range_err))?
  @assertion.assert_eq(Date::from_ymd(2000, 1, 32), Err(dom_out_of_range_err))?
  @assertion.assert_eq(
    Date::from_ymd(2000, 2, 29),
    Ok({ year: Year(2000), month: February, day: DayOfMonth(29) }),
  )?
  @assertion.assert_eq(Date::from_ymd(2001, 2, 29), Err(invalid_date_err))?
  @assertion.assert_eq(Date::from_ymd(2001, 4, 31), Err(invalid_date_err))?
}

test "parse" {
  @assertion.assert_eq(
    Date::parse("2000-01-01"),
    Ok({ year: Year(2000), month: January, day: DayOfMonth(1) }),
  )?
  @assertion.assert_eq(
    Date::parse("0500-01-01"),
    Ok({ year: Year(500), month: January, day: DayOfMonth(1) }),
  )?
  @assertion.assert_eq(Date::parse("2000"), Err(invalid_date_err))?
  @assertion.assert_eq(Date::parse("2000-01"), Err(invalid_date_err))?
  @assertion.assert_eq(Date::parse("2000-01-1"), Err(invalid_date_err))?
  @assertion.assert_eq(Date::parse("2000-1-01"), Err(invalid_date_err))?
}

test "to_string" {
  let date = { year: Year(2000), month: January, day: DayOfMonth(1) }
  inspect(date.to_string(), ~content="2000-01-01")?
}

test "getters" {
  let date = { year: Year(2000), month: January, day: DayOfMonth(1) }
  @assertion.assert_eq(date.year(), Year(2000))?
  @assertion.assert_eq(date.month(), January)?
  @assertion.assert_eq(date.day_of_month(), DayOfMonth(1))?
}

test "length_of_year" {
  @assertion.assert_eq(Date::from_ymd(2000, 2, 1)?.length_of_year(), 366)?
  @assertion.assert_eq(Date::from_ymd(2001, 2, 1)?.length_of_year(), 365)?
}

test "length_of_month" {
  @assertion.assert_eq(Date::from_ymd(2000, 2, 1)?.length_of_month(), 29)?
  @assertion.assert_eq(Date::from_ymd(2001, 2, 1)?.length_of_month(), 28)?
  @assertion.assert_eq(Date::from_ymd(2000, 3, 1)?.length_of_month(), 31)?
  @assertion.assert_eq(Date::from_ymd(2000, 4, 1)?.length_of_month(), 30)?
}

test "compare_eq" {
  let d1 = Date::from_ymd(2000, 1, 31)?
  let d2 = Date::from_ymd(2000, 2, 1)?
  let d3 = Date::from_ymd(1999, 12, 31)?
  let d4 = Date::from_ymd(2000, 2, 1)?
  @assertion.assert_true(d1 < d2)?
  @assertion.assert_true(d1 > d3)?
  @assertion.assert_true(d2 == d4)?
}

test "add_years" {
  @assertion.assert_eq(
    Date::from_ymd(2000, 1, 1)?.add_years(10)?,
    Date::from_ymd(2010, 1, 1)?,
  )?
  @assertion.assert_eq(
    Date::from_ymd(2000, 1, 1)?.add_years(-10)?,
    Date::from_ymd(1990, 1, 1)?,
  )?
  @assertion.assert_eq(
    Date::from_ymd(2000, 2, 29)?.add_years(1)?,
    Date::from_ymd(2001, 2, 28)?,
  )?
}

test "add_months" {
  @assertion.assert_eq(
    Date::from_ymd(2000, 1, 1)?.add_months(1)?,
    Date::from_ymd(2000, 2, 1)?,
  )?
  @assertion.assert_eq(
    Date::from_ymd(2000, 2, 1)?.add_months(-1)?,
    Date::from_ymd(2000, 1, 1)?,
  )?
  @assertion.assert_eq(
    Date::from_ymd(2000, 12, 1)?.add_months(1)?,
    Date::from_ymd(2001, 1, 1)?,
  )?
  @assertion.assert_eq(
    Date::from_ymd(2000, 2, 29)?.add_months(12)?,
    Date::from_ymd(2001, 2, 28)?,
  )?
  @assertion.assert_eq(
    Date::from_ymd(2000, 3, 31)?.add_months(1)?,
    Date::from_ymd(2000, 4, 30)?,
  )?
}