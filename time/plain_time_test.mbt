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

test "of" {
  inspect(PlainTime::of(0, 0, 0, 0), content="Ok(00:00:00)")?
  inspect(PlainTime::of(24, 0, 0, 0), content="Ok(24:00:00)")?
  inspect(
    PlainTime::of(23, 59, 59, 999_999_999),
    content="Ok(23:59:59.999999999)",
  )?
  inspect(PlainTime::of(24, 0, 0, 1), content="Err(Invalid time)")?
  inspect(PlainTime::of(-1, 0, 0, 0), content="Err(Invalid time)")?
}

test "from_string" {
  inspect(PlainTime::from_string("00:00"), content="Ok(00:00:00)")?
  inspect(PlainTime::from_string("23:59"), content="Ok(23:59:00)")?
  inspect(PlainTime::from_string("24:00"), content="Ok(24:00:00)")?
  inspect(PlainTime::from_string("23:59:59"), content="Ok(23:59:59)")?
  inspect(PlainTime::from_string("01:00:00.123"), content="Ok(01:00:00.123)")?
  inspect(
    PlainTime::from_string("01:00:00.0000123"),
    content="Ok(01:00:00.0000123)",
  )?
  inspect(PlainTime::from_string("1:00"), content="Err(Invalid time)")?
  inspect(PlainTime::from_string("10:0"), content="Err(Invalid time)")?
  inspect(PlainTime::from_string("100000"), content="Err(Invalid time)")?
  inspect(PlainTime::from_string("123:00:00"), content="Err(Invalid time)")?
  inspect(
    PlainTime::from_string("10:00:00.123zzz"),
    content="Err(invalid syntax)",
  )?
  inspect(PlainTime::from_string("z1:00:00"), content="Err(invalid syntax)")?
}

test "getters" {
  let time = PlainTime::of(1, 2, 3, 400)?
  inspect(time.hour(), content="1")?
  inspect(time.minute(), content="2")?
  inspect(time.second(), content="3")?
  inspect(time.nanosecond(), content="400")?
}

test "second_of_day" {
  inspect(PlainTime::of(0, 0, 0, 0)?.second_of_day(), content="0")?
  inspect(PlainTime::of(12, 30, 30, 0)?.second_of_day(), content="45030")?
  inspect(PlainTime::of(24, 0, 0, 0)?.second_of_day(), content="86400")?
}

test "nanosecond_of_day" {
  inspect(PlainTime::of(0, 0, 0, 0)?.nanosecond_of_day(), content="0")?
  inspect(
    PlainTime::of(12, 30, 30, 123456789)?.nanosecond_of_day(),
    content="45030123456789",
  )?
  inspect(
    PlainTime::of(24, 0, 0, 0)?.nanosecond_of_day(),
    content="86400000000000",
  )?
}

test "from_second_of_day" {
  inspect(PlainTime::from_second_of_day(0), content="Ok(00:00:00)")?
  inspect(PlainTime::from_second_of_day(86400), content="Ok(24:00:00)")?
  inspect(PlainTime::from_second_of_day(45030), content="Ok(12:30:30)")?
  inspect(PlainTime::from_second_of_day(12345), content="Ok(03:25:45)")?
  inspect(PlainTime::from_second_of_day(-1), content="Err(Invalid time)")?
  inspect(PlainTime::from_second_of_day(86401), content="Err(Invalid time)")?
}

test "from_nanosecond_of_day" {
  inspect(PlainTime::from_nanosecond_of_day(0L), content="Ok(00:00:00)")?
  inspect(
    PlainTime::from_nanosecond_of_day(86400000000000L),
    content="Ok(24:00:00)",
  )?
  inspect(
    PlainTime::from_nanosecond_of_day(45030123456789L),
    content="Ok(12:30:30.123456789)",
  )?
  inspect(PlainTime::from_nanosecond_of_day(-1L), content="Err(Invalid time)")?
  inspect(
    PlainTime::from_nanosecond_of_day(86400000000001L),
    content="Err(Invalid time)",
  )?
}

test "add_hours" {
  let time = PlainTime::of(10, 0, 0, 0)?
  inspect(time.add_hours(-1L), content="Ok(09:00:00)")?
  inspect(time.add_hours(0L), content="Ok(10:00:00)")?
  inspect(time.add_hours(1L), content="Ok(11:00:00)")?
  inspect(time.add_hours(12L), content="Ok(22:00:00)")?
  inspect(time.add_hours(24L), content="Ok(10:00:00)")?
  inspect(time.add_hours(25L), content="Ok(11:00:00)")?
  inspect(time.add_hours(26L), content="Ok(12:00:00)")?
  inspect(time.add_hours(27L), content="Ok(13:00:00)")?
  inspect(time.add_hours(28L), content="Ok(14:00:00)")?
  inspect(time.add_hours(29L), content="Ok(15:00:00)")?
  inspect(time.add_hours(30L), content="Ok(16:00:00)")?
  inspect(time.add_hours(31L), content="Ok(17:00:00)")?
  inspect(time.add_hours(32L), content="Ok(18:00:00)")?
  inspect(time.add_hours(33L), content="Ok(19:00:00)")?
  inspect(time.add_hours(34L), content="Ok(20:00:00)")?
  inspect(time.add_hours(35L), content="Ok(21:00:00)")?
  inspect(time.add_hours(36L), content="Ok(22:00:00)")?
  inspect(time.add_hours(37L), content="Ok(23:00:00)")?
  inspect(time.add_hours(38L), content="Ok(00:00:00)")?
  inspect(time.add_hours(39L), content="Ok(01:00:00)")?
  inspect(time.add_hours(40L), content="Ok(02:00:00)")?
  inspect(time.add_hours(Int64::min_value()), content="Ok(02:00:00)")?
  inspect(time.add_hours(Int64::max_value()), content="Ok(17:00:00)")?
}

test "add_minutes" {
  let time = PlainTime::of(0, 30, 0, 0)?
  inspect(time.add_minutes(-1L), content="Ok(00:29:00)")?
  inspect(time.add_minutes(0L), content="Ok(00:30:00)")?
  inspect(time.add_minutes(1L), content="Ok(00:31:00)")?
  inspect(time.add_minutes(30L), content="Ok(01:00:00)")?
  inspect(time.add_minutes(360L), content="Ok(06:30:00)")?
  inspect(time.add_minutes(720L), content="Ok(12:30:00)")?
  inspect(time.add_minutes(1234L), content="Ok(21:04:00)")?
  inspect(time.add_minutes(1440L), content="Ok(00:30:00)")?
  inspect(time.add_minutes(2345L), content="Ok(15:35:00)")?
  inspect(time.add_minutes(2880L), content="Ok(00:30:00)")?
  inspect(time.add_minutes(Int64::min_value()), content="Ok(06:22:00)")?
  inspect(time.add_minutes(Int64::max_value()), content="Ok(18:37:00)")?
}

test "add_seconds" {
  let time = PlainTime::of(0, 0, 30, 0)?
  inspect(time.add_seconds(-1L), content="Ok(00:00:29)")?
  inspect(time.add_seconds(0L), content="Ok(00:00:30)")?
  inspect(time.add_seconds(1L), content="Ok(00:00:31)")?
  inspect(time.add_seconds(30L), content="Ok(00:01:00)")?
  inspect(time.add_seconds(60L), content="Ok(00:01:30)")?
  inspect(time.add_seconds(12345678L), content="Ok(21:21:48)")?
  inspect(time.add_seconds(Int64::min_value()), content="Ok(08:30:22)")?
  inspect(time.add_seconds(Int64::max_value()), content="Ok(15:30:37)")?
  inspect(time.add_seconds(24L * 60L * 60L), content="Ok(00:00:30)")?
}

test "add_nanoseconds" {
  let time = PlainTime::of(0, 0, 00, 1000)?
  inspect(time.add_nanoseconds(-1L), content="Ok(00:00:00.000000999)")?
  inspect(time.add_nanoseconds(0L), content="Ok(00:00:00.000001)")?
  inspect(time.add_nanoseconds(1L), content="Ok(00:00:00.000001001)")?
  inspect(time.add_nanoseconds(123456789L), content="Ok(00:00:00.123457789)")?
  inspect(
    time.add_nanoseconds(Int64::min_value()),
    content="Ok(00:12:43.145225192)",
  )?
  inspect(
    time.add_nanoseconds(Int64::max_value()),
    content="Ok(23:47:16.854776807)",
  )?
  inspect(
    time.add_nanoseconds(nanoseconds_per_day),
    content="Ok(00:00:00.000001)",
  )?
}

test "with_hour" {
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_hour(1),
    content="Ok(01:20:30.0000004)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_hour(10),
    content="Ok(10:20:30.0000004)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_hour(0),
    content="Ok(00:20:30.0000004)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_hour(-1),
    content="Err(Invalid time)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_hour(24),
    content="Err(Invalid time)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_hour(25),
    content="Err(Invalid time)",
  )?
}

test "with_minute" {
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_minute(20),
    content="Ok(01:20:30.0000004)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_minute(10),
    content="Ok(01:10:30.0000004)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_minute(0),
    content="Ok(01:00:30.0000004)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_minute(59),
    content="Ok(01:59:30.0000004)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_minute(-1),
    content="Err(Invalid time)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_minute(60),
    content="Err(Invalid time)",
  )?
}

test "with_second" {
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_second(30),
    content="Ok(01:20:30.0000004)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_second(10),
    content="Ok(01:20:10.0000004)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_second(0),
    content="Ok(01:20:00.0000004)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_second(59),
    content="Ok(01:20:59.0000004)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_second(-1),
    content="Err(Invalid time)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_second(60),
    content="Err(Invalid time)",
  )?
}

test "with_nanosecond" {
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_nanosecond(400),
    content="Ok(01:20:30.0000004)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_nanosecond(100),
    content="Ok(01:20:30.0000001)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_nanosecond(0),
    content="Ok(01:20:30)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_nanosecond(999_999_999),
    content="Ok(01:20:30.999999999)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_nanosecond(-1),
    content="Err(Invalid time)",
  )?
  inspect(
    PlainTime::of(1, 20, 30, 400)?.with_nanosecond(1_000_000_000),
    content="Err(Invalid time)",
  )?
}

test "until" {
  let time = PlainTime::of(12, 0, 0, 0)?
  inspect(
    time.until(PlainTime::of(13, 30, 30, 1_000_000)?),
    content="Ok(PT1H30M30.001S)",
  )?
  inspect(
    time.until(PlainTime::of(11, 30, 30, 1_000_000)?),
    content="Ok(PT-29M-29.999S)",
  )?
}

test "add_duration" {
  let time = PlainTime::of(12, 0, 0, 0)?
  inspect(
    time.add_duration(
      Duration::of(hours=1L, minutes=30L, seconds=30L, nanoseconds=1_000_000L)?,
    ),
    content="Ok(13:30:30.001)",
  )?
  inspect(
    time.add_duration(
      Duration::of(minutes=-29L, seconds=-29L, nanoseconds=-999_000_000L)?,
    ),
    content="Ok(11:30:30.001)",
  )?
  inspect(time.add_duration(Duration::zero()), content="Ok(12:00:00)")?
}

test "at_date" {
  let time = PlainTime::of(12, 0, 0, 0)?
  let date = PlainDate::of(2000, 1, 1)?
  inspect(time.at_date(date), content="2000-01-01T12:00:00")?
}
