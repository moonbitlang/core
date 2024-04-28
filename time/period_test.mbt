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
  inspect(Period::of(years=1000, months=24, days=365), content="P1000Y24M365D")?
}

test "from_string" {
  inspect(Period::from_string("P10Y2M3D"), content="Ok(P10Y2M3D)")?
  inspect(Period::from_string("P-10Y-2M-3D"), content="Ok(P-10Y-2M-3D)")?
  inspect(Period::from_string("P2M3D10Y"), content="Ok(P2M3D)")?
  inspect(Period::from_string("10Y"), content="Err(Invalid period)")?
  inspect(Period::from_string("10Y0M"), content="Err(Invalid period)")?
  inspect(Period::from_string("P10YT3H"), content="Err(Invalid period)")?
  inspect(Period::from_string("P2.5Y"), content="Err(Invalid period)")?
}

test "getters" {
  let p = Period::of(years=1, months=2, days=3)
  inspect(p.years(), content="1")?
  inspect(p.months(), content="2")?
  inspect(p.days(), content="3")?
  inspect(p.to_total_months(), content="14")?
}

test "is_zero" {
  inspect(Period::zero().is_zero(), content="true")?
  inspect(Period::of().is_zero(), content="true")?
  inspect(Period::of(years=1).is_zero(), content="false")?
  inspect(Period::of(months=1).is_zero(), content="false")?
  inspect(Period::of(days=1).is_zero(), content="false")?
}

test "is_neg" {
  inspect(Period::of().is_neg(), content="false")?
  inspect(Period::of(years=1, months=1).is_neg(), content="false")?
  inspect(Period::of(years=-1, months=1).is_neg(), content="true")?
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
  let p = Period::of(days=10)
  inspect(p.add_weeks(0), content="Ok(P10D)")?
  inspect(p.add_weeks(1), content="Ok(P17D)")?
  inspect(p.add_weeks(-1), content="Ok(P3D)")?
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

test "with_days" {
  inspect(Period::of(days=1).with_days(1), content="P1D")?
  inspect(Period::of(days=1).with_days(2), content="P2D")?
  inspect(Period::of(days=1).with_days(-1), content="P-1D")?
}

test "op_add" {
  let p1 = Period::of(years=1, months=2, days=3)
  let p2 = Period::of(years=-1, months=-2, days=-3)
  let p3 = Period::of(
    years=Int::max_value(),
    months=Int::max_value(),
    days=Int::max_value(),
  )
  let p4 = Period::of(
    years=Int::min_value(),
    months=Int::min_value(),
    days=Int::min_value(),
  )
  inspect(p1 + Period::zero(), content="Ok(P1Y2M3D)")?
  inspect(p1 + p2, content="Ok(P0D)")?
  inspect(p1 + p1, content="Ok(P2Y4M6D)")?
  inspect(p2 + p2, content="Ok(P-2Y-4M-6D)")?
  inspect(p1 + p3, content="Err(Int overflow)")?
  inspect(p2 + p4, content="Err(Int overflow)")?
}

test "op_sub" {
  let p1 = Period::of(years=1, months=2, days=3)
  let p2 = Period::of(years=-1, months=-2, days=-3)
  let p3 = Period::of(
    years=Int::max_value(),
    months=Int::max_value(),
    days=Int::max_value(),
  )
  let p4 = Period::of(
    years=Int::min_value(),
    months=Int::min_value(),
    days=Int::min_value(),
  )
  inspect(p1 - p1, content="Ok(P0D)")?
  inspect(p1 - p2, content="Ok(P2Y4M6D)")?
  inspect(p2 - p1, content="Ok(P-2Y-4M-6D)")?
  inspect(p3 - p2, content="Err(Int overflow)")?
  inspect(p4 - p1, content="Err(Int overflow)")?
}

test "multiply" {
  let p = Period::of(years=1, months=2, days=3)
  inspect(p.multiply(0), content="Ok(P0D)")?
  inspect(p.multiply(1), content="Ok(P1Y2M3D)")?
  inspect(p.multiply(-1), content="Ok(P-1Y-2M-3D)")?
  inspect(p.multiply(2), content="Ok(P2Y4M6D)")?
  inspect(p.multiply(Int::max_value()), content="Err(Int overflow)")?
  inspect(p.multiply(Int::min_value()), content="Err(Int overflow)")?
}

test "negated" {
  let p = Period::of(years=1, months=1, days=1)
  inspect(p.negated(), content="Ok(P-1Y-1M-1D)")?
  inspect(p.negated()?.negated()? == p, content="true")?
  let p = Period::of(
    years=Int::max_value(),
    months=Int::max_value(),
    days=Int::max_value(),
  )
  inspect(p.negated(), content="Ok(P-2147483647Y-2147483647M-2147483647D)")?
  inspect(p.negated()?.negated()? == p, content="true")?
  let p = Period::of(
    years=Int::min_value(),
    months=Int::min_value(),
    days=Int::min_value(),
  )
  inspect(p.negated(), content="Err(Int overflow)")?
}
