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

test "of" {
  inspect(PlainDate::of(0, 1, 1), content="Ok(0000-01-01)")?
  inspect(PlainDate::of(1, 1, 1), content="Ok(0001-01-01)")?
  inspect(PlainDate::of(2000, 2, 29), content="Ok(2000-02-29)")?
  inspect(PlainDate::of(9999, 1, 1), content="Ok(9999-01-01)")?
  inspect(PlainDate::of(-1, 1, 1), content="Ok(-0001-01-01)")?
  inspect(PlainDate::of(-2000, 2, 29), content="Ok(-2000-02-29)")?
  inspect(PlainDate::of(-9999, 1, 1), content="Ok(-9999-01-01)")?
  inspect(PlainDate::of(2001, 2, 29), content="Err(Invalid date)")?
  inspect(PlainDate::of(2001, 1, 32), content="Err(Invalid date)")?
  inspect(PlainDate::of(10000, 1, 1), content="Err(Invalid date)")?
  inspect(PlainDate::of(10000, 1, 1), content="Err(Invalid date)")?
}

test "from_year_ord" {
  inspect(PlainDate::from_year_ord(0, 1), content="Ok(0000-01-01)")?
  inspect(PlainDate::from_year_ord(1, 365), content="Ok(0001-12-31)")?
  inspect(PlainDate::from_year_ord(-1, 365), content="Ok(-0001-12-31)")?
  inspect(PlainDate::from_year_ord(2000, 366), content="Ok(2000-12-31)")?
  inspect(PlainDate::from_year_ord(-2000, 366), content="Ok(-2000-12-31)")?
  inspect(PlainDate::from_year_ord(9999, 365), content="Ok(9999-12-31)")?
  inspect(PlainDate::from_year_ord(-9999, 365), content="Ok(-9999-12-31)")?
  inspect(PlainDate::from_year_ord(2001, 366), content="Err(Invalid date)")?
  inspect(PlainDate::from_year_ord(-2001, 366), content="Err(Invalid date)")?
  inspect(PlainDate::from_year_ord(10000, 365), content="Err(Invalid date)")?
  inspect(PlainDate::from_year_ord(-10000, 365), content="Err(Invalid date)")?
}

test "from_string" {
  inspect(PlainDate::from_string("9999-01-01"), content="Ok(9999-01-01)")?
  inspect(PlainDate::from_string("0000-01-01"), content="Ok(0000-01-01)")?
  inspect(PlainDate::from_string("0001-01-01"), content="Ok(0001-01-01)")?
  inspect(PlainDate::from_string("-9999-01-01"), content="Ok(-9999-01-01)")?
  inspect(PlainDate::from_string("10000-01-01"), content="Err(Invalid date)")?
  inspect(PlainDate::from_string("-10000-01-01"), content="Err(Invalid date)")?
  inspect(PlainDate::from_string("-01-01"), content="Err(Invalid date)")?
  inspect(PlainDate::from_string("12-31"), content="Err(Invalid date)")?
  inspect(PlainDate::from_string("-01"), content="Err(Invalid date)")?
}

test "compare" {
  inspect(
    PlainDate::of(2000, 1, 1)? == PlainDate::of(2000, 1, 1)?,
    content="true",
  )?
  inspect(
    PlainDate::of(2001, 1, 1)? > PlainDate::of(2000, 1, 1)?,
    content="true",
  )?
  inspect(
    PlainDate::of(2000, 1, 1)? < PlainDate::of(2001, 1, 1)?,
    content="true",
  )?
  inspect(
    PlainDate::of(2000, 2, 1)? > PlainDate::of(2000, 1, 1)?,
    content="true",
  )?
  inspect(
    PlainDate::of(2000, 1, 1)? < PlainDate::of(2000, 2, 1)?,
    content="true",
  )?
  inspect(
    PlainDate::of(2000, 1, 2)? > PlainDate::of(2000, 1, 1)?,
    content="true",
  )?
  inspect(
    PlainDate::of(2000, 1, 1)? < PlainDate::of(2000, 1, 2)?,
    content="true",
  )?
}

test "era" {
  inspect(PlainDate::of(-9999, 1, 1)?.era(), content="BCE")?
  inspect(PlainDate::of(-1, 1, 1)?.era(), content="BCE")?
  inspect(PlainDate::of(0, 1, 1)?.era(), content="BCE")?
  inspect(PlainDate::of(1, 1, 1)?.era(), content="CE")?
  inspect(PlainDate::of(9999, 1, 1)?.era(), content="CE")?
}

test "era_year" {
  inspect(PlainDate::of(-9999, 1, 1)?.era_year(), content="10000")?
  inspect(PlainDate::of(-1, 1, 1)?.era_year(), content="2")?
  inspect(PlainDate::of(0, 1, 1)?.era_year(), content="1")?
  inspect(PlainDate::of(1, 1, 1)?.era_year(), content="1")?
  inspect(PlainDate::of(9999, 1, 1)?.era_year(), content="9999")?
}

test "getters" {
  let date = PlainDate::of(2000, 12, 31)?
  inspect(date.year(), content="2000")?
  inspect(date.month(), content="12")?
  inspect(date.day(), content="31")?
  inspect(date.ordinal(), content="366")?
  let date = PlainDate::of(-2000, 12, 31)?
  inspect(date.year(), content="-2000")?
  inspect(date.month(), content="12")?
  inspect(date.day(), content="31")?
  inspect(date.ordinal(), content="366")?
}

test "weekday" {
  inspect(PlainDate::of(2000, 1, 1)?.weekday(), content="Saturday")?
  inspect(PlainDate::of(2000, 1, 2)?.weekday(), content="Sunday")?
  inspect(PlainDate::of(2000, 1, 3)?.weekday(), content="Monday")?
  inspect(PlainDate::of(2000, 1, 4)?.weekday(), content="Tuesday")?
  inspect(PlainDate::of(2000, 1, 5)?.weekday(), content="Wednesday")?
  inspect(PlainDate::of(2000, 1, 6)?.weekday(), content="Thursday")?
  inspect(PlainDate::of(2000, 1, 7)?.weekday(), content="Friday")?
}

test "ordinal" {
  inspect(PlainDate::of(1, 1, 1)?.ordinal(), content="1")?
  inspect(PlainDate::of(2000, 12, 31)?.ordinal(), content="366")?
  inspect(PlainDate::of(2001, 12, 31)?.ordinal(), content="365")?
}

test "days_in_week" {
  inspect(PlainDate::of(1, 1, 1)?.days_in_week(), content="7")?
}

test "days_in_month" {
  inspect(PlainDate::of(2000, 1, 1)?.days_in_month(), content="31")?
  inspect(PlainDate::of(2000, 2, 1)?.days_in_month(), content="29")?
  inspect(PlainDate::of(2000, 3, 1)?.days_in_month(), content="31")?
  inspect(PlainDate::of(2000, 4, 1)?.days_in_month(), content="30")?
  inspect(PlainDate::of(2000, 5, 1)?.days_in_month(), content="31")?
  inspect(PlainDate::of(2000, 6, 1)?.days_in_month(), content="30")?
  inspect(PlainDate::of(2000, 7, 1)?.days_in_month(), content="31")?
  inspect(PlainDate::of(2000, 8, 1)?.days_in_month(), content="31")?
  inspect(PlainDate::of(2000, 9, 1)?.days_in_month(), content="30")?
  inspect(PlainDate::of(2000, 10, 1)?.days_in_month(), content="31")?
  inspect(PlainDate::of(2000, 11, 1)?.days_in_month(), content="30")?
  inspect(PlainDate::of(2000, 12, 1)?.days_in_month(), content="31")?
  inspect(PlainDate::of(2001, 2, 1)?.days_in_month(), content="28")?
}

test "days_in_year" {
  inspect(PlainDate::of(2000, 1, 1)?.days_in_year(), content="366")?
  inspect(PlainDate::of(2001, 1, 1)?.days_in_year(), content="365")?
  inspect(PlainDate::of(-2000, 1, 1)?.days_in_year(), content="366")?
  inspect(PlainDate::of(-2001, 1, 1)?.days_in_year(), content="365")?
}

test "months_in_year" {
  inspect(PlainDate::of(2000, 1, 1)?.months_in_year(), content="12")?
}

test "in_leap_year" {
  inspect(PlainDate::of(2000, 1, 1)?.in_leap_year(), content="true")?
  inspect(PlainDate::of(2000, 1, 1)?.in_leap_year(), content="true")?
  inspect(PlainDate::of(2001, 1, 1)?.in_leap_year(), content="false")?
  inspect(PlainDate::of(-2000, 1, 1)?.in_leap_year(), content="true")?
  inspect(PlainDate::of(-2001, 1, 1)?.in_leap_year(), content="false")?
  inspect(PlainDate::of(-1, 1, 1)?.in_leap_year(), content="false")?
  inspect(PlainDate::of(0, 1, 1)?.in_leap_year(), content="true")?
  inspect(PlainDate::of(1, 1, 1)?.in_leap_year(), content="false")?
}

test "create_from_valid" {
  inspect(create_from_valid(2001, 2, 29), content="2001-02-28")?
  inspect(create_from_valid(-2001, 2, 29), content="-2001-02-28")?
}

test "add_years" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(d.add_years(0L), content="Ok(2000-02-29)")?
  inspect(d.add_years(1L), content="Ok(2001-02-28)")?
  inspect(d.add_years(-1L), content="Ok(1999-02-28)")?
  inspect(d.add_years(-1999L), content="Ok(0001-02-28)")?
  inspect(d.add_years(7999L), content="Ok(9999-02-28)")?
  inspect(d.add_years(-2001L), content="Ok(-0001-02-28)")?
  inspect(d.add_years(-9999L), content="Ok(-7999-02-28)")?
  inspect(d.add_years(8000L), content="Err(Invalid date)")?
  inspect(d.add_years(Int64::max_value()), content="Err(Int64 overflow)")?
  inspect(d.add_years(Int64::min_value()), content="Ok(2000-02-29)")?
}

test "add_months" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(d.add_months(0L), content="Ok(2000-02-29)")?
  inspect(d.add_months(1L), content="Ok(2000-03-29)")?
  inspect(d.add_months(-1L), content="Ok(2000-01-29)")?
  inspect(d.add_months(-12L), content="Ok(1999-02-28)")?
  inspect(d.add_months(12L), content="Ok(2001-02-28)")?
  inspect(d.add_months(24L), content="Ok(2002-02-28)")?
  inspect(d.add_months(12L * -2000L), content="Ok(0000-02-29)")?
  inspect(d.add_months(12L * 8000L), content="Err(Invalid date)")?
  inspect(d.add_months(Int64::max_value()), content="Err(Int64 overflow)")?
  inspect(d.add_months(Int64::min_value()), content="Err(Invalid date)")?
  let d = PlainDate::of(-2000, 2, 29)?
  inspect(d.add_months(0L), content="Ok(-2000-02-29)")?
  inspect(d.add_months(1L), content="Ok(-2000-03-29)")?
  inspect(d.add_months(-1L), content="Ok(-2000-01-29)")?
  inspect(d.add_months(-12L), content="Ok(-2001-02-28)")?
  inspect(d.add_months(12L), content="Ok(-1999-02-28)")?
  inspect(d.add_months(24L), content="Ok(-1998-02-28)")?
  inspect(d.add_months(12L * 10000L), content="Ok(8000-02-29)")?
  inspect(d.add_months(12L * -8000L), content="Err(Invalid date)")?
  inspect(d.add_months(Int64::max_value()), content="Err(Invalid date)")?
  inspect(d.add_months(Int64::min_value()), content="Err(Int64 overflow)")?
}

test "add_weeks" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(d.add_weeks(0L), content="Ok(2000-02-29)")?
  inspect(d.add_weeks(1L), content="Ok(2000-03-07)")?
  inspect(d.add_weeks(-1L), content="Ok(2000-02-22)")?
  inspect(d.add_weeks(3L), content="Ok(2000-03-21)")?
  inspect(d.add_weeks(-3L), content="Ok(2000-02-08)")?
  inspect(d.add_weeks(Int64::max_value()), content="Err(Int64 overflow)")?
  inspect(d.add_weeks(Int64::min_value()), content="Err(Int64 overflow)")?
  let d = PlainDate::of(-2000, 2, 29)?
  inspect(d.add_weeks(0L), content="Ok(-2000-02-29)")?
  inspect(d.add_weeks(1L), content="Ok(-2000-03-07)")?
  inspect(d.add_weeks(-1L), content="Ok(-2000-02-22)")?
  inspect(d.add_weeks(3L), content="Ok(-2000-03-21)")?
  inspect(d.add_weeks(-3L), content="Ok(-2000-02-08)")?
  inspect(d.add_weeks(Int64::max_value()), content="Err(Int64 overflow)")?
  inspect(d.add_weeks(Int64::min_value()), content="Err(Int64 overflow)")?
}

test "add_days" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(d.add_days(0L), content="Ok(2000-02-29)")?
  inspect(d.add_days(1L), content="Ok(2000-03-01)")?
  inspect(d.add_days(-1L), content="Ok(2000-02-28)")?
  inspect(d.add_days(365L), content="Ok(2001-02-28)")?
  inspect(d.add_days(-365L), content="Ok(1999-03-01)")?
  inspect(d.add_days(Int64::max_value()), content="Err(Int64 overflow)")?
  inspect(d.add_days(Int64::min_value()), content="Err(Invalid date)")?
  let d = PlainDate::of(-2000, 2, 29)?
  inspect(d.add_days(0L), content="Ok(-2000-02-29)")?
  inspect(d.add_days(1L), content="Ok(-2000-03-01)")?
  inspect(d.add_days(-1L), content="Ok(-2000-02-28)")?
  inspect(d.add_days(365L), content="Ok(-1999-02-28)")?
  inspect(d.add_days(-365L), content="Ok(-2001-03-01)")?
  inspect(d.add_days(Int64::max_value()), content="Err(Invalid date)")?
  inspect(d.add_days(Int64::min_value()), content="Err(Int64 overflow)")?
}

test "add_period" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(d.add_period(Period::of(years=1)), content="Ok(2001-02-28)")?
  inspect(d.add_period(Period::of(months=1)), content="Ok(2000-03-29)")?
  inspect(d.add_period(Period::of(days=1)), content="Ok(2000-03-01)")?
  inspect(
    d.add_period(Period::of(years=1, months=1, days=1)),
    content="Ok(2001-03-30)",
  )?
}

test "with_year" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(d.with_year(2000), content="Ok(2000-02-29)")?
  inspect(d.with_year(2001), content="Ok(2001-02-28)")?
  inspect(d.with_year(2008), content="Ok(2008-02-29)")?
  inspect(d.with_year(0), content="Ok(0000-02-29)")?
  inspect(d.with_year(9999), content="Ok(9999-02-28)")?
  inspect(d.with_year(-9999), content="Ok(-9999-02-28)")?
  inspect(d.with_year(10000), content="Err(Invalid date)")?
  inspect(d.with_year(-10000), content="Err(Invalid date)")?
}

test "with_month" {
  let d = PlainDate::of(2000, 1, 31)?
  inspect(d.with_month(1), content="Ok(2000-01-31)")?
  inspect(d.with_month(2), content="Ok(2000-02-29)")?
  inspect(d.with_month(4), content="Ok(2000-04-30)")?
  inspect(d.with_month(0), content="Err(Invalid date)")?
  inspect(d.with_month(13), content="Err(Invalid date)")?
}

test "with_day" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(d.with_day(29), content="Ok(2000-02-29)")?
  inspect(d.with_day(1), content="Ok(2000-02-01)")?
  inspect(d.with_day(0), content="Err(Invalid date)")?
  inspect(d.with_day(30), content="Err(Invalid date)")?
}

test "with_ordinal" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(d.with_ordinal(1), content="Ok(2000-01-01)")?
  inspect(d.with_ordinal(366), content="Ok(2000-12-31)")?
  inspect(d.with_ordinal(0), content="Err(Invalid date)")?
  inspect(d.with_ordinal(367), content="Err(Invalid date)")?
}

test "until" {
  inspect(
    PlainDate::of(1970, 1, 1)?.until(PlainDate::of(2000, 1, 1)?),
    content="Ok(P30Y)",
  )?
  inspect(
    PlainDate::of(2000, 2, 1)?.until(PlainDate::of(2000, 1, 15)?),
    content="Ok(P-17D)",
  )?
  inspect(
    PlainDate::of(2000, 1, 15)?.until(PlainDate::of(2000, 2, 1)?),
    content="Ok(P17D)",
  )?
  inspect(
    PlainDate::of(2000, 1, 15)?.until(PlainDate::of(2000, 3, 1)?),
    content="Ok(P1M15D)",
  )?
  inspect(
    PlainDate::of(2000, 1, 1)?.until(PlainDate::of(2001, 2, 15)?),
    content="Ok(P1Y1M14D)",
  )?
  inspect(
    PlainDate::of(2001, 2, 15)?.until(PlainDate::of(2000, 1, 1)?),
    content="Ok(P-1Y-1M-14D)",
  )?
  inspect(
    PlainDate::of(-9999, 1, 1)?.until(PlainDate::of(9999, 1, 1)?),
    content="Ok(P19998Y)",
  )?
}

test "until and add_period" {
  let start = PlainDate::of(2000, 1, 1)?
  let p = start.until(PlainDate::of(2024, 1, 1)?)?
  inspect(start.add_period(p)?, content="2024-01-01")?
  let p = start.until(PlainDate::of(1970, 1, 1)?)?
  inspect(start.add_period(p)?, content="1970-01-01")?
  let p = start.until(PlainDate::of(2000, 2, 15)?)?
  inspect(start.add_period(p)?, content="2000-02-15")?
  let p = start.until(PlainDate::of(1999, 2, 15)?)?
  inspect(start.add_period(p)?, content="1999-02-15")?
}

test "date_to_fixed_days" {
  inspect(date_to_fixed_days(0, 1, 1), content="0")?
  inspect(date_to_fixed_days(1, 1, 1), content="366")?
  inspect(date_to_fixed_days(2, 1, 1), content="731")?
  inspect(date_to_fixed_days(-1, 1, 1), content="-365")?
  inspect(date_to_fixed_days(-1970, 1, 1), content="-719527")?
  inspect(date_to_fixed_days(1970, 1, 1), content="719528")?
}

test "fixed_days_to_year_ord" {
  inspect(fixed_days_to_year_ord(0L), content="(0, 1)")?
  inspect(fixed_days_to_year_ord(1L), content="(0, 2)")?
  inspect(fixed_days_to_year_ord(366L), content="(1, 1)")?
  inspect(fixed_days_to_year_ord(731L), content="(2, 1)")?
  inspect(fixed_days_to_year_ord(719528L), content="(1970, 1)")?
  inspect(fixed_days_to_year_ord(-365L), content="(-1, 1)")?
  inspect(fixed_days_to_year_ord(-730L), content="(-2, 1)")?
  inspect(fixed_days_to_year_ord(-719527L), content="(-1970, 1)")?
}
