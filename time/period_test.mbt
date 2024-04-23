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
  inspect(
    Period::of(years=1000, months=24, weeks=30, days=365),
    content="P1000Y24M30W365D",
  )?
}

test "between" {
  inspect(
    Period::between(PlainDate::of(2000, 1, 1)?, PlainDate::of(2000, 1, 1)?),
    content="P0D",
  )?
}

test "from_string" {
  inspect(Period::from_string("P10Y2M3W4D"), content="Ok(P10Y2M3W4D)")?
  inspect(Period::from_string("P2M3W4D10Y"), content="Ok(P10Y2M3W4D)")?
  inspect(Period::from_string("10Y"), content="Err(Invalid period)")?
  inspect(Period::from_string("10Y0M"), content="Err(Invalid period)")?
  inspect(Period::from_string("P10YT3H"), content="Err(Invalid period)")?
  inspect(Period::from_string("P2.5Y"), content="Err(Invalid period)")?
}

test "getters" {
  let p = Period::of(years=1, months=2, weeks=3, days=4)
  inspect(p.years(), content="1")?
  inspect(p.months(), content="2")?
  inspect(p.weeks(), content="3")?
  inspect(p.days(), content="4")?
}

test "is_zero" {
  inspect(Period::of().is_zero(), content="true")?
  inspect(Period::of(years=1).is_zero(), content="false")?
  inspect(Period::of(months=1).is_zero(), content="false")?
  inspect(Period::of(weeks=1).is_zero(), content="false")?
  inspect(Period::of(days=1).is_zero(), content="false")?
}

test "is_neg" {
  inspect(Period::of().is_neg(), content="false")?
  inspect(Period::of(years=1, months=1).is_neg(), content="false")?
  inspect(Period::of(years=-1, months=1).is_neg(), content="true")?
}

test "get_calendar" {
  inspect(
    Period::of().get_calendar().get_type() == iso_calendar.get_type(),
    content="true",
  )?
}

test "add_years" {
  let p = Period::of(years=10)
  inspect(p.add_years(0), content="Ok(P10Y)")?
  inspect(p.add_years(1), content="Ok(P11Y)")?
  inspect(p.add_years(-1), content="Ok(P9Y)")?
}

test "add_months" {
  let p = Period::of(months=10)
  inspect(p.add_months(0), content="Ok(P10M)")?
  inspect(p.add_months(1), content="Ok(P11M)")?
  inspect(p.add_months(-1), content="Ok(P9M)")?
}

test "add_weeks" {
  let p = Period::of(weeks=10)
  inspect(p.add_weeks(0), content="Ok(P10W)")?
  inspect(p.add_weeks(1), content="Ok(P11W)")?
  inspect(p.add_weeks(-1), content="Ok(P9W)")?
}

test "add_days" {
  let p = Period::of(days=10)
  inspect(p.add_days(0), content="Ok(P10D)")?
  inspect(p.add_days(1), content="Ok(P11D)")?
  inspect(p.add_days(-1), content="Ok(P9D)")?
}

test "with_years" {
  inspect(Period::of(years=1).with_years(1), content="P1Y")?
  inspect(Period::of(years=1).with_years(2), content="P2Y")?
  inspect(Period::of(years=1).with_years(-1), content="P-1Y")?
}

test "with_months" {
  inspect(Period::of(months=1).with_months(1), content="P1M")?
  inspect(Period::of(months=1).with_months(2), content="P2M")?
  inspect(Period::of(months=1).with_months(-1), content="P-1M")?
}
test "with_weeks" {
  inspect(Period::of(weeks=1).with_weeks(1), content="P1W")?
  inspect(Period::of(weeks=1).with_weeks(2), content="P2W")?
  inspect(Period::of(weeks=1).with_weeks(-1), content="P-1W")?
}
test "with_days" {
  inspect(Period::of(days=1).with_days(1), content="P1D")?
  inspect(Period::of(days=1).with_days(2), content="P2D")?
  inspect(Period::of(days=1).with_days(-1), content="P-1D")?
}