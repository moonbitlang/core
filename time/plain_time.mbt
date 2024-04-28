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

/// A time without a time zone
struct PlainTime {
  hour : Int
  minute : Int
  second : Int
  nanosecond : Int
} derive(Eq, Compare)

/// Creates a PlainTime from the hour, minute, second and nanosecond.
pub fn PlainTime::of(
  hour : Int,
  minute : Int,
  second : Int,
  nanosecond : Int
) -> Result[PlainTime, String] {
  if validate_time(hour, minute, second, nanosecond) {
    Ok({ hour, minute, second, nanosecond })
  } else {
    Err(invalid_time_err)
  }
}

/// Creates a PlainTime from a string, like '10:20:30.45678'.
pub fn PlainTime::from_string(str : String) -> Result[PlainTime, String] {
  // TODO: better parsing implementation
  if str.length() < 5 || str.length() > 18 || str[2] != ':' {
    return Err(invalid_time_err)
  }
  let mut hour = 0
  let mut minute = 0
  let mut second = 0
  let mut nanosecond = 0
  hour = @strconv.parse(str.substring(end=2))?
  minute = @strconv.parse(str.substring(start=3, end=5))?
  if str.length() > 7 {
    if str[5] != ':' {
      return Err(invalid_time_err)
    }
    second = @strconv.parse(str.substring(start=6, end=8))?
  }
  if str.length() > 9 && str[8] == '.' {
    let nano_str = str.substring(start=9)
    nanosecond = @strconv.parse(add_suffix_zero(nano_str, 9))?
  }
  PlainTime::of(hour, minute, second, nanosecond)
}

/// Returns a string representing the time.
pub fn PlainTime::to_string(self : PlainTime) -> String {
  let buf = Buffer::make(8)
  buf.write_string(add_prefix_zero(self.hour.to_string(), 2))
  buf.write_char(':')
  buf.write_string(add_prefix_zero(self.minute.to_string(), 2))
  buf.write_char(':')
  buf.write_string(add_prefix_zero(self.second.to_string(), 2))
  if self.nanosecond > 0 {
    buf.write_char('.')
    let nanos_str = (self.nanosecond.to_int64() + nanoseconds_per_second).to_string().substring(
      start=1,
    )
    buf.write_string(remove_suffix_zero(nanos_str))
  }
  buf.to_string()
}

/// Returns the hour of this time.
pub fn hour(self : PlainTime) -> Int {
  self.hour
}

/// Returns the minute of this time.
pub fn minute(self : PlainTime) -> Int {
  self.minute
}

/// Returns the second of this time.
pub fn second(self : PlainTime) -> Int {
  self.second
}

/// Returns the nanosecond of this time.
pub fn nanosecond(self : PlainTime) -> Int {
  self.nanosecond
}

/// Returns the total seconds of this time.
pub fn second_of_day(self : PlainTime) -> Int {
  let sec = self.hour * seconds_per_hour.to_int() + self.minute * seconds_per_minute.to_int() +
    self.second
  sec
}

/// Returns the total nanoseconds of this time.
pub fn nanosecond_of_day(self : PlainTime) -> Int64 {
  let sec = self.second_of_day()
  sec.to_int64() * nanoseconds_per_second + self.nanosecond.to_int64()
}

/// Creates a PlainTime from the total seconds of the day.
pub fn PlainTime::from_second_of_day(second : Int) -> Result[PlainTime, String] {
  if second < 0 || second > seconds_per_day.to_int() {
    return Err(invalid_time_err)
  }
  let mut sec = second.to_int64()
  let hour = sec / seconds_per_hour
  sec -= hour * seconds_per_hour
  let minute = sec / seconds_per_minute
  sec -= minute * seconds_per_minute
  PlainTime::of(hour.to_int(), minute.to_int(), sec.to_int(), 0)
}

/// Creates a PlainTime from the total nanoseconds of the day.
pub fn PlainTime::from_nanosecond_of_day(
  nanosecond : Int64
) -> Result[PlainTime, String] {
  if nanosecond < 0L || nanosecond > nanoseconds_per_day {
    return Err(invalid_time_err)
  }
  let mut nanos = nanosecond
  let hour = nanos / nanoseconds_per_hour
  nanos -= hour * nanoseconds_per_hour
  let minute = nanos / nanoseconds_per_minute
  nanos -= minute * nanoseconds_per_minute
  let second = nanos / nanoseconds_per_second
  nanos -= second * nanoseconds_per_second
  PlainTime::of(hour.to_int(), minute.to_int(), second.to_int(), nanos.to_int())
}

/// Adds specified hours to this time, and returns a new time.
pub fn add_hours(self : PlainTime, hours : Int64) -> Result[PlainTime, String] {
  if hours == 0L {
    return Ok(self)
  }
  let new_hour = (hours % hours_per_day + self.hour.to_int64()) % hours_per_day
  PlainTime::of(new_hour.to_int(), self.minute, self.second, self.nanosecond)
}

/// Adds specified minutes to this time, and returns a new time.
pub fn add_minutes(
  self : PlainTime,
  minutes : Int64
) -> Result[PlainTime, String] {
  if minutes == 0L {
    return Ok(self)
  }
  let mins = self.hour.to_int64() * minutes_per_hour + self.minute.to_int64()
  let new_mins = (minutes % minutes_per_day + mins + minutes_per_day) % minutes_per_day
  if mins == new_mins {
    return Ok(self)
  }
  let new_hour = new_mins / minutes_per_hour
  let new_minute = new_mins % minutes_per_hour
  PlainTime::of(
    new_hour.to_int(),
    new_minute.to_int(),
    self.second,
    self.nanosecond,
  )
}

/// Adds specified seconds to this time, and returns a new time.
pub fn add_seconds(
  self : PlainTime,
  seconds : Int64
) -> Result[PlainTime, String] {
  if seconds == 0L {
    return Ok(self)
  }
  let secs_of_day = self.second_of_day().to_int64()
  let new_secs_of_day = (seconds % seconds_per_day + secs_of_day + seconds_per_day) %
    seconds_per_day
  if secs_of_day == new_secs_of_day {
    return Ok(self)
  }
  let new_hour = new_secs_of_day / seconds_per_hour
  let new_minute = new_secs_of_day / seconds_per_minute % minutes_per_hour
  let new_second = new_secs_of_day % seconds_per_minute
  PlainTime::of(
    new_hour.to_int(),
    new_minute.to_int(),
    new_second.to_int(),
    self.nanosecond,
  )
}

/// Adds specified nanoseconds to this time, and returns a new time.
pub fn add_nanoseconds(
  self : PlainTime,
  nanoseconds : Int64
) -> Result[PlainTime, String] {
  if nanoseconds == 0L {
    return Ok(self)
  }
  let nanos = self.nanosecond_of_day()
  let new_nanos = (nanoseconds % nanoseconds_per_day + nanos + nanoseconds_per_day) %
    nanoseconds_per_day
  if nanos == new_nanos {
    return Ok(self)
  }
  PlainTime::from_nanosecond_of_day(new_nanos)
}

/// Adds a duration to this time, and returns a new time.
pub fn add_duration(
  self : PlainTime,
  duration : Duration
) -> Result[PlainTime, String] {
  if duration.is_zero() {
    return Ok(self)
  }
  self.add_nanoseconds(duration.to_nanoseconds())
}

/// Returns a new time with the specified hour.
pub fn with_hour(self : PlainTime, hour : Int) -> Result[PlainTime, String] {
  if hour == self.hour {
    return Ok(self)
  }
  PlainTime::of(hour, self.minute, self.second, self.nanosecond)
}

/// Returns a new time with the specified minute.
pub fn with_minute(self : PlainTime, minute : Int) -> Result[PlainTime, String] {
  if minute == self.minute {
    return Ok(self)
  }
  PlainTime::of(self.hour, minute, self.second, self.nanosecond)
}

/// Returns a new time with the specified second.
pub fn with_second(self : PlainTime, second : Int) -> Result[PlainTime, String] {
  if second == self.second {
    return Ok(self)
  }
  PlainTime::of(self.hour, self.minute, second, self.nanosecond)
}

/// Returns a new time with the specified nanosecond.
pub fn with_nanosecond(
  self : PlainTime,
  nanosecond : Int
) -> Result[PlainTime, String] {
  if nanosecond == self.nanosecond {
    return Ok(self)
  }
  PlainTime::of(self.hour, self.minute, self.second, nanosecond)
}

/// Returns the duration between this time and another time.
pub fn until(self : PlainTime, end : PlainTime) -> Result[Duration, String] {
  let nanoseconds = end.nanosecond_of_day() - self.nanosecond_of_day()
  Duration::of(~nanoseconds)
}

/// Combines this time with a date to creates a PlainDateTime
pub fn at_date(self : PlainTime, date : PlainDate) -> PlainDateTime {
  PlainDateTime::{ date, time: self }
}

// *****************************
// * internal helper functions *
// *****************************

let min_hour = 0

let max_hour = 23

let min_minute = 0

let max_minute = 59

let min_second = 0

let max_second = 59

let min_nanosecond = 0

let max_nanosecond = 999_999_999

let hours_per_day = 24L

let minutes_per_hour = 60L

let minutes_per_day : Int64 = 24L * minutes_per_hour

let seconds_per_minute = 60L

let seconds_per_hour : Int64 = seconds_per_minute * 60L

let seconds_per_day : Int64 = seconds_per_hour * 24L

let nanoseconds_per_second = 1_000_000_000L

let nanoseconds_per_minute : Int64 = nanoseconds_per_second * seconds_per_minute

let nanoseconds_per_hour : Int64 = nanoseconds_per_minute * minutes_per_hour

let nanoseconds_per_day : Int64 = nanoseconds_per_second * seconds_per_day

fn validate_time(h : Int, m : Int, s : Int, ns : Int) -> Bool {
  let valid_hour = validate_hour(h)
  let valid_minute = validate_minute(m)
  let valid_second = validate_second(s)
  let valid_nano = validate_nano(ns)
  let zero = h == 24 && m == 0 && s == 0 && ns == 0
  valid_hour && valid_minute && valid_second && valid_nano || zero
}

fn validate_hour(h : Int) -> Bool {
  h >= min_hour && h <= max_hour
}

fn validate_minute(m : Int) -> Bool {
  m >= min_minute && m <= max_minute
}

fn validate_second(s : Int) -> Bool {
  s >= min_second && s <= max_second
}

fn validate_nano(n : Int) -> Bool {
  n >= min_nanosecond && n <= max_nanosecond
}
