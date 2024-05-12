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

/// A datetime with a time zone and offset in the ISO 8601 calendar system.
struct ZonedDateTime {
  datetime : PlainDateTime
  zone : Zone
  offset : ZoneOffset
}

/// Creates a ZonedDateTime from year, month, day, hour, minute, second and a time zone.
/// The default time zone is UTC+0.
pub fn date_time(
  year : Int,
  month : Int,
  day : Int,
  ~hour : Int = 0,
  ~minute : Int = 0,
  ~second : Int = 0,
  ~zone : Zone = utc_zone
) -> Result[ZonedDateTime, String] {
  ZonedDateTime::of(year, month, day, ~hour, ~minute, ~second, ~zone)
}

/// Creates a ZonedDateTime from elapsed seconds since the unix epoch and a time zone.
/// The default time zone is UTC+0.
pub fn unix(
  second : Int64,
  ~nanosecond : Int = 0,
  ~zone : Zone = utc_zone
) -> Result[ZonedDateTime, String] {
  ZonedDateTime::from_unix_second(second, ~nanosecond, ~zone)
}

/// Creates a ZonedDateTime from year, month, day, hour, minute and second.
/// The default time zone is UTC+0.
pub fn ZonedDateTime::of(
  year : Int,
  month : Int,
  day : Int,
  ~hour : Int = 0,
  ~minute : Int = 0,
  ~second : Int = 0,
  ~zone : Zone = utc_zone
) -> Result[ZonedDateTime, String] {
  let datetime = PlainDateTime::of(year, month, day, ~hour, ~minute, ~second)?
  Ok(create_from_plain(datetime, zone))
}

/// Creates a ZonedDateTime from a PlainDateTime and a time zone.
/// The default time zone is UTC+0.
pub fn ZonedDateTime::from_plain_datetime(
  datetime : PlainDateTime,
  ~zone : Zone = utc_zone
) -> ZonedDateTime {
  create_from_plain(datetime, zone)
}

/// Creates a ZonedDateTime from elapsed seconds since the unix epoch and a time zone.
/// The default time zone is UTC+0.
pub fn ZonedDateTime::from_unix_second(
  second : Int64,
  ~nanosecond : Int = 0,
  ~zone : Zone = utc_zone
) -> Result[ZonedDateTime, String] {
  let offset = zone.lookup_offset(second)
  let datetime = PlainDateTime::from_unix_second(second, nanosecond, offset)?
  Ok({ datetime, zone, offset })
}

/// Returns a string representing this datetime, like "2008-08-08T20:00:00+8:00[Asia/Beijing]"
pub fn to_string(self : ZonedDateTime) -> String {
  let buf = Buffer::make(0)
  buf.write_string(self.datetime.to_string())
  buf.write_string(self.offset.to_string())
  if self.zone != utc_zone {
    buf.write_char('[')
    buf.write_string(self.zone.to_string())
    buf.write_char(']')
  }
  buf.to_string()
}

/// Returns the elapsed seconds since the unix epoch.
pub fn to_unix_second(self : ZonedDateTime) -> Int64 {
  self.datetime.to_unix_second() - self.offset.seconds().to_int64()
}

/// Returns the date part of this datetime, without timezone.
pub fn to_plain_date(self : ZonedDateTime) -> PlainDate {
  self.datetime.to_plain_date()
}

/// Returns the time part of this datetime, without timezone.
pub fn to_plain_time(self : ZonedDateTime) -> PlainTime {
  self.datetime.to_plain_time()
}

/// Returns the datetime part of this datetime, without timezone.
pub fn to_plain_date_time(self : ZonedDateTime) -> PlainDateTime {
  self.datetime
}

/// Returns the era of this datetime.
pub fn era(self : ZonedDateTime) -> String {
  self.datetime.era()
}

/// Returns the year of era of this datetime.
pub fn era_year(self : ZonedDateTime) -> Int {
  self.datetime.era_year()
}

/// Returns the year of this datetime.
pub fn year(self : ZonedDateTime) -> Int {
  self.datetime.year()
}

/// Returns the month of this datetime.
pub fn month(self : ZonedDateTime) -> Int {
  self.datetime.month()
}

/// Returns the day of month of this datetime.
pub fn day(self : ZonedDateTime) -> Int {
  self.datetime.day()
}

/// Returns the weekday of this datetime.
pub fn weekday(self : ZonedDateTime) -> Weekday {
  self.datetime.weekday()
}

/// Returns the ordinal day of year of this datetime.
pub fn ordinal(self : ZonedDateTime) -> Int {
  self.datetime.ordinal()
}

/// Returns the number of days in a month of this datetime.
pub fn days_in_week(self : ZonedDateTime) -> Int {
  self.datetime.days_in_week()
}

/// Returns the number of days in a month of this datetime.
pub fn days_in_month(self : ZonedDateTime) -> Int {
  self.datetime.days_in_month()
}

/// Returns the number of days in a year of this datetime.
pub fn days_in_year(self : ZonedDateTime) -> Int {
  self.datetime.days_in_year()
}

/// Returns the number of months in a year of this datetime.
pub fn months_in_year(self : ZonedDateTime) -> Int {
  self.datetime.months_in_year()
}

/// Checks if this datetime is in a leap year.
pub fn in_leap_year(self : ZonedDateTime) -> Bool {
  self.datetime.in_leap_year()
}

/// Returns the hour of this datetime.
pub fn hour(self : ZonedDateTime) -> Int {
  self.datetime.hour()
}

/// Returns the minute of this datetime.
pub fn minute(self : ZonedDateTime) -> Int {
  self.datetime.minute()
}

/// Returns the second of this datetime.
pub fn second(self : ZonedDateTime) -> Int {
  self.datetime.second()
}

/// Returns the nanosecond of this datetime.
pub fn nanosecond(self : ZonedDateTime) -> Int {
  self.datetime.nanosecond()
}

/// Returns the time zone of this datetime.
pub fn zone(self : ZonedDateTime) -> Zone {
  self.zone
}

/// Returns the time offset of this datetime.
pub fn offset(self : ZonedDateTime) -> ZoneOffset {
  self.offset
}

/// Adds specified years to this datetime, and returns a new datetime.
pub fn add_years(
  self : ZonedDateTime,
  years : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_years(years)?, self.zone))
}

/// Adds specified months to this datetime, and returns a new datetime.
pub fn add_months(
  self : ZonedDateTime,
  months : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_months(months)?, self.zone))
}

/// Adds specified weeks to this datetime, and returns a new datetime.
pub fn add_weeks(
  self : ZonedDateTime,
  weeks : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_weeks(weeks)?, self.zone))
}

/// Adds specified days to this datetime, and returns a new datetime.
pub fn add_days(
  self : ZonedDateTime,
  days : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_days(days)?, self.zone))
}

/// Adds specified hours to this datetime, and returns a new datetime.
pub fn add_hours(
  self : ZonedDateTime,
  hours : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_hours(hours)?, self.zone))
}

/// Adds specified minutes to this datetime, and returns a new datetime.
pub fn add_minutes(
  self : ZonedDateTime,
  minutes : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_minutes(minutes)?, self.zone))
}

/// Adds specified seconds to this datetime, and returns a new datetime.
pub fn add_seconds(
  self : ZonedDateTime,
  seconds : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_seconds(seconds)?, self.zone))
}

/// Adds specified nanoseconds to this datetime, and returns a new datetime.
pub fn add_nanoseconds(
  self : ZonedDateTime,
  nanoseconds : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_nanoseconds(nanoseconds)?, self.zone))
}

/// Returns a new datetime with the specified year.
pub fn with_year(
  self : ZonedDateTime,
  year : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_year(year)?, self.zone))
}

/// Returns a new datetime with the specified month.
pub fn with_month(
  self : ZonedDateTime,
  month : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_month(month)?, self.zone))
}

/// Returns a new datetime with the specified day of the month.
pub fn with_day(
  self : ZonedDateTime,
  day : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_day(day)?, self.zone))
}

/// Returns a new datetime with the specified ordinal day of the year.
pub fn with_ordinal(
  self : ZonedDateTime,
  ordinal : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_ordinal(ordinal)?, self.zone))
}

/// Returns a new datetime with the specified hour.
pub fn with_hour(
  self : ZonedDateTime,
  hour : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_hour(hour)?, self.zone))
}

/// Returns a new datetime with the specified minute.
pub fn with_minute(
  self : ZonedDateTime,
  minute : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_minute(minute)?, self.zone))
}

/// Returns a new datetime with the specified second.
pub fn with_second(
  self : ZonedDateTime,
  second : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_second(second)?, self.zone))
}

/// Returns a new datetime with the specified nanosecond.
pub fn with_nanosecond(
  self : ZonedDateTime,
  nanosecond : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_nanosecond(nanosecond)?, self.zone))
}

fn create_from_plain(datetime : PlainDateTime, zone : Zone) -> ZonedDateTime {
  let offset = zone.lookup_offset(datetime.to_unix_second())
  { datetime, zone, offset }
}
