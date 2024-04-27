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
  inspect(ZoneOffset::of(), content="Ok(Z)")?
  inspect(ZoneOffset::of(hours=8), content="Ok(+08:00)")?
  inspect(ZoneOffset::of(hours=-8), content="Ok(-08:00)")?
  inspect(ZoneOffset::of(hours=18), content="Ok(+18:00)")?
  inspect(ZoneOffset::of(hours=-18), content="Ok(-18:00)")?
  inspect(
    ZoneOffset::of(hours=1, minutes=30, seconds=30),
    content="Ok(+01:30:30)",
  )?
  inspect(ZoneOffset::of(hours=19), content="Err(Invalid offset)")?
  inspect(ZoneOffset::of(hours=-19), content="Err(Invalid offset)")?
  inspect(ZoneOffset::of(minutes=60), content="Err(Invalid offset)")?
  inspect(ZoneOffset::of(minutes=-60), content="Err(Invalid offset)")?
  inspect(ZoneOffset::of(seconds=60), content="Err(Invalid offset)")?
  inspect(ZoneOffset::of(seconds=-60), content="Err(Invalid offset)")?
  inspect(
    ZoneOffset::of(hours=1, minutes=-30, seconds=-30),
    content="Err(Invalid offset)",
  )?
  inspect(
    ZoneOffset::of(hours=-1, minutes=30, seconds=30),
    content="Err(Invalid offset)",
  )?
  inspect(
    ZoneOffset::of(minutes=-30, seconds=30),
    content="Err(Invalid offset)",
  )?
  inspect(
    ZoneOffset::of(minutes=30, seconds=-30),
    content="Err(Invalid offset)",
  )?
  inspect(ZoneOffset::of(hours=18, minutes=1), content="Err(Invalid offset)")?
  inspect(ZoneOffset::of(hours=-18, seconds=1), content="Err(Invalid offset)")?
}

test "from_seconds" {
  inspect(ZoneOffset::from_seconds(8 * 60 * 60), content="Ok(+08:00)")?
  inspect(ZoneOffset::from_seconds(0), content="Ok(Z)")?
  inspect(ZoneOffset::from_seconds(18 * 60 * 60), content="Ok(+18:00)")?
  inspect(ZoneOffset::from_seconds(-18 * 60 * 60), content="Ok(-18:00)")?
  inspect(ZoneOffset::from_seconds(19 * 60 * 60), content="Err(Invalid offset)")?
  inspect(
    ZoneOffset::from_seconds(-19 * 60 * 60),
    content="Err(Invalid offset)",
  )?
}

test "utc" {
  inspect(utc_offset, content="Z")?
  inspect(utc_offset.id(), content="Z")?
  inspect(utc_offset.seconds(), content="0")?
  inspect(utc_offset.is_dst(), content="false")?
}

test "compare" {
  let o1 = ZoneOffset::from_seconds(10)?
  let o2 = ZoneOffset::from_seconds(-10)?
  inspect(o1 > o2, content="false")?
  inspect(o1 == o2, content="false")?
  inspect(o1 < o2, content="true")?
  inspect(o1 == o1, content="true")?
}
