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

struct PlainDateTime {
  date : PlainDate
  time : PlainTime
} derive(Eq, Compare)

pub fn PlainDateTime::of(
  year : Int,
  month : Int,
  day : Int,
  ~hour : Int = 0,
  ~minute : Int = 0,
  ~second : Int = 0,
  ~nanosecond : Int = 0
) -> Result[PlainDateTime, String] {
  Ok(
    {
      date: PlainDate::of(year, month, day)?,
      time: PlainTime::of(hour, minute, second, nanosecond)?,
    },
  )
}

pub fn PlainDateTime::from_unix_second(
  second : Int64,
  nanosecond : Int,
  offset : ZoneOffset
) -> Result[PlainDateTime, String] {
  if not(validate_nano(nanosecond)) {
    return Err(invalid_date_time_err)
  }
  let sec = second + offset.seconds().to_int64()
  let unix_day = floor_div_int64(sec, seconds_per_day)?
  let seconds_of_day = floor_mod_int64(sec, seconds_per_day)?
  let date = PlainDate::from_unix_day(unix_day)?
  let time = PlainTime::from_nanosecond_of_day(
    seconds_of_day * nanoseconds_per_second + nanosecond.to_int64(),
  )?
  Ok({ date, time })
}

pub fn to_unix_second(self : PlainDateTime) -> Int64 {
  self.date.to_unix_day() * seconds_per_day + self.time.second_of_day().to_int64()
}

pub fn PlainDateTime::from_string(
  str : String
) -> Result[PlainDateTime, String] {
  // TODO: better parsing implementation
  let split = split(str, 'T')
  if split.length() != 2 {
    return Err(invalid_date_time_err)
  }
  let date = PlainDate::from_string(split[0])?
  let time = PlainTime::from_string(split[1])?
  Ok({ date, time })
}

pub fn to_string(self : PlainDateTime) -> String {
  let buf = Buffer::make(18)
  buf.write_string(self.date.to_string())
  buf.write_char('T')
  buf.write_string(self.time.to_string())
  buf.to_string()
}

pub fn era(self : PlainDateTime) -> String {
  self.date.era()
}

pub fn era_year(self : PlainDateTime) -> Int {
  self.date.era_year()
}

pub fn year(self : PlainDateTime) -> Int {
  self.date.year()
}

pub fn month(self : PlainDateTime) -> Int {
  self.date.month()
}

pub fn day(self : PlainDateTime) -> Int {
  self.date.day()
}

pub fn weekday(self : PlainDateTime) -> Weekday {
  self.date.weekday()
}

pub fn ordinal(self : PlainDateTime) -> Int {
  self.date.ordinal()
}

pub fn days_in_week(self : PlainDateTime) -> Int {
  self.date.days_in_week()
}

pub fn days_in_month(self : PlainDateTime) -> Int {
  self.date.days_in_month()
}

pub fn days_in_year(self : PlainDateTime) -> Int {
  self.date.days_in_year()
}

pub fn months_in_year(self : PlainDateTime) -> Int {
  self.date.months_in_year()
}

pub fn in_leap_year(self : PlainDateTime) -> Bool {
  self.date.in_leap_year()
}

pub fn hour(self : PlainDateTime) -> Int {
  self.time.hour()
}

pub fn minute(self : PlainDateTime) -> Int {
  self.time.minute()
}

pub fn second(self : PlainDateTime) -> Int {
  self.time.second()
}

pub fn nanosecond(self : PlainDateTime) -> Int {
  self.time.nanosecond()
}

pub fn add_years(
  self : PlainDateTime,
  years : Int64
) -> Result[PlainDateTime, String] {
  Ok({ ..self, date: self.date.add_years(years)? })
}

pub fn add_months(
  self : PlainDateTime,
  months : Int64
) -> Result[PlainDateTime, String] {
  Ok({ ..self, date: self.date.add_months(months)? })
}

pub fn add_weeks(
  self : PlainDateTime,
  weeks : Int64
) -> Result[PlainDateTime, String] {
  Ok({ ..self, date: self.date.add_weeks(weeks)? })
}

pub fn add_days(
  self : PlainDateTime,
  days : Int64
) -> Result[PlainDateTime, String] {
  Ok({ ..self, date: self.date.add_days(days)? })
}

pub fn add_period(
  self : PlainDateTime,
  period : Period
) -> Result[PlainDateTime, String] {
  Ok({ ..self, date: self.date.add_period(period)? })
}

pub fn add_hours(
  self : PlainDateTime,
  hours : Int64
) -> Result[PlainDateTime, String] {
  if hours == 0L {
    return Ok(self)
  }
  self.overflowing_add(h=hours)
}

pub fn add_minutes(
  self : PlainDateTime,
  minutes : Int64
) -> Result[PlainDateTime, String] {
  if minutes == 0L {
    return Ok(self)
  }
  self.overflowing_add(m=minutes)
}

pub fn add_seconds(
  self : PlainDateTime,
  seconds : Int64
) -> Result[PlainDateTime, String] {
  if seconds == 0L {
    return Ok(self)
  }
  self.overflowing_add(s=seconds)
}

pub fn add_nanoseconds(
  self : PlainDateTime,
  nanoseconds : Int64
) -> Result[PlainDateTime, String] {
  if nanoseconds == 0L {
    return Ok(self)
  }
  self.overflowing_add(ns=nanoseconds)
}

pub fn add_duration(
  self : PlainDateTime,
  duration : Duration
) -> Result[PlainDateTime, String] {
  if duration.is_zero() {
    return Ok(self)
  }
  self.overflowing_add(s=duration.secs, ns=duration.nanos.to_int64())
}

pub fn with_year(
  self : PlainDateTime,
  year : Int
) -> Result[PlainDateTime, String] {
  Ok({ ..self, date: self.date.with_year(year)? })
}

pub fn with_month(
  self : PlainDateTime,
  month : Int
) -> Result[PlainDateTime, String] {
  Ok({ ..self, date: self.date.with_month(month)? })
}

pub fn with_day(
  self : PlainDateTime,
  day : Int
) -> Result[PlainDateTime, String] {
  Ok({ ..self, date: self.date.with_day(day)? })
}

pub fn with_ordinal(
  self : PlainDateTime,
  ordinal : Int
) -> Result[PlainDateTime, String] {
  Ok({ ..self, date: self.date.with_ordinal(ordinal)? })
}

pub fn with_hour(
  self : PlainDateTime,
  hour : Int
) -> Result[PlainDateTime, String] {
  Ok({ ..self, time: self.time.with_hour(hour)? })
}

pub fn with_minute(
  self : PlainDateTime,
  minute : Int
) -> Result[PlainDateTime, String] {
  Ok({ ..self, time: self.time.with_minute(minute)? })
}

pub fn with_second(
  self : PlainDateTime,
  second : Int
) -> Result[PlainDateTime, String] {
  Ok({ ..self, time: self.time.with_second(second)? })
}

pub fn with_nanosecond(
  self : PlainDateTime,
  nanosecond : Int
) -> Result[PlainDateTime, String] {
  Ok({ ..self, time: self.time.with_nanosecond(nanosecond)? })
}

pub fn to_plain_date(self : PlainDateTime) -> PlainDate {
  self.date
}

pub fn to_plain_time(self : PlainDateTime) -> PlainTime {
  self.time
}

// *****************************
// * internal helper functions *
// *****************************

fn overflowing_add(
  self : PlainDateTime,
  ~h : Int64 = 0L,
  ~m : Int64 = 0L,
  ~s : Int64 = 0L,
  ~ns : Int64 = 0L
) -> Result[PlainDateTime, String] {
  if h == 0L && m == 0L && s == 0L && ns == 0L {
    return Ok(self)
  }
  let mut date = self.date
  let days_to_add = h / hours_per_day + m / minutes_per_day + s / seconds_per_day +
    ns / nanoseconds_per_day
  let nanos_to_add = h % hours_per_day * nanoseconds_per_hour + m % minutes_per_day *
    nanoseconds_per_minute + s % seconds_per_day * nanoseconds_per_second + ns %
    nanoseconds_per_day
  let current_nanos = self.time.nanosecond_of_day()
  let mut total_nanos = current_nanos + nanos_to_add
  let total_days = days_to_add + floor_div_int64(
      total_nanos, nanoseconds_per_day,
    )?
  total_nanos = floor_mod_int64(total_nanos, nanoseconds_per_day)?
  let time = if current_nanos == total_nanos {
    self.time
  } else {
    PlainTime::from_nanosecond_of_day(total_nanos)?
  }
  date = date.add_days(total_days)?
  Ok({ date, time })
}
