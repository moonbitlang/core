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
  inspect(PlainDate::of(2008, 8, 8), content="Ok(2008-08-08)")?
  inspect(PlainDate::of(0, 1, 1), content="Ok(0000-01-01)")?
  inspect(PlainDate::of(1, 1, 1), content="Ok(0001-01-01)")?
  inspect(PlainDate::of(2000, 2, 29), content="Ok(2000-02-29)")?
  inspect(PlainDate::of(2001, 2, 29), content="Err(Invalid date)")?
  inspect(PlainDate::of(2001, 1, 32), content="Err(Invalid date)")?
  inspect(PlainDate::of(10000, 1, 1), content="Err(Invalid date)")?
}

test "from_string" {
  inspect(PlainDate::from_string("2008-08-08"), content="Ok(2008-08-08)")?
  inspect(PlainDate::from_string("0000-01-01"), content="Ok(0000-01-01)")?
  inspect(PlainDate::from_string("0001-01-01"), content="Ok(0001-01-01)")?
  inspect(PlainDate::from_string("10000-01-01"), content="Err(Invalid date)")?
  inspect(PlainDate::from_string("-1970-01-01"), content="Err(Invalid date)")?
  inspect(PlainDate::from_string("-01-01"), content="Err(Invalid date)")?
  inspect(PlainDate::from_string("12-31"), content="Err(Invalid date)")?
  inspect(PlainDate::from_string("-01"), content="Err(Invalid date)")?
}

test "compare" {
  inspect(
    PlainDate::of(2000, 1, 1)? == PlainDate::of(2000, 1, 1)?,
    content="true",
  )?
  inspect(
    PlainDate::of(2001, 1, 1)? > PlainDate::of(2000, 1, 1)?,
    content="true",
  )?
  inspect(
    PlainDate::of(2000, 1, 1)? < PlainDate::of(2001, 1, 1)?,
    content="true",
  )?
  inspect(
    PlainDate::of(2000, 2, 1)? > PlainDate::of(2000, 1, 1)?,
    content="true",
  )?
  inspect(
    PlainDate::of(2000, 1, 1)? < PlainDate::of(2000, 2, 1)?,
    content="true",
  )?
  inspect(
    PlainDate::of(2000, 1, 2)? > PlainDate::of(2000, 1, 1)?,
    content="true",
  )?
  inspect(
    PlainDate::of(2000, 1, 1)? < PlainDate::of(2000, 1, 2)?,
    content="true",
  )?
}
