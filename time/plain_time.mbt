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

let min_hour = 0

let max_hour = 23

let min_minute = 0

let max_minute = 59

let min_second = 0

let max_second = 59

let min_nanoseconds = 0

let max_nanoseconds = 999_999_999

let seconds_per_minute = 60L

let seconds_per_hour : Int64 = seconds_per_minute * 60L

// let seconds_per_day : Int64 = seconds_per_hour * 24L

// let seconds_per_week : Int64 = seconds_per_day * 7L

struct PlainTime {
  hour : Int
  minute : Int
  second : Int
  nanosecond : Int
} derive(Debug, Eq, Compare)

pub fn PlainTime::from(
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

fn validate_time(h : Int, m : Int, s : Int, ns : Int) -> Bool {
  let valid_hour = h >= min_hour && h <= max_hour
  let valid_minute = m >= min_minute && m <= max_minute
  let valid_second = s >= min_second && s <= max_second
  let valid_nanosecond = ns >= min_nanoseconds && ns <= max_nanoseconds
  let zero = h == 24 && m == 0 && s == 0 && ns == 0
  valid_hour && valid_minute && valid_second && valid_nanosecond || zero
}

test "validate_time" {
  inspect(validate_time(1, 0, 0, 0), content="true")?
  inspect(validate_time(0, 0, 0, 0), content="true")?
  inspect(validate_time(23, 59, 59, 0), content="true")?
  inspect(validate_time(24, 0, 0, 0), content="true")?
  inspect(validate_time(1, 59, 0, 0), content="true")?
  inspect(validate_time(1, 60, 0, 0), content="false")?
  inspect(validate_time(1, 0, 59, 0), content="true")?
  inspect(validate_time(1, 0, 60, 0), content="false")?
  inspect(validate_time(1, 0, 0, 999_999_999), content="true")?
  inspect(validate_time(1, 0, 0, 1_000_000_000), content="false")?
}
