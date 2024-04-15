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

// The number of days per 400 years.
// There are 97 leap years in a 400 years cycle.
let days_400_years : Int64 = 400L * 365L + 97L

// The number of days from the first year of C.E. to unix epoch. 2000 years - 30 years.
// There are 7 leap years from 1970 to 2000.
let days_ce_start_to_unix_epoch : Int64 = days_400_years * 5L - (30L * 365L + 7L)

let min_date : Date = {
  year: Year(min_year),
  month: Month::January,
  day: DayOfMonth(1),
}

let max_date : Date = {
  year: Year(max_year),
  month: Month::December,
  day: DayOfMonth(31),
}

let unix_epoch_date : Date = {
  year: Year(1970),
  month: Month::January,
  day: DayOfMonth(1),
}

let min_unix_days : Int64 = -365243219162L

let max_unix_days : Int64 = 365241780471L

// Days offset per year in a 400 years cycle.
let total_days_offset : Array[Int] = [
  0, 1, 1, 1, 1, 2, 2, 2, 2, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6, 6, 7, 7,
  7, 7, 8, 8, 8, 8, 9, 9, 9, 9, 10, 10, 10, 10, 11, 11, 11, 11, 12, 12, 12, 12, 13,
  13, 13, 13, 14, 14, 14, 14, 15, 15, 15, 15, 16, 16, 16, 16, 17, 17, 17, 17, 18,
  18, 18, 18, 19, 19, 19, 19, 20, 20, 20, 20, 21, 21, 21, 21, 22, 22, 22, 22, 23,
  23, 23, 23, 24, 24, 24, 24, 25, 25, 25, // 100
   25, 25, 25, 25, 25, 26, 26, 26, 26, 27, 27, 27, 27, 28, 28, 28, 28, 29, 29, 29,
  29, 30, 30, 30, 30, 31, 31, 31, 31, 32, 32, 32, 32, 33, 33, 33, 33, 34, 34, 34,
  34, 35, 35, 35, 35, 36, 36, 36, 36, 37, 37, 37, 37, 38, 38, 38, 38, 39, 39, 39,
  39, 40, 40, 40, 40, 41, 41, 41, 41, 42, 42, 42, 42, 43, 43, 43, 43, 44, 44, 44,
  44, 45, 45, 45, 45, 46, 46, 46, 46, 47, 47, 47, 47, 48, 48, 48, 48, 49, 49, 49, // 200
   49, 49, 49, 49, 49, 50, 50, 50, 50, 51, 51, 51, 51, 52, 52, 52, 52, 53, 53, 53,
  53, 54, 54, 54, 54, 55, 55, 55, 55, 56, 56, 56, 56, 57, 57, 57, 57, 58, 58, 58,
  58, 59, 59, 59, 59, 60, 60, 60, 60, 61, 61, 61, 61, 62, 62, 62, 62, 63, 63, 63,
  63, 64, 64, 64, 64, 65, 65, 65, 65, 66, 66, 66, 66, 67, 67, 67, 67, 68, 68, 68,
  68, 69, 69, 69, 69, 70, 70, 70, 70, 71, 71, 71, 71, 72, 72, 72, 72, 73, 73, 73, // 300
   73, 73, 73, 73, 73, 74, 74, 74, 74, 75, 75, 75, 75, 76, 76, 76, 76, 77, 77, 77,
  77, 78, 78, 78, 78, 79, 79, 79, 79, 80, 80, 80, 80, 81, 81, 81, 81, 82, 82, 82,
  82, 83, 83, 83, 83, 84, 84, 84, 84, 85, 85, 85, 85, 86, 86, 86, 86, 87, 87, 87,
  87, 88, 88, 88, 88, 89, 89, 89, 89, 90, 90, 90, 90, 91, 91, 91, 91, 92, 92, 92,
  92, 93, 93, 93, 93, 94, 94, 94, 94, 95, 95, 95, 95, 96, 96, 96, 96, 97, 97, 97,
  97, // 400+1
]

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

/// Creates a date from year and day of year.
pub fn Date::from_yd(year : Int, day_of_year : Int) -> Result[Date, String] {
  let year = Year::new(year)?
  let leap = year.is_leap_year()
  if not(DayOfYear::valid(day_of_year)) || day_of_year == 366 && not(leap) {
    return Err(doy_out_of_range_err)
  }
  let mut month = Month::new((day_of_year - 1) / 31 + 1)?
  let month_end = month.first_day_of_year(leap_year=leap) + month.length(
      leap_year=leap,
    ) - 1
  if day_of_year > month_end {
    month = month.add(1)?
  }
  let day_of_month = DayOfMonth::new(
    day_of_year - month.first_day_of_year(leap_year=leap) + 1,
  )?
  create(year, month, day_of_month)
}

/// Creates a date based on the days from the start of unix epoch.
pub fn Date::from_unix_days(days : Int64) -> Result[Date, String] {
  if days < min_unix_days || days > max_unix_days {
    return Err(unix_days_out_of_range_err)
  }
  let mut ce_days = days + days_ce_start_to_unix_epoch
  // make days non-negative
  let mut year_offset = 0
  if ce_days < 0L {
    let c = (ce_days + 1L) / days_400_years - 1L
    year_offset = c.to_int() * 400
    ce_days += c * -days_400_years
  }
  let full_cycles = (ce_days / days_400_years).to_int()
  let cycle = (ce_days % days_400_years).to_int()
  let (y, doy) = cycle_to_yd(cycle)
  Date::from_yd(y + full_cycles * 400 + year_offset, doy)
}

fn cycle_to_yd(cycle : Int) -> (Int, Int) {
  let mut year = cycle / 365
  let mut day_of_year = cycle % 365
  let offset = total_days_offset[year]
  if day_of_year < offset {
    year -= 1
    day_of_year += 365 - total_days_offset[year]
  } else {
    day_of_year -= offset
  }
  (year, day_of_year + 1)
}

/// Returns the days from the start of unix epoch to this date.
pub fn to_unix_days(self : Date) -> Int64 {
  let y = self.year.value().to_int64()
  let mut total_days = 365L * y
  // calculate the leap days
  if y > 0L {
    total_days += (y + 3L) / 4L - (y + 99L) / 100L + (y + 399L) / 400L
  } else {
    total_days -= y / -4L - y / -100L + y / -400L
  }
  total_days += self.day_of_year().to_int64() - 1L
  total_days - days_ce_start_to_unix_epoch
}

/// Parse a date from a ISO-8601 date string.
pub fn Date::parse(str : String) -> Result[Date, String] {
  let mut s = str
  let mut neg = false
  if s[0] == '-' {
    neg = true
    s = substring(s, 1, s.length() - 1)
  }
  let ymd = split(s, '-')
  if ymd.length() < 3 || ymd[0].length() < 4 || ymd[1].length() < 2 || ymd[2].length() <
  2 {
    return Err(invalid_date_err)
  }
  if neg {
    ymd[0] = "-" + ymd[0]
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

pub fn day_of_year(self : Date) -> Int {
  self.month.first_day_of_year(leap_year=self.year.is_leap_year()) + self.day.value() -
  1
}

pub fn day_of_week(self : Date) -> DayOfWeek {
  // Zeller's congruence
  // https://en.wikipedia.org/wiki/Zeller%27s_congruence
  let mut y = self.year.value()
  let mut m = self.month.value()
  let q = self.day.value()
  if m < 3 {
    m += 12
    y -= 1
  }
  let k = y % 100
  let j = y / 100
  let h = (q + 13 * (m + 1) / 5 + k + k / 4 + j / 4 + 5 * j) % 7
  let dow = (h + 5) % 7 + 1
  DayOfWeek::new_exact(dow)
}

pub fn length_of_year(self : Date) -> Int {
  self.year.length()
}

pub fn length_of_month(self : Date) -> Int {
  self.month.length(leap_year=self.year.is_leap_year())
}

pub fn is_leap_year(self : Date) -> Bool {
  self.year.is_leap_year()
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
    return Ok(self)
  }
  let month_count = self.year.value().to_int64() * 12L + (self.month.value().to_int64() -
    1L)
  let new_month_count = month_count + months_to_add.to_int64()
  let new_year = (new_month_count / 12L).to_int()
  let new_month = (new_month_count % 12L).to_int() + 1
  create_from_valid_date(Year::new(new_year)?, Month::new(new_month)?, self.day)
}

pub fn add_days(self : Date, days_to_add : Int) -> Result[Date, String] {
  if days_to_add == 0 {
    return Ok(self)
  }
  // TODO: some short path
  match checked_add(self.to_unix_days(), days_to_add.to_int64()) {
    Some(n) => n |> from_unix_days()
    None => Err(days_overflow_err)
  }
}

pub fn add_weeks(self : Date, weeks_to_add : Int) -> Result[Date, String] {
  match checked_mul(weeks_to_add, 7) {
    Some(d) => self.add_days(d)
    None => Err(days_overflow_err)
  }
}

pub fn with_year(self : Date, year : Int) -> Result[Date, String] {
  if self.year.value() == year {
    return Ok(self)
  }
  create_from_valid_date(Year::new(year)?, self.month, self.day)
}

pub fn with_month(self : Date, month : Int) -> Result[Date, String] {
  if self.month.value() == month {
    return Ok(self)
  }
  create_from_valid_date(self.year, Month::new(month)?, self.day)
}

pub fn with_day_of_month(
  self : Date,
  day_of_month : Int
) -> Result[Date, String] {
  if self.day.value() == day_of_month {
    return Ok(self)
  }
  create(self.year, self.month, DayOfMonth::new(day_of_month)?)
}

pub fn with_day_of_year(self : Date, day_of_year : Int) -> Result[Date, String] {
  Date::from_yd(self.year.value(), day_of_year)
}

pub fn hash(self : Date) -> Int {
  // TODO: better hash
  let y = self.year.value()
  let m = self.month.value()
  let d = self.day.value()
  y.lsl(11) + m.lsl(6) + d
}

fn create(year : Year, month : Month, day : DayOfMonth) -> Result[Date, String] {
  if day.value() > 28 && day.value() > month.length(
    leap_year=year.is_leap_year(),
  ) {
    return Err(dom_out_of_range_err)
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
    month.length(leap_year=year.is_leap_year()),
  )
  Ok({ year, month, day: DayOfMonth::new(d)? })
}

test "from_ymd" {
  @assertion.assert_eq(
    Date::from_ymd(2000, 1, 1),
    Ok({ year: Year(2000), month: January, day: DayOfMonth(1) }),
  )?
  @assertion.assert_eq(Date::from_ymd(min_year, 1, 1), Ok(min_date))?
  @assertion.assert_eq(Date::from_ymd(max_year, 12, 31), Ok(max_date))?
  @assertion.assert_eq(Date::from_ymd(2000, 13, 1), Err(month_out_of_range_err))?
  @assertion.assert_eq(Date::from_ymd(2000, 1, 32), Err(dom_out_of_range_err))?
  @assertion.assert_eq(
    Date::from_ymd(2000, 2, 29),
    Ok({ year: Year(2000), month: February, day: DayOfMonth(29) }),
  )?
  @assertion.assert_eq(Date::from_ymd(2001, 2, 29), Err(dom_out_of_range_err))?
  @assertion.assert_eq(Date::from_ymd(2001, 4, 31), Err(dom_out_of_range_err))?
}

test "from_yd" {
  @assertion.assert_eq(
    Date::from_yd(2000, 1),
    Ok({ year: Year(2000), month: January, day: DayOfMonth(1) }),
  )?
  @assertion.assert_eq(
    Date::from_yd(2000, 366),
    Ok({ year: Year(2000), month: December, day: DayOfMonth(31) }),
  )?
  @assertion.assert_eq(
    Date::from_yd(2001, 365),
    Ok({ year: Year(2001), month: December, day: DayOfMonth(31) }),
  )?
  @assertion.assert_eq(Date::from_yd(min_year, 1), Ok(min_date))?
  @assertion.assert_eq(Date::from_yd(max_year, 365), Ok(max_date))?
  @assertion.assert_eq(Date::from_yd(2001, 366), Err(doy_out_of_range_err))?
}

test "from_unix_days" {
  @assertion.assert_eq(Date::from_unix_days(0L), Ok(unix_epoch_date))?
  @assertion.assert_eq(Date::from_unix_days(min_unix_days), Ok(min_date))?
  @assertion.assert_eq(Date::from_unix_days(max_unix_days), Ok(max_date))?
  @assertion.assert_eq(
    Date::from_unix_days(365L * 30L + 7L),
    Ok({ year: Year(2000), month: Month::January, day: DayOfMonth(1) }),
  )?
  @assertion.assert_eq(
    Date::from_unix_days(-1L),
    Ok({ year: Year(1969), month: Month::December, day: DayOfMonth(31) }),
  )?
  @assertion.assert_eq(
    Date::from_unix_days(min_unix_days - 1L),
    Err(unix_days_out_of_range_err),
  )?
  @assertion.assert_eq(
    Date::from_unix_days(max_unix_days + 1L),
    Err(unix_days_out_of_range_err),
  )?
}

test "to_unix_days" {
  inspect(Date::from_ymd(1970, 1, 1)?.to_unix_days(), content="0")?
  inspect(Date::from_ymd(1970, 1, 2)?.to_unix_days(), content="1")?
  inspect(Date::from_ymd(1969, 12, 31)?.to_unix_days(), content="-1")?
  inspect(
    Date::from_ymd(min_year, 1, 1)?.to_unix_days(),
    content="-365243219162",
  )?
  inspect(
    Date::from_ymd(max_year, 12, 31)?.to_unix_days(),
    content="365241780471",
  )?
}

test "parse" {
  @assertion.assert_eq(Date::parse("-999999999-01-01"), Ok(min_date))?
  @assertion.assert_eq(Date::parse("999999999-12-31"), Ok(max_date))?
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
  @assertion.assert_eq(Date::parse("-2000-1"), Err(invalid_date_err))?
}

test "to_string" {
  let date = { year: Year(2000), month: January, day: DayOfMonth(1) }
  inspect(date.to_string(), content="2000-01-01")?
}

test "getters" {
  let date = { year: Year(2000), month: February, day: DayOfMonth(1) }
  @assertion.assert_eq(date.year(), Year(2000))?
  @assertion.assert_eq(date.month(), February)?
  @assertion.assert_eq(date.day_of_month(), DayOfMonth(1))?
  @assertion.assert_eq(date.day_of_year(), 32)?
}

test "day_of_week" {
  inspect(Date::from_ymd(2000, 1, 1)?.day_of_week(), content="Saturday")?
  inspect(Date::from_ymd(2000, 1, 2)?.day_of_week(), content="Sunday")?
  inspect(Date::from_ymd(2000, 1, 3)?.day_of_week(), content="Monday")?
  inspect(Date::from_ymd(2000, 1, 4)?.day_of_week(), content="Tuesday")?
  inspect(Date::from_ymd(2000, 1, 5)?.day_of_week(), content="Wednesday")?
  inspect(Date::from_ymd(2000, 1, 6)?.day_of_week(), content="Thursday")?
  inspect(Date::from_ymd(2000, 1, 7)?.day_of_week(), content="Friday")?
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

test "is_leap_year" {
  @assertion.assert_true(Date::from_ymd(2000, 1, 1)?.is_leap_year())?
  @assertion.assert_false(Date::from_ymd(2001, 1, 1)?.is_leap_year())?
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
    Date::from_ymd(2000, 1, 1)?.add_years(0)?,
    Date::from_ymd(2000, 1, 1)?,
  )?
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
    Date::from_ymd(2000, 1, 1)?.add_months(0)?,
    Date::from_ymd(2000, 1, 1)?,
  )?
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
}

test "add_days" {
  @assertion.assert_eq(
    Date::from_ymd(2000, 1, 1)?.add_days(1)?,
    Date::from_ymd(2000, 1, 2)?,
  )?
  @assertion.assert_eq(
    Date::from_ymd(2000, 2, 29)?.add_days(365)?,
    Date::from_ymd(2001, 2, 28)?,
  )?
}

test "add_weeks" {
  @assertion.assert_eq(
    Date::from_ymd(2000, 1, 1)?.add_weeks(1)?,
    Date::from_ymd(2000, 1, 8)?,
  )?
  @assertion.assert_eq(
    Date::from_ymd(2000, 1, 1)?.add_weeks(1000000000),
    Err(days_overflow_err),
  )?
}

test "with_year" {
  let d = unix_epoch_date
  @assertion.assert_eq(
    d.with_year(2000),
    Ok({ year: Year(2000), month: Month::January, day: DayOfMonth(1) }),
  )?
  @assertion.assert_eq(
    d.with_year(max_year),
    Ok({ year: Year(max_year), month: Month::January, day: DayOfMonth(1) }),
  )?
  @assertion.assert_eq(
    d.with_year(min_year),
    Ok({ year: Year(min_year), month: Month::January, day: DayOfMonth(1) }),
  )?
  @assertion.assert_eq(d.with_year(max_year + 1), Err(year_out_of_range_err))?
  @assertion.assert_eq(d.with_year(min_year - 1), Err(year_out_of_range_err))?
}

test "with_month" {
  let d = unix_epoch_date
  @assertion.assert_eq(
    d.with_month(2),
    Ok({ year: Year(1970), month: Month::February, day: DayOfMonth(1) }),
  )?
  @assertion.assert_eq(
    d.with_month(max_month),
    Ok({ year: Year(1970), month: Month::December, day: DayOfMonth(1) }),
  )?
  @assertion.assert_eq(
    d.with_month(min_month),
    Ok({ year: Year(1970), month: Month::January, day: DayOfMonth(1) }),
  )?
  @assertion.assert_eq(d.with_month(max_month + 1), Err(month_out_of_range_err))?
  @assertion.assert_eq(d.with_month(min_month - 1), Err(month_out_of_range_err))?
  let d1 = Date::from_ymd(1970, 1, 31)?
  @assertion.assert_eq(
    d1.with_month(2),
    Ok({ year: Year(1970), month: Month::February, day: DayOfMonth(28) }),
  )?
  let d2 = Date::from_ymd(2000, 1, 31)?
  @assertion.assert_eq(
    d2.with_month(2),
    Ok({ year: Year(2000), month: Month::February, day: DayOfMonth(29) }),
  )?
}

test "with_day_of_month" {
  let d = unix_epoch_date
  @assertion.assert_eq(
    d.with_day_of_month(31),
    Ok({ year: Year(1970), month: Month::January, day: DayOfMonth(31) }),
  )?
  @assertion.assert_eq(d.with_day_of_month(32), Err(dom_out_of_range_err))?
  let d2 = Date::from_ymd(2000, 2, 1)?
  @assertion.assert_eq(
    d2.with_day_of_month(29),
    Ok({ year: Year(2000), month: Month::February, day: DayOfMonth(29) }),
  )?
  let d3 = Date::from_ymd(2001, 2, 1)?
  @assertion.assert_eq(
    d3.with_day_of_month(28),
    Ok({ year: Year(2001), month: Month::February, day: DayOfMonth(28) }),
  )?
  @assertion.assert_eq(d3.with_day_of_month(29), Err(dom_out_of_range_err))?
}

test "with_day_of_year" {
  let d = unix_epoch_date
  @assertion.assert_eq(
    d.with_day_of_year(365),
    Ok({ year: Year(1970), month: Month::December, day: DayOfMonth(31) }),
  )?
  @assertion.assert_eq(d.with_day_of_year(366), Err(doy_out_of_range_err))?
  @assertion.assert_eq(d.with_day_of_year(0), Err(doy_out_of_range_err))?
  @assertion.assert_eq(d.with_day_of_year(367), Err(doy_out_of_range_err))?
  let d1 = Date::from_ymd(2000, 1, 1)?
  @assertion.assert_eq(
    d1.with_day_of_year(366),
    Ok({ year: Year(2000), month: Month::December, day: DayOfMonth(31) }),
  )?
}

test "hash" {
  @assertion.assert_ne(min_date.hash(), max_date.hash())?
  @assertion.assert_ne(
    unix_epoch_date.add_days(1)?.hash(),
    unix_epoch_date.hash(),
  )?
}
