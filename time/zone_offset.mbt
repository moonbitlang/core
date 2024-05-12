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

/// Time offset from UTC.
struct ZoneOffset {
  id : String
  seconds : Int
  dst : Bool
}

let max_offset_hours = 18

let min_offset_hours = -18

let max_offset_seconds : Int = max_offset_hours * seconds_per_hour.to_int()

let min_offset_seconds : Int = min_offset_hours * seconds_per_hour.to_int()

/// UTC+0 offset.
pub let utc_offset : ZoneOffset = ZoneOffset::{
  id: "Z",
  seconds: 0,
  dst: false,
}

/// Creates a offset from hours, minutes and seconds.
pub fn ZoneOffset::of(
  ~hours : Int = 0,
  ~minutes : Int = 0,
  ~seconds : Int = 0
) -> Result[ZoneOffset, String] {
  validate_offset(hours, minutes, seconds)?
  let secs = hours * seconds_per_hour.to_int() + minutes * seconds_per_minute.to_int() +
    seconds
  ZoneOffset::from_seconds(secs)
}

/// Creates a offset from seconds.
pub fn ZoneOffset::from_seconds(seconds : Int) -> Result[ZoneOffset, String] {
  if seconds == 0 {
    return Ok(utc_offset)
  }
  if seconds < min_offset_seconds || seconds > max_offset_seconds {
    return Err(invalid_offset_err)
  }
  Ok({ id: create_id(seconds), seconds, dst: false })
}

/// Returns the offset id.
pub fn to_string(self : ZoneOffset) -> String {
  self.id
}

pub fn op_equal(self : ZoneOffset, other : ZoneOffset) -> Bool {
  self.seconds == other.seconds
}

pub fn compare(self : ZoneOffset, other : ZoneOffset) -> Int {
  other.seconds - self.seconds
}

/// Returns the offset id.
pub fn id(self : ZoneOffset) -> String {
  self.id
}

/// Returns the total seconds of this offset.
pub fn seconds(self : ZoneOffset) -> Int {
  self.seconds
}

/// Checks if this offset is daylight saving time.
pub fn is_dst(self : ZoneOffset) -> Bool {
  self.dst
}

fn create_id(secs : Int) -> String {
  if secs == 0 {
    return "Z"
  }
  let abs_secs = secs.abs()
  let offset_hours = abs_secs / seconds_per_hour.to_int()
  let offset_mins = abs_secs % seconds_per_hour.to_int() / seconds_per_minute.to_int()
  let offset_secs = abs_secs % seconds_per_minute.to_int()
  let buf = Buffer::make(9)
  buf.write_char(if secs < 0 { '-' } else { '+' })
  buf.write_string(add_prefix_zero(offset_hours.to_string(), 2))
  buf.write_char(':')
  buf.write_string(add_prefix_zero(offset_mins.to_string(), 2))
  if offset_secs > 0 {
    buf.write_char(':')
    buf.write_string(add_prefix_zero(offset_secs.to_string(), 2))
  }
  buf.to_string()
}

fn validate_offset(h : Int, m : Int, s : Int) -> Result[Unit, String] {
  if h < min_offset_hours || h > max_offset_hours {
    return Err(invalid_offset_err)
  }
  if m < -59 || m > 59 {
    return Err(invalid_offset_err)
  }
  if s < -59 || s > 59 {
    return Err(invalid_offset_err)
  }
  if h > 0 && (m < 0 || s < 0) || h < 0 && (m > 0 || s > 0) {
    return Err(invalid_offset_err)
  }
  if m > 0 && s < 0 || m < 0 && s > 0 {
    return Err(invalid_offset_err)
  }
  if h.abs() == 18 && (m != 0 || s != 0) {
    return Err(invalid_offset_err)
  }
  Ok(())
}
