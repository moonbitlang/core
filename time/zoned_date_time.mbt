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

struct ZonedDateTime {
  datetime : PlainDateTime
  zone : Zone
  offset : ZoneOffset
}

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

pub fn ZonedDateTime::from_plain_datetime(
  datetime : PlainDateTime,
  ~zone : Zone = utc_zone
) -> ZonedDateTime {
  create_from_plain(datetime, zone)
}

pub fn ZonedDateTime::from_unix_second(
  second : Int64,
  nanosecond : Int,
  ~zone : Zone = utc_zone
) -> Result[ZonedDateTime, String] {
  let offset = zone.lookup_offset(second)
  let datetime = PlainDateTime::from_unix_second(second, nanosecond, offset)?
  Ok({ datetime, zone, offset })
}

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

pub fn to_unix_second(self : ZonedDateTime) -> Int64 {
  self.datetime.to_unix_second() - self.offset.seconds().to_int64()
}

pub fn to_plain_date(self : ZonedDateTime) -> PlainDate {
  self.datetime.to_plain_date()
}

pub fn to_plain_time(self : ZonedDateTime) -> PlainTime {
  self.datetime.to_plain_time()
}

pub fn to_plain_date_time(self : ZonedDateTime) -> PlainDateTime {
  self.datetime
}

pub fn era(self : ZonedDateTime) -> String {
  self.datetime.era()
}

pub fn era_year(self : ZonedDateTime) -> Int {
  self.datetime.era_year()
}

pub fn year(self : ZonedDateTime) -> Int {
  self.datetime.year()
}

pub fn month(self : ZonedDateTime) -> Int {
  self.datetime.month()
}

pub fn day(self : ZonedDateTime) -> Int {
  self.datetime.day()
}

pub fn weekday(self : ZonedDateTime) -> Weekday {
  self.datetime.weekday()
}

pub fn ordinal(self : ZonedDateTime) -> Int {
  self.datetime.ordinal()
}

pub fn days_in_week(self : ZonedDateTime) -> Int {
  self.datetime.days_in_week()
}

pub fn days_in_month(self : ZonedDateTime) -> Int {
  self.datetime.days_in_month()
}

pub fn days_in_year(self : ZonedDateTime) -> Int {
  self.datetime.days_in_year()
}

pub fn months_in_year(self : ZonedDateTime) -> Int {
  self.datetime.months_in_year()
}

pub fn in_leap_year(self : ZonedDateTime) -> Bool {
  self.datetime.in_leap_year()
}

pub fn hour(self : ZonedDateTime) -> Int {
  self.datetime.hour()
}

pub fn minute(self : ZonedDateTime) -> Int {
  self.datetime.minute()
}

pub fn second(self : ZonedDateTime) -> Int {
  self.datetime.second()
}

pub fn nanosecond(self : ZonedDateTime) -> Int {
  self.datetime.nanosecond()
}

pub fn zone(self : ZonedDateTime) -> Zone {
  self.zone
}

pub fn offset(self : ZonedDateTime) -> ZoneOffset {
  self.offset
}

pub fn add_years(
  self : ZonedDateTime,
  years : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_years(years)?, self.zone))
}

pub fn add_months(
  self : ZonedDateTime,
  months : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_months(months)?, self.zone))
}

pub fn add_weeks(
  self : ZonedDateTime,
  weeks : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_weeks(weeks)?, self.zone))
}

pub fn add_days(
  self : ZonedDateTime,
  days : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_days(days)?, self.zone))
}

pub fn add_hours(
  self : ZonedDateTime,
  hours : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_hours(hours)?, self.zone))
}

pub fn add_minutes(
  self : ZonedDateTime,
  minutes : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_minutes(minutes)?, self.zone))
}

pub fn add_seconds(
  self : ZonedDateTime,
  seconds : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_seconds(seconds)?, self.zone))
}

pub fn add_nanoseconds(
  self : ZonedDateTime,
  nanoseconds : Int64
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.add_nanoseconds(nanoseconds)?, self.zone))
}

pub fn with_year(
  self : ZonedDateTime,
  year : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_year(year)?, self.zone))
}

pub fn with_month(
  self : ZonedDateTime,
  month : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_month(month)?, self.zone))
}

pub fn with_day(
  self : ZonedDateTime,
  day : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_day(day)?, self.zone))
}

pub fn with_ordinal(
  self : ZonedDateTime,
  ordinal : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_ordinal(ordinal)?, self.zone))
}

pub fn with_hour(
  self : ZonedDateTime,
  hour : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_hour(hour)?, self.zone))
}

pub fn with_minute(
  self : ZonedDateTime,
  minute : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_minute(minute)?, self.zone))
}

pub fn with_second(
  self : ZonedDateTime,
  second : Int
) -> Result[ZonedDateTime, String] {
  Ok(create_from_plain(self.datetime.with_second(second)?, self.zone))
}

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
