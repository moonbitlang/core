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
  inspect(PlainDateTime::of(2000, 1, 1), content="Ok(2000-01-01T00:00:00)")?
  inspect(
    PlainDateTime::of(2000, 1, 1, hour=1, minute=2, second=3, nanosecond=400),
    content="Ok(2000-01-01T01:02:03.0000004)",
  )?
  inspect(PlainDateTime::of(0, 1, 1), content="Ok(0000-01-01T00:00:00)")?
  inspect(
    PlainDateTime::of(
      9999,
      12,
      31,
      hour=23,
      minute=59,
      second=59,
      nanosecond=999_999_999,
    ),
    content="Ok(9999-12-31T23:59:59.999999999)",
  )?
  inspect(
    PlainDateTime::of(
      -9999,
      12,
      31,
      hour=23,
      minute=59,
      second=59,
      nanosecond=999_999_999,
    ),
    content="Ok(-9999-12-31T23:59:59.999999999)",
  )?
}

test "from_unix_second" {
  inspect(
    PlainDateTime::from_unix_second(1714227729L, 1000, utc_offset),
    content="Ok(2024-04-27T14:22:09.000001)",
  )?
  inspect(
    PlainDateTime::from_unix_second(
      1714227729L,
      1000,
      ZoneOffset::from_seconds(8 * 60 * 60)?,
    ),
    content="Ok(2024-04-27T22:22:09.000001)",
  )?
  inspect(
    PlainDateTime::from_unix_second(1714227729L, 1_000_000_000, utc_offset),
    content="Err(Invalid date time)",
  )?
}

test "from_string" {
  inspect(
    PlainDateTime::from_string("0000-01-01T00:00:00"),
    content="Ok(0000-01-01T00:00:00)",
  )?
  inspect(
    PlainDateTime::from_string("9999-12-31T23:59:59"),
    content="Ok(9999-12-31T23:59:59)",
  )?
  inspect(
    PlainDateTime::from_string("-9999-12-31T23:59:59"),
    content="Ok(-9999-12-31T23:59:59)",
  )?
  inspect(
    PlainDateTime::from_string("2000-01-01T00:00:00.12345"),
    content="Ok(2000-01-01T00:00:00.12345)",
  )?
  inspect(
    PlainDateTime::from_string("9999-12-31T23:59:60"),
    content="Err(Invalid time)",
  )?
  inspect(
    PlainDateTime::from_string("10000-12-31T23:59:60"),
    content="Err(Invalid date)",
  )?
  inspect(
    PlainDateTime::from_string("2000-01-01 00:00:00"),
    content="Err(Invalid date time)",
  )?
  inspect(
    PlainDateTime::from_string("2000-01-01"),
    content="Err(Invalid date time)",
  )?
  inspect(
    PlainDateTime::from_string("00:00:00"),
    content="Err(Invalid date time)",
  )?
}

test "getters" {
  let d = PlainDateTime::of(
    2000,
    2,
    29,
    hour=1,
    minute=10,
    second=30,
    nanosecond=1000,
  )?
  inspect(d.era(), content="CE")?
  inspect(d.era_year(), content="2000")?
  inspect(d.year(), content="2000")?
  inspect(d.month(), content="2")?
  inspect(d.day(), content="29")?
  inspect(d.weekday(), content="Tuesday")?
  inspect(d.ordinal(), content="60")?
  inspect(d.days_in_year(), content="366")?
  inspect(d.days_in_month(), content="29")?
  inspect(d.days_in_week(), content="7")?
  inspect(d.months_in_year(), content="12")?
  inspect(d.hour(), content="1")?
  inspect(d.minute(), content="10")?
  inspect(d.second(), content="30")?
  inspect(d.nanosecond(), content="1000")?
}

test "in_leap_year" {
  inspect(PlainDateTime::of(2000, 1, 1)?.in_leap_year(), content="true")?
  inspect(PlainDateTime::of(2001, 1, 1)?.in_leap_year(), content="false")?
}

test "add_years" {
  let d = PlainDateTime::of(2000, 2, 29)?
  inspect(d.add_years(0L), content="Ok(2000-02-29T00:00:00)")?
  inspect(d.add_years(1L), content="Ok(2001-02-28T00:00:00)")?
  inspect(d.add_years(7999L), content="Ok(9999-02-28T00:00:00)")?
  inspect(d.add_years(8000L), content="Err(Invalid date)")?
  inspect(d.add_years(-11999L), content="Ok(-9999-02-28T00:00:00)")?
  inspect(d.add_years(-12000L), content="Err(Invalid date)")?
}

test "add_months" {
  let d = PlainDateTime::of(2000, 2, 29)?
  inspect(d.add_months(0L), content="Ok(2000-02-29T00:00:00)")?
  inspect(d.add_months(1L), content="Ok(2000-03-29T00:00:00)")?
  inspect(d.add_months(12L * 7999L), content="Ok(9999-02-28T00:00:00)")?
  inspect(d.add_months(12L * 8000L), content="Err(Invalid date)")?
  inspect(d.add_months(12L * -11999L), content="Ok(-9999-02-28T00:00:00)")?
  inspect(d.add_months(12L * -12000L), content="Err(Invalid date)")?
}

test "add_weeks" {
  let d = PlainDateTime::of(2000, 2, 29)?
  inspect(d.add_weeks(0L), content="Ok(2000-02-29T00:00:00)")?
  inspect(d.add_weeks(1L), content="Ok(2000-03-07T00:00:00)")?
  inspect(d.add_weeks(-1L), content="Ok(2000-02-22T00:00:00)")?
  inspect(d.add_weeks(3L), content="Ok(2000-03-21T00:00:00)")?
  inspect(d.add_weeks(-3L), content="Ok(2000-02-08T00:00:00)")?
  inspect(d.add_weeks(Int64::max_value()), content="Err(Int64 overflow)")?
  inspect(d.add_weeks(Int64::min_value()), content="Err(Int64 overflow)")?
}

test "add_days" {
  let d = PlainDateTime::of(2000, 2, 29)?
  inspect(d.add_days(0L), content="Ok(2000-02-29T00:00:00)")?
  inspect(d.add_days(1L), content="Ok(2000-03-01T00:00:00)")?
  inspect(d.add_days(-1L), content="Ok(2000-02-28T00:00:00)")?
  inspect(d.add_days(365L), content="Ok(2001-02-28T00:00:00)")?
  inspect(d.add_days(-365L), content="Ok(1999-03-01T00:00:00)")?
  inspect(d.add_days(Int64::max_value()), content="Err(Int64 overflow)")?
  inspect(d.add_days(Int64::min_value()), content="Err(Invalid date)")?
}

test "add_period" {
  let d = PlainDateTime::of(2000, 2, 29)?
  inspect(d.add_period(Period::of(years=1)), content="Ok(2001-02-28T00:00:00)")?
  inspect(d.add_period(Period::of(months=1)), content="Ok(2000-03-29T00:00:00)")?
  inspect(d.add_period(Period::of(days=1)), content="Ok(2000-03-01T00:00:00)")?
  inspect(
    d.add_period(Period::of(years=1, months=1, days=1)),
    content="Ok(2001-03-30T00:00:00)",
  )?
}

test "add_hours" {
  let d = PlainDateTime::of(0, 1, 1)?
  inspect(d.add_hours(0L), content="Ok(0000-01-01T00:00:00)")?
  inspect(d.add_hours(1L), content="Ok(0000-01-01T01:00:00)")?
  inspect(d.add_hours(24L), content="Ok(0000-01-02T00:00:00)")?
  inspect(d.add_hours(24L * 30L), content="Ok(0000-01-31T00:00:00)")?
  inspect(d.add_hours(24L * 366L), content="Ok(0001-01-01T00:00:00)")?
}

test "add_minutes" {
  let d = PlainDateTime::of(0, 1, 1)?
  inspect(d.add_minutes(0L), content="Ok(0000-01-01T00:00:00)")?
  inspect(d.add_minutes(1L), content="Ok(0000-01-01T00:01:00)")?
  inspect(d.add_minutes(60L), content="Ok(0000-01-01T01:00:00)")?
  inspect(d.add_minutes(24L * 60L), content="Ok(0000-01-02T00:00:00)")?
  inspect(d.add_minutes(24L * 60L * 366L), content="Ok(0001-01-01T00:00:00)")?
}

test "add_seconds" {
  let d = PlainDateTime::of(0, 1, 1)?
  inspect(d.add_seconds(0L), content="Ok(0000-01-01T00:00:00)")?
  inspect(d.add_seconds(1L), content="Ok(0000-01-01T00:00:01)")?
  inspect(d.add_seconds(60L), content="Ok(0000-01-01T00:01:00)")?
  inspect(d.add_seconds(60L * 60L), content="Ok(0000-01-01T01:00:00)")?
  inspect(d.add_seconds(24L * 60L * 60L), content="Ok(0000-01-02T00:00:00)")?
  inspect(
    d.add_seconds(24L * 60L * 60L * 366L),
    content="Ok(0001-01-01T00:00:00)",
  )?
}

test "add_nanoseconds" {
  let d = PlainDateTime::of(0, 1, 1)?
  inspect(d.add_nanoseconds(0L), content="Ok(0000-01-01T00:00:00)")?
  inspect(d.add_nanoseconds(1L), content="Ok(0000-01-01T00:00:00.000000001)")?
  inspect(
    d.add_nanoseconds(nanoseconds_per_second),
    content="Ok(0000-01-01T00:00:01)",
  )?
  inspect(
    d.add_nanoseconds(nanoseconds_per_minute),
    content="Ok(0000-01-01T00:01:00)",
  )?
  inspect(
    d.add_nanoseconds(nanoseconds_per_hour),
    content="Ok(0000-01-01T01:00:00)",
  )?
  inspect(
    d.add_nanoseconds(nanoseconds_per_day),
    content="Ok(0000-01-02T00:00:00)",
  )?
  inspect(
    d.add_nanoseconds(nanoseconds_per_day * 366L),
    content="Ok(0001-01-01T00:00:00)",
  )?
}

test "add_duration" {
  let d = PlainDateTime::of(0, 1, 1)?
  inspect(d.add_duration(Duration::zero()), content="Ok(0000-01-01T00:00:00)")?
  inspect(
    d.add_duration(Duration::of(hours=1L)?),
    content="Ok(0000-01-01T01:00:00)",
  )?
  inspect(
    d.add_duration(Duration::of(minutes=1L)?),
    content="Ok(0000-01-01T00:01:00)",
  )?
  inspect(
    d.add_duration(Duration::of(seconds=1L)?),
    content="Ok(0000-01-01T00:00:01)",
  )?
  inspect(
    d.add_duration(Duration::of(nanoseconds=100L)?),
    content="Ok(0000-01-01T00:00:00.0000001)",
  )?
  inspect(
    d.add_duration(
      Duration::of(hours=1L, minutes=10L, seconds=30L, nanoseconds=1000L)?,
    ),
    content="Ok(0000-01-01T01:10:30.000001)",
  )?
}

test "with_year" {
  let d = PlainDateTime::of(2000, 2, 29)?
  inspect(d.with_year(2000), content="Ok(2000-02-29T00:00:00)")?
  inspect(d.with_year(2001), content="Ok(2001-02-28T00:00:00)")?
  inspect(d.with_year(2008), content="Ok(2008-02-29T00:00:00)")?
  inspect(d.with_year(0), content="Ok(0000-02-29T00:00:00)")?
  inspect(d.with_year(9999), content="Ok(9999-02-28T00:00:00)")?
  inspect(d.with_year(-9999), content="Ok(-9999-02-28T00:00:00)")?
  inspect(d.with_year(10000), content="Err(Invalid date)")?
  inspect(d.with_year(-10000), content="Err(Invalid date)")?
}

test "with_month" {
  let d = PlainDateTime::of(2000, 1, 31)?
  inspect(d.with_month(1), content="Ok(2000-01-31T00:00:00)")?
  inspect(d.with_month(2), content="Ok(2000-02-29T00:00:00)")?
  inspect(d.with_month(4), content="Ok(2000-04-30T00:00:00)")?
  inspect(d.with_month(0), content="Err(Invalid date)")?
  inspect(d.with_month(13), content="Err(Invalid date)")?
}

test "with_day" {
  let d = PlainDateTime::of(2000, 2, 29)?
  inspect(d.with_day(29), content="Ok(2000-02-29T00:00:00)")?
  inspect(d.with_day(1), content="Ok(2000-02-01T00:00:00)")?
  inspect(d.with_day(0), content="Err(Invalid date)")?
  inspect(d.with_day(30), content="Err(Invalid date)")?
}

test "with_ordinal" {
  let d = PlainDateTime::of(2000, 2, 29)?
  inspect(d.with_ordinal(1), content="Ok(2000-01-01T00:00:00)")?
  inspect(d.with_ordinal(366), content="Ok(2000-12-31T00:00:00)")?
  inspect(d.with_ordinal(0), content="Err(Invalid date)")?
  inspect(d.with_ordinal(367), content="Err(Invalid date)")?
}

test "with_hour" {
  let d = PlainDateTime::of(2000, 1, 1, hour=1)?
  inspect(d.with_hour(1), content="Ok(2000-01-01T01:00:00)")?
  inspect(d.with_hour(10), content="Ok(2000-01-01T10:00:00)")?
  inspect(d.with_hour(0), content="Ok(2000-01-01T00:00:00)")?
  inspect(d.with_hour(24), content="Ok(2000-01-01T24:00:00)")?
  inspect(d.with_hour(-1), content="Err(Invalid time)")?
  inspect(d.with_hour(25), content="Err(Invalid time)")?
}

test "with_minute" {
  let d = PlainDateTime::of(2000, 1, 1, minute=20)?
  inspect(d.with_minute(20), content="Ok(2000-01-01T00:20:00)")?
  inspect(d.with_minute(10), content="Ok(2000-01-01T00:10:00)")?
  inspect(d.with_minute(0), content="Ok(2000-01-01T00:00:00)")?
  inspect(d.with_minute(59), content="Ok(2000-01-01T00:59:00)")?
  inspect(d.with_minute(-1), content="Err(Invalid time)")?
  inspect(d.with_minute(60), content="Err(Invalid time)")?
}

test "with_second" {
  let d = PlainDateTime::of(2000, 1, 1, second=30)?
  inspect(d.with_second(30), content="Ok(2000-01-01T00:00:30)")?
  inspect(d.with_second(10), content="Ok(2000-01-01T00:00:10)")?
  inspect(d.with_second(0), content="Ok(2000-01-01T00:00:00)")?
  inspect(d.with_second(59), content="Ok(2000-01-01T00:00:59)")?
  inspect(d.with_second(-1), content="Err(Invalid time)")?
  inspect(d.with_second(60), content="Err(Invalid time)")?
}

test "with_nanosecond" {
  let d = PlainDateTime::of(2000, 1, 1, nanosecond=400)?
  inspect(d.with_nanosecond(400), content="Ok(2000-01-01T00:00:00.0000004)")?
  inspect(d.with_nanosecond(100), content="Ok(2000-01-01T00:00:00.0000001)")?
  inspect(d.with_nanosecond(0), content="Ok(2000-01-01T00:00:00)")?
  inspect(
    d.with_nanosecond(999_999_999),
    content="Ok(2000-01-01T00:00:00.999999999)",
  )?
  inspect(d.with_nanosecond(-1), content="Err(Invalid time)")?
  inspect(d.with_nanosecond(1_000_000_000), content="Err(Invalid time)")?
}

test "to_plain_date and to_plain_time" {
  let d = PlainDateTime::of(
    2000,
    1,
    1,
    hour=1,
    minute=2,
    second=3,
    nanosecond=400,
  )?
  inspect(d.to_plain_date(), content="2000-01-01")?
  inspect(d.to_plain_time(), content="01:02:03.0000004")?
}
