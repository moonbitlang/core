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

test "get_type" {
  inspect(iso_calendar.get_type(), content="iso8601")?
}

test "era" {
  inspect(iso_calendar.era(PlainDate::of(0, 1, 1)?), content="BCE")?
  inspect(iso_calendar.era(PlainDate::of(1, 1, 1)?), content="CE")?
  inspect(iso_calendar.era(PlainDate::of(2008, 8, 8)?), content="CE")?
}

test "era_year" {
  inspect(iso_calendar.era_year(PlainDate::of(0, 1, 1)?), content="1")?
  inspect(iso_calendar.era_year(PlainDate::of(1, 1, 1)?), content="1")?
  inspect(iso_calendar.era_year(PlainDate::of(2008, 8, 8)?), content="2008")?
}

test "year" {
  inspect(iso_calendar.year(PlainDate::of(2008, 8, 8)?), content="2008")?
}

test "month" {
  inspect(iso_calendar.month(PlainDate::of(2008, 8, 8)?), content="8")?
}

test "day" {
  inspect(iso_calendar.day(PlainDate::of(2008, 8, 8)?), content="8")?
}

test "day_of_week" {
  inspect(
    iso_calendar.day_of_week(PlainDate::of(2008, 8, 8)?),
    content="Friday",
  )?
  inspect(
    iso_calendar.day_of_week(PlainDate::of(2008, 8, 9)?),
    content="Saturday",
  )?
  inspect(
    iso_calendar.day_of_week(PlainDate::of(2008, 8, 10)?),
    content="Sunday",
  )?
  inspect(
    iso_calendar.day_of_week(PlainDate::of(2008, 8, 11)?),
    content="Monday",
  )?
  inspect(
    iso_calendar.day_of_week(PlainDate::of(2008, 8, 12)?),
    content="Tuesday",
  )?
  inspect(
    iso_calendar.day_of_week(PlainDate::of(2008, 8, 13)?),
    content="Wednesday",
  )?
  inspect(
    iso_calendar.day_of_week(PlainDate::of(2008, 8, 14)?),
    content="Thursday",
  )?
  inspect(
    iso_calendar.day_of_week(PlainDate::of(2008, 8, 15)?),
    content="Friday",
  )?
}

test "day_of_year" {
  inspect(iso_calendar.day_of_year(PlainDate::of(1, 1, 1)?), content="1")?
  inspect(iso_calendar.day_of_year(PlainDate::of(2000, 12, 31)?), content="366")?
  inspect(iso_calendar.day_of_year(PlainDate::of(2001, 12, 31)?), content="365")?
}

test "days_in_week" {
  inspect(iso_calendar.days_in_week(PlainDate::of(1, 1, 1)?), content="7")?
}

test "days_in_month" {
  inspect(iso_calendar.days_in_month(PlainDate::of(2000, 1, 1)?), content="31")?
  inspect(iso_calendar.days_in_month(PlainDate::of(2000, 2, 1)?), content="29")?
  inspect(iso_calendar.days_in_month(PlainDate::of(2000, 3, 1)?), content="31")?
  inspect(iso_calendar.days_in_month(PlainDate::of(2000, 4, 1)?), content="30")?
  inspect(iso_calendar.days_in_month(PlainDate::of(2000, 5, 1)?), content="31")?
  inspect(iso_calendar.days_in_month(PlainDate::of(2000, 6, 1)?), content="30")?
  inspect(iso_calendar.days_in_month(PlainDate::of(2000, 7, 1)?), content="31")?
  inspect(iso_calendar.days_in_month(PlainDate::of(2000, 8, 1)?), content="31")?
  inspect(iso_calendar.days_in_month(PlainDate::of(2000, 9, 1)?), content="30")?
  inspect(iso_calendar.days_in_month(PlainDate::of(2000, 10, 1)?), content="31")?
  inspect(iso_calendar.days_in_month(PlainDate::of(2000, 11, 1)?), content="30")?
  inspect(iso_calendar.days_in_month(PlainDate::of(2000, 12, 1)?), content="31")?
  inspect(iso_calendar.days_in_month(PlainDate::of(2001, 2, 1)?), content="28")?
}

test "days_in_year" {
  inspect(iso_calendar.days_in_year(PlainDate::of(2000, 1, 1)?), content="366")?
  inspect(iso_calendar.days_in_year(PlainDate::of(2001, 1, 1)?), content="365")?
}

test "months_in_year" {
  inspect(iso_calendar.months_in_year(PlainDate::of(2000, 1, 1)?), content="12")?
}

test "in_leap_year" {
  inspect(iso_calendar.in_leap_year(PlainDate::of(2000, 1, 1)?), content="true")?
  inspect(
    iso_calendar.in_leap_year(PlainDate::of(2001, 1, 1)?),
    content="false",
  )?
}

test "date_from" {
  inspect(iso_calendar.date_from(0, 1, 1), content="Ok(0000-01-01)")?
  inspect(iso_calendar.date_from(1, 1, 1), content="Ok(0001-01-01)")?
  inspect(iso_calendar.date_from(9999, 12, 31), content="Ok(9999-12-31)")?
  inspect(iso_calendar.date_from(2000, 1, 1), content="Ok(2000-01-01)")?
  inspect(iso_calendar.date_from(-1, 1, 1), content="Err(Invalid date)")?
  inspect(iso_calendar.date_from(0, 0, 1), content="Err(Invalid date)")?
  inspect(iso_calendar.date_from(0, 1, 0), content="Err(Invalid date)")?
  inspect(iso_calendar.date_from(10000, 12, 31), content="Err(Invalid date)")?
}

test "date_from_valid" {
  inspect(date_from_valid(2001, 2, 29), content="2001-02-28")?
}

test "add_years" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(iso_calendar.add_years(d, 0), content="Ok(2000-02-29)")?
  inspect(iso_calendar.add_years(d, 1), content="Ok(2001-02-28)")?
  inspect(iso_calendar.add_years(d, -1), content="Ok(1999-02-28)")?
  inspect(iso_calendar.add_years(d, -1999), content="Ok(0001-02-28)")?
  inspect(iso_calendar.add_years(d, 7999), content="Ok(9999-02-28)")?
  inspect(iso_calendar.add_years(d, -2001), content="Err(Invalid date)")?
  inspect(iso_calendar.add_years(d, 8000), content="Err(Invalid date)")?
}

test "add_months" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(iso_calendar.add_months(d, 0), content="Ok(2000-02-29)")?
  inspect(iso_calendar.add_months(d, 1), content="Ok(2000-03-29)")?
  inspect(iso_calendar.add_months(d, -1), content="Ok(2000-01-29)")?
  inspect(iso_calendar.add_months(d, -12), content="Ok(1999-02-28)")?
  inspect(iso_calendar.add_months(d, 12), content="Ok(2001-02-28)")?
  inspect(iso_calendar.add_months(d, 13), content="Ok(2001-03-29)")?
  inspect(iso_calendar.add_months(d, 14), content="Ok(2001-04-29)")?
  inspect(iso_calendar.add_months(d, 15), content="Ok(2001-05-29)")?
  inspect(iso_calendar.add_months(d, 16), content="Ok(2001-06-29)")?
  inspect(iso_calendar.add_months(d, 17), content="Ok(2001-07-29)")?
  inspect(iso_calendar.add_months(d, 18), content="Ok(2001-08-29)")?
  inspect(iso_calendar.add_months(d, 19), content="Ok(2001-09-29)")?
  inspect(iso_calendar.add_months(d, 20), content="Ok(2001-10-29)")?
  inspect(iso_calendar.add_months(d, 21), content="Ok(2001-11-29)")?
  inspect(iso_calendar.add_months(d, 22), content="Ok(2001-12-29)")?
  inspect(iso_calendar.add_months(d, 23), content="Ok(2002-01-29)")?
  inspect(iso_calendar.add_months(d, 24), content="Ok(2002-02-28)")?
  inspect(iso_calendar.add_months(d, 12 * 8000), content="Err(Invalid date)")?
  inspect(iso_calendar.add_months(d, 12 * -2001), content="Err(Invalid date)")?
}

test "add_weeks" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(iso_calendar.add_weeks(d, 0), content="Ok(2000-02-29)")?
  inspect(iso_calendar.add_weeks(d, 1), content="Ok(2000-03-07)")?
  inspect(iso_calendar.add_weeks(d, -1), content="Ok(2000-02-22)")?
  inspect(iso_calendar.add_weeks(d, 3), content="Ok(2000-03-21)")?
  inspect(iso_calendar.add_weeks(d, -3), content="Ok(2000-02-08)")?
  inspect(iso_calendar.add_weeks(d, 12 * 8000 * 5), content="Err(Invalid date)")?
  inspect(
    iso_calendar.add_weeks(d, 12 * -2001 * 5),
    content="Err(Invalid date)",
  )?
}

test "add_days" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(iso_calendar.add_days(d, 0), content="Ok(2000-02-29)")?
  inspect(iso_calendar.add_days(d, 1), content="Ok(2000-03-01)")?
  inspect(iso_calendar.add_days(d, -1), content="Ok(2000-02-28)")?
  inspect(iso_calendar.add_days(d, 365), content="Ok(2001-02-28)")?
  inspect(iso_calendar.add_days(d, -365), content="Ok(1999-03-01)")?
  inspect(iso_calendar.add_days(d, 12 * 8000 * 31), content="Err(Invalid date)")?
  inspect(
    iso_calendar.add_days(d, 12 * -2001 * 31),
    content="Err(Invalid date)",
  )?
}

test "add_period" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(
    iso_calendar.add_period(d, Period::of(years=1)),
    content="Ok(2001-02-28)",
  )?
  inspect(
    iso_calendar.add_period(d, Period::of(months=1)),
    content="Ok(2000-03-29)",
  )?
  inspect(
    iso_calendar.add_period(d, Period::of(days=1)),
    content="Ok(2000-03-01)",
  )?
  inspect(
    iso_calendar.add_period(d, Period::of(years=1, months=1, days=1)),
    content="Ok(2001-03-29)",
  )?
}

test "with_year" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(iso_calendar.with_year(d, 2000), content="Ok(2000-02-29)")?
  inspect(iso_calendar.with_year(d, 2001), content="Ok(2001-02-28)")?
  inspect(iso_calendar.with_year(d, 2008), content="Ok(2008-02-29)")?
  inspect(iso_calendar.with_year(d, 0), content="Ok(0000-02-29)")?
  inspect(iso_calendar.with_year(d, 9999), content="Ok(9999-02-28)")?
  inspect(iso_calendar.with_year(d, -1), content="Err(Invalid date)")?
  inspect(iso_calendar.with_year(d, 10000), content="Err(Invalid date)")?
}

test "with_month" {
  let d = PlainDate::of(2000, 1, 31)?
  inspect(iso_calendar.with_month(d, 1), content="Ok(2000-01-31)")?
  inspect(iso_calendar.with_month(d, 2), content="Ok(2000-02-29)")?
  inspect(iso_calendar.with_month(d, 4), content="Ok(2000-04-30)")?
  inspect(iso_calendar.with_month(d, 0), content="Err(Invalid date)")?
  inspect(iso_calendar.with_month(d, 13), content="Err(Invalid date)")?
}

test "with_day" {
  let d = PlainDate::of(2000, 2, 29)?
  inspect(iso_calendar.with_day(d, 29), content="Ok(2000-02-29)")?
  inspect(iso_calendar.with_day(d, 1), content="Ok(2000-02-01)")?
  inspect(iso_calendar.with_day(d, 0), content="Err(Invalid date)")?
  inspect(iso_calendar.with_day(d, 30), content="Err(Invalid date)")?
}

test "until" {
  inspect(
    iso_calendar.until(PlainDate::of(1970, 1, 1)?, PlainDate::of(2000, 1, 1)?),
    content="Ok(P30Y)",
  )?
  inspect(
    iso_calendar.until(PlainDate::of(2000, 2, 1)?, PlainDate::of(2000, 1, 15)?),
    content="Ok(P-17D)",
  )?
  inspect(
    iso_calendar.until(PlainDate::of(2000, 1, 15)?, PlainDate::of(2000, 2, 1)?),
    content="Ok(P17D)",
  )?
  inspect(
    iso_calendar.until(PlainDate::of(2000, 1, 15)?, PlainDate::of(2000, 3, 1)?),
    content="Ok(P1M15D)",
  )?
  inspect(
    iso_calendar.until(PlainDate::of(2000, 1, 1)?, PlainDate::of(2001, 2, 15)?),
    content="Ok(P1Y1M14D)",
  )?
  inspect(
    iso_calendar.until(PlainDate::of(2001, 2, 15)?, PlainDate::of(2000, 1, 1)?),
    content="Ok(P-1Y-1M-14D)",
  )?
}

test "until and add_period" {
  let start = PlainDate::of(2000, 1, 1)?
  let p = iso_calendar.until(start, PlainDate::of(2024, 1, 1)?)?
  inspect(iso_calendar.add_period(start, p)?, content="2024-01-01")?
  let p = iso_calendar.until(start, PlainDate::of(1970, 1, 1)?)?
  inspect(iso_calendar.add_period(start, p)?, content="1970-01-01")?
  let p = iso_calendar.until(start, PlainDate::of(2000, 2, 15)?)?
  inspect(iso_calendar.add_period(start, p)?, content="2000-02-15")?
  let p = iso_calendar.until(start, PlainDate::of(1999, 2, 15)?)?
  inspect(iso_calendar.add_period(start, p)?, content="1999-02-15")?
}
